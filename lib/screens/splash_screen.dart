import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import '../dummy_data/dummy_data.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

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
    final localToken = prefs.getString('token');
    final localRole = prefs.getString('role');
    final localEmail = prefs.getString('userEmail') ?? '';

    // Check Cloud Session (Cross-Device Sync)
    bool cloudLoginDetected = false;
    String cloudRole = '';
    String cloudName = '';

    if (localEmail.isNotEmpty) {
      try {
        await FirebaseService().init();
        final cloudSession = await FirebaseService().firestore!
            .collection('active_sessions')
            .doc(localEmail.replaceAll('.', '_'))
            .get();
        
        if (cloudSession.exists && cloudSession.data()?['isLoggedIn'] == true) {
          cloudLoginDetected = true;
          cloudRole = cloudSession.data()?['role'] ?? 'user';
          cloudName = cloudSession.data()?['name'] ?? 'User';
        }
      } catch (_) {}
    }

    // Resolve profile image quickly
    String resolvedImageUrl = 'assets/images/avatar.jpg';
    final savedBase64 = prefs.getString('profileImageBase64') ?? '';
    if (savedBase64.isNotEmpty) {
      resolvedImageUrl = 'data:image/jpeg;base64,$savedBase64';
    } else {
      final savedImagePath = prefs.getString('profileImagePath') ?? '';
      if (!kIsWeb && savedImagePath.isNotEmpty) {
        try {
          final file = File(savedImagePath);
          if (await file.exists()) {
            resolvedImageUrl = savedImagePath;
          }
        } catch (_) {}
      }
    }

    // Faster Splash: Only wait 1.2 seconds instead of 3
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Prioritize Cloud Login or Local Login
    if (cloudLoginDetected || (localToken != null && localToken.isNotEmpty)) {
      final id = prefs.getString('userId') ?? 'u_${DateTime.now().millisecondsSinceEpoch}';
      final name = cloudLoginDetected ? cloudName : (prefs.getString('userName') ?? 'User');
      final email = localEmail;
      final role = cloudLoginDetected ? cloudRole : localRole;
      
      DummyData.currentUser = UserModel(
        id: id,
        name: name,
        email: email,
        phone: '+91 98765 43210',
        imageUrl: resolvedImageUrl,
        location: 'Chennai, Tamil Nadu',
      );

      // Save synced cloud state to local prefs if it was a cloud login
      if (cloudLoginDetected) {
        await prefs.setString('token', 'cloud-synced-token');
        await prefs.setString('role', cloudRole);
        await prefs.setString('userName', cloudName);
      }

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
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlack.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'assets/images/download.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.construction,
                        size: 50,
                        color: AppTheme.primaryYellow,
                      ),
                    ),
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
