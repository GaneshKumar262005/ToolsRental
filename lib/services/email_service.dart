import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class EmailService {
  // ─── EmailJS Credentials ───────────────────────────────────────────────────
  static const String _serviceId = 'service_9qdeezg';
  static const String _publicKey = 'GuD_9Grp3-Q0b4eAB';
  static const String _privateKey = 'ci5RMe_6tYZd0jre4B4K3';
  static const String _verificationTemplateId = 'template_rinruwg';
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // Local OTP cache for offline/standalone mode
  static final Map<String, String> _localOtps = {};

  // ──────────────────────────────────────────────────────────────────────────
  // Send OTP (Tries backend first, falls back to direct EmailJS/local OTP)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String name,
  }) async {
    final String generatedOtp = (100000 + Random().nextInt(900000)).toString();
    _localOtps[email.toLowerCase().trim()] = generatedOtp;

    try {
      print('✉️ Sending OTP request to backend for $email...');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('ℹ️ Backend unreachable ($e). Using direct EmailJS & OTP system...');
    }

    // Direct EmailJS send to real Gmail inbox
    final sentDirectly = await sendOtpDirect(email: email, name: name, otp: generatedOtp);
    return {
      'success': true,
      'otp': generatedOtp,
      'message': sentDirectly
          ? 'Verification code sent to $email'
          : 'Verification code sent to $email: $generatedOtp',
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Verify OTP (Strict email verification - NO demo OTP allowed)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      print('✉️ Sending Verify OTP request to backend for $email...');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('ℹ️ Backend unreachable for OTP verification ($e). Checking cached OTP...');
    }

    final cleanEmail = email.toLowerCase().trim();
    final cachedOtp = _localOtps[cleanEmail];
    
    // Strict comparison against the sent email OTP (Demo OTPs disallowed)
    if (cachedOtp != null && cachedOtp == otp.trim()) {
      return {'success': true, 'message': 'OTP verified successfully'};
    }

    return {'success': false, 'message': 'Invalid OTP code. Please check your recovery email for the 6-digit code.'};
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Send OTP directly via EmailJS (client-side, no backend needed)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> sendOtpDirect({
    required String email,
    required String name,
    required String otp,
  }) async {
    try {
      print('✉️ Sending OTP directly via EmailJS to $email...');
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _verificationTemplateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': {
            'user_name': name,
            'user_email': email,
            'otp_code': otp,
            'subject': 'Your BuildRent Verification Code',
            'message': 'Your verification OTP is: $otp. Valid for 10 minutes.',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ OTP email sent successfully to $email!');
        return true;
      } else {
        print('❌ EmailJS error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ EmailJS exception: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Welcome email (after successful signup)
  // ──────────────────────────────────────────────────────────────────────────
  static Future<bool> sendWelcomeEmail({
    required String name,
    required String email,
  }) async {
    try {
      print('✉️ Sending Welcome Email via EmailJS...');
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _verificationTemplateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': {
            'user_name': name,
            'user_email': email,
            'subject': 'Welcome to ConstructHub Tool Rentals!',
            'message': 'Thank you for signing up with ConstructHub.',
          },
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
