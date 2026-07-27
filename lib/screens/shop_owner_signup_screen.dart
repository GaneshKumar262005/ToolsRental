import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../config/api_config.dart';
import '../dummy_data/dummy_data.dart';
import '../models/user_model.dart';
import '../services/email_service.dart';
import '../services/firebase_service.dart';


class ShopOwnerSignupScreen extends StatefulWidget {
  const ShopOwnerSignupScreen({super.key});

  @override
  State<ShopOwnerSignupScreen> createState() => _ShopOwnerSignupScreenState();
}

class _ShopOwnerSignupScreenState extends State<ShopOwnerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the terms and conditions')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final String name = _nameController.text.trim();
        final String email = _emailController.text.trim();
        final String phone = _phoneController.text.trim();
        final String location = _locationController.text.trim();
        final String password = _passwordController.text.trim();

        // 1. Send OTP via EmailService (Tries backend first, falls back to direct EmailJS/local OTP)
        final otpResponse = await EmailService.sendOtp(email: email, name: name);

        if (otpResponse['success'] == true) {
          if (mounted) {
            _showOtpDialog(name, email, phone, location, password);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(otpResponse['message'] ?? 'Failed to send verification code'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showOtpDialog(String name, String email, String phone, String location, String password) {
    final otpController = TextEditingController();
    bool verifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.primaryBlack,
              title: const Text('Verify Shop Owner Email', style: TextStyle(color: AppTheme.primaryWhite)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('We sent a 6-digit verification code to $email', style: const TextStyle(color: AppTheme.mediumGray)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    style: const TextStyle(color: AppTheme.primaryWhite, letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.darkGray,
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: verifying ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: verifying ? null : () async {
                    if (otpController.text.length != 6) return;
                    setDialogState(() => verifying = true);

                    // Verify OTP via EmailService
                    final res = await EmailService.verifyOtp(email: email, otp: otpController.text);

                    if (res['success'] == true) {
                      Navigator.pop(ctx);
                      _registerAfterOtp(name, email, phone, location, password);
                    } else {
                      setDialogState(() => verifying = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Incorrect verification code'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: verifying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Verify & Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _registerAfterOtp(String name, String email, String phone, String location, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String userId = DateTime.now().millisecondsSinceEpoch.toString();
      String token = 'shopowner-token-${DateTime.now().millisecondsSinceEpoch}';

      try {
        final response = await http.post(
          Uri.parse(ApiConfig.signupUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'phone': phone,
            'location': location,
            'password': password,
            'role': 'shopowner',
          }),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['user'] != null) {
            userId = data['user']['id'].toString();
            if (data['token'] != null) token = data['token'];
          }
        }
      } catch (_) {
        // Backend optional fallback
      }

      // Update DummyData.currentUser for active session
      DummyData.currentUser = UserModel(
        id: userId,
        name: name,
        email: email,
        phone: phone,
        imageUrl: 'assets/images/avatar.jpg',
        location: location,
      );

      // Save session to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', 'shopowner');
      await prefs.setString('userId', userId);
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', email);

      // Save User Account to Firebase Firestore
      final shopOwnerData = {
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'password': password,
        'role': 'shopowner',
        'registeredAt': DateTime.now().toIso8601String(),
      };
      await FirebaseService().saveUserToFirestore(shopOwnerData);

      // Permanently store in registered_users persistent list
      final String registeredUsersJson = prefs.getString('registered_users') ?? '[]';
      List<dynamic> usersList = jsonDecode(registeredUsersJson);
      usersList.removeWhere((u) => u['email'] == email);
      usersList.add(shopOwnerData);

      await prefs.setString('registered_users', jsonEncode(usersList));

      // Send welcome email
      EmailService.sendWelcomeEmail(name: name, email: email);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop Owner account registered successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/shop-owner-dashboard',
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    'Shop Owner Registration',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    'Register as a shop owner to manage tool rentals',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 100)),
                  const SizedBox(height: 24),
                  // Name field
                  Text(
                    'Full Name',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 20),
                  // Email field
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your email';
                      }
                      if (!value!.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                  const SizedBox(height: 20),
                  // Phone field
                  Text(
                    'Phone Number',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
                  const SizedBox(height: 20),
                  // Location field
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 450)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 450)),
                  const SizedBox(height: 20),
                  // Password field
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Create a password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter a password';
                      }
                      if (value!.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                  const SizedBox(height: 20),
                  // Confirm password field
                  Text(
                    'Confirm Password',
                    style: Theme.of(context).textTheme.titleSmall,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                  const SizedBox(height: 24),
                  // Terms checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryYellow,
                      ),
                      Expanded(
                        child: Text(
                          'I agree to the terms and conditions',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
                  const SizedBox(height: 32),
                  // Sign up button
                  GradientButton(
                    text: _isLoading ? 'Creating Account...' : 'Register as Shop Owner',
                    onPressed: _isLoading ? null : _signup,
                  ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
                  const SizedBox(height: 24),
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: const Duration(milliseconds: 900)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
