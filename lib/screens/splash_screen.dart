import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import '../dummy_data/dummy_data.dart';
import '../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    // Resolve profile image before the delay
    String resolvedImageUrl = 'assets/images/avatar.jpg';
    final savedBase64 = prefs.getString('profileImageBase64') ?? '';
    if (savedBase64.isNotEmpty) {
      resolvedImageUrl = 'data:image/jpeg;base64,$savedBase64';
    } else {
      final savedImagePath = prefs.getString('profileImagePath') ?? '';
      if (savedImagePath.isNotEmpty) {
        try {
          final file = File(savedImagePath);
          if (await file.exists()) {
            resolvedImageUrl = savedImagePath;
          }
        } catch (_) {}
      }
    }
    
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Restore basic user data for DummyData
      final id = prefs.getString('userId') ?? '1';
      final name = prefs.getString('userName') ?? 'User';
      final email = prefs.getString('userEmail') ?? '';
      
      DummyData.currentUser = UserModel(
        id: id,
        name: name,
        email: email,
        phone: '+91 98765 43210',
        imageUrl: resolvedImageUrl,
        location: 'Chennai, Tamil Nadu',
      );

      if (role == 'admin') {
        if (mounted) Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (role == 'shopowner') {
        if (mounted) Navigator.pushReplacementNamed(context, '/shop-owner-dashboard');
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, '/home', arguments: {'userName': name});
      }
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.yellowBlackGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.primaryWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlack.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/drilling_machine.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ).animate().scale(
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
              ).fadeIn(),
              const SizedBox(height: 32),
              // App Name
              Text(
                'ConstructHub',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryWhite,
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 800),
              ),
              const SizedBox(height: 16),
              // Tagline
              Text(
                'Rent Smart. Build Faster.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryWhite.withOpacity(0.9),
                      letterSpacing: 1.5,
                    ),
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 800),
              ),
              const SizedBox(height: 64),
              // Loading indicator
              const CircularProgressIndicator(
                color: AppTheme.primaryWhite,
                strokeWidth: 3,
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
