import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/shop_owner_login_screen.dart';
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
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely — app launches even if Firebase fails
  bool firestoreConnected = false;
  try {
    await FirebaseService().init();
    // Skip connection test at startup to avoid blocking the UI
    firestoreConnected = true;
  } catch (e) {
    print('Firebase startup error: $e');
  }

  runApp(ConstructHubApp(firestoreConnected: firestoreConnected));
}

class ConstructHubApp extends StatelessWidget {
  final bool firestoreConnected;
  const ConstructHubApp({super.key, this.firestoreConnected = false});

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
        '/shop-owner-login': (context) => const ShopOwnerLoginScreen(),
        '/shop-owner-signup': (context) => const ShopOwnerSignupScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final userName = args?['userName'] as String? ?? 'User';
          return MainNavigationWrapper(
            userName: userName,
            firestoreConnected: firestoreConnected,
          );
        },
        '/categories': (context) => CategoriesScreen(),
        '/nearby-rentals': (context) => NearbyRentalsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/booking-history': (context) => BookingHistoryScreen(),
        '/payment-history': (context) => PaymentHistoryScreen(),
        '/vendor-dashboard': (context) => VendorDashboardScreen(),
        '/admin-login': (context) => AdminLoginScreen(),
        '/admin-dashboard': (context) => AdminDashboardScreen(),
        '/shop-owner-dashboard': (context) => ShopOwnerDashboardScreen(),
        '/backend-admin': (context) => BackendAdminScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  final String userName;
  final bool firestoreConnected;
  const MainNavigationWrapper({
    super.key,
    this.userName = 'User',
    this.firestoreConnected = false,
  });

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
      HomeScreen(
        userName: widget.userName,
        firestoreConnected: widget.firestoreConnected,
      ),
      CategoriesScreen(),
      BookingHistoryScreen(),
      NotificationsScreen(),
      ProfileScreen(),
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