import 'package:flutter/foundation.dart';

class ApiConfig {
  // Change this to your actual backend server IP address
  // For local development on emulator: use '10.0.2.2'
  // For local development on real device: use your computer's IP address
  // For web development: use 'localhost'
  
  static const String _host = '10.242.206.148'; // YOUR CURRENT IP
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      // Use the IP for real devices or 10.0.2.2 for emulators
      // return 'http://10.0.2.2:3000'; // Uncomment for Android Emulator
      return 'http://$_host:3000';
    }
  }

  static String get loginUrl => '$baseUrl/api/login';
  static String get usersUrl => '$baseUrl/api/users';
  static String get healthUrl => '$baseUrl/api/health';
  static String get bookingsUrl => '$baseUrl/api/bookings';
  static String userBookingsUrl(int userId) => '$baseUrl/api/bookings/$userId';
  static String get adminBookingsUrl => '$baseUrl/api/admin/bookings';
  static String get adminUsersUrl => '$baseUrl/api/admin/users';
  static String updateUserUrl(int userId) => '$baseUrl/api/users/$userId';
  static String updateBookingStatusUrl(int bookingId) => '$baseUrl/api/bookings/$bookingId/status';
  static String notificationsUrl(int userId) => '$baseUrl/api/notifications/$userId';
  static String markNotificationReadUrl(int notificationId) => '$baseUrl/api/notifications/$notificationId/read';
}
