import 'package:flutter/foundation.dart';

class ApiConfig {
  // Change this to your actual backend server IP address
  // For local development on emulator: use '10.0.2.2'
  // For local development on real device: use your computer's IP address
  // For web development: use 'localhost'
  
  // Current LAN IP of your machine for real mobile devices on Wi-Fi
  // ⚠️ If "Server" dot is RED, update this IP to your computer's current Wi-Fi IP
  static const String _lanHost = '10.242.206.148';

  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'http://localhost:3000';
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      default:
        return 'http://$_lanHost:3000';
    }
  }

  static String get loginUrl => '$baseUrl/api/login';
  static String get shopOwnerOtpLoginUrl => '$baseUrl/api/shopowner-login-otp';
  static String get signupUrl => '$baseUrl/api/signup';
  static String get usersUrl => '$baseUrl/api/users';
  static String get healthUrl => '$baseUrl/api/health';
  static String get bookingsUrl => '$baseUrl/api/bookings';
  static String userBookingsUrl(dynamic userId) => '$baseUrl/api/bookings/$userId';
  static String get adminBookingsUrl => '$baseUrl/api/admin/bookings';
  static String get adminUsersUrl => '$baseUrl/api/admin/users';
  static String updateUserUrl(dynamic userId) => '$baseUrl/api/users/$userId';
  static String updateBookingStatusUrl(dynamic bookingId) => '$baseUrl/api/bookings/$bookingId/status';
  static String notificationsUrl(dynamic userId) => '$baseUrl/api/notifications/$userId';
  static String markNotificationReadUrl(dynamic notificationId) => '$baseUrl/api/notifications/$notificationId/read';
}
