import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/shop_owner_signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/nearby_rentals_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/payment_history_screen.dart';
import 'screens/vendor_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/shop_owner_dashboard_screen.dart';
import 'screens/backend_admin_screen.dart';
import 'screens/profile_screen.dart';
import 'themes/app_theme.dart';
import 'widgets/bottom_navigation.dart';

void main() {
  runApp(const ConstructHubApp());
}

class ConstructHubApp extends StatelessWidget {
  const ConstructHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConstructHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/splash',
      routes: {
        '/': (context) => const SplashScreen(), // ✅ fallback
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/shop-owner-signup': (context) => const ShopOwnerSignupScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final userName = args?['userName'] as String? ?? 'User';
          return MainNavigationWrapper(userName: userName);
        },
        '/categories': (context) => const CategoriesScreen(),
        '/nearby-rentals': (context) => const NearbyRentalsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/booking-history': (context) => const BookingHistoryScreen(),
        '/payment-history': (context) => const PaymentHistoryScreen(),
        '/vendor-dashboard': (context) => const VendorDashboardScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/shop-owner-dashboard': (context) => const ShopOwnerDashboardScreen(),
        '/backend-admin': (context) => const BackendAdminScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  final String userName;
  const MainNavigationWrapper({super.key, this.userName = 'User'});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late List<Widget> _screens; // ✅ late — built once in initState

  @override
  void initState() {
    super.initState();
    // ✅ FIX: build list once so IndexedStack keeps stable widget elements
    _screens = [
      HomeScreen(userName: widget.userName),
      const CategoriesScreen(),
      const BookingHistoryScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}