import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../dummy_data/dummy_data.dart';
import '../themes/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/app_image.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < DummyData.onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _skip() {
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryYellow,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: DummyData.onboardingData.length,
                itemBuilder: (context, index) {
                  final data = DummyData.onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image
                        Builder(
                          builder: (context) {
                            final isWide = MediaQuery.of(context).size.width >= 800;
                            return Container(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 420 : 300,
                                maxHeight: isWide ? 220 : 180,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryYellow.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AppImage(
                                  imageUrl: data.imageUrl,
                                  height: double.infinity,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ).animate().fadeIn().slideY(),
                        const SizedBox(height: 40),
                        // Title
                        Text(
                          data.title,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          data.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: DummyData.onboardingData.length,
                effect: WormEffect(
                  dotWidth: 12,
                  dotHeight: 12,
                  activeDotColor: AppTheme.primaryYellow,
                  dotColor: AppTheme.mediumGray.withOpacity(0.5),
                ),
              ),
            ),
            // Next button
            Padding(
              padding: const EdgeInsets.all(24),
              child: GradientButton(
                text: _currentPage == DummyData.onboardingData.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
