import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../themes/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  void _navigateToOnboarding() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
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
              // Logo
              Container(
                width: 120,
                height: 120,
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
                child: const Icon(
                  Icons.construction,
                  size: 60,
                  color: AppTheme.primaryYellow,
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
