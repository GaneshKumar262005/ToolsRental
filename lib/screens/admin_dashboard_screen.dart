import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dummy_data/dummy_data.dart';

import '../themes/app_theme.dart';
import '../models/tool_model.dart';
import '../widgets/stats_card.dart';
import '../config/api_config.dart';
import '../services/firebase_service.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _backendUsers = [];
  List<Map<String, dynamic>> _backendBookings = [];
  bool _isLoadingUsers = false;
  // ignore: unused_field
  bool _isLoadingBookings = false;
  String _revenueTimeframe = 'Months'; // 'Weeks', 'Months', 'Years'

  List<Map<String, dynamic>> _pendingVendorsList = [];
  List<Map<String, dynamic>> _recentActivityList = [];

  List<String> _getChartLabels() {
    switch (_revenueTimeframe) {
      case 'Weeks':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'Years':
        return ['2022', '2023', '2024', '2025', '2026'];
      case 'Months':
      default:
        return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    }
  }

  List<double> _getChartValues() {
    switch (_revenueTimeframe) {
      case 'Weeks':
        return [14500, 22000, 18500, 31000, 27500, 42000, 38000];
      case 'Years':
        return [180000, 340000, 520000, 780000, 950000];
      case 'Months':
      default:
        return [25000, 32000, 28000, 40000, 35000, 45000];
    }
  }

  List<Map<String, dynamic>> _getRevenueTableData() {
    final labels = _getChartLabels();
    final values = _getChartValues();
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    List<Map<String, dynamic>> tableRows = [];
    for (int i = 0; i < labels.length; i++) {
      int count = (values[i] / 2500).round() + 3;
      tableRows.add({
        'period': labels[i],
        'rentals': count,
        'revenue': format.format(values[i]),
        'status': 'Active',
      });
    }
    return tableRows;
  }

  @override
  void initState() {
    super.initState();
    _checkAdminSession();
    _loadPendingVendors();
    _fetchBackendUsers();
    _fetchBackendBookings();
    _generateRecentActivity();
  }

  Future<void> _checkAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isAdminAuth = prefs.getBool('admin_authenticated') ?? false;
    final String role = prefs.getString('role') ?? '';

    if (!isAdminAuth && role != 'admin') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Restricted Admin Portal. Please authenticate via corporate login.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/admin-login');
      }
    }
  }

  Future<void> _logoutAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_authenticated', false);
    await prefs.remove('admin_email');
    await prefs.remove('token');
    await prefs.remove('role');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin session destroyed & logged out securely.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pushReplacementNamed(context, '/admin-login');
    }
  }


  List<Map<String, dynamic>> _verifiedShopsList = [];

  Future<void> _loadPendingVendors() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> pendingVendors = [];
    List<Map<String, dynamic>> verifiedList = [];

    // 1. Fetch from Firebase Firestore via FirebaseService
    final firestoreVerifications = await FirebaseService().fetchShopVerifications();
    for (var data in firestoreVerifications) {
      if (data['status'] == 'approved') {
        if (!verifiedList.any((v) => v['email'] == data['email'])) {
          verifiedList.add(data);
        }
      } else {
        if (!pendingVendors.any((v) => v['email'] == data['email'])) {
          pendingVendors.add(data);
        }
      }
    }


    // 2. Load from SharedPreferences 'pending_vendors'
    final pendingJson = prefs.getString('pending_vendors') ?? '[]';
    final List<dynamic> localPending = jsonDecode(pendingJson);
    for (var item in localPending) {
      final mapItem = Map<String, dynamic>.from(item);
      if (mapItem['status'] == 'pending' && !pendingVendors.any((v) => v['name'] == mapItem['name'] || v['email'] == mapItem['email'])) {
        pendingVendors.insert(0, mapItem);
      }
    }

    // 3. Load from SharedPreferences 'verified_shops'
    final verifiedJson = prefs.getString('verified_shops') ?? '[]';
    final List<dynamic> localVerified = jsonDecode(verifiedJson);
    for (var item in localVerified) {
      final mapItem = Map<String, dynamic>.from(item);
      if (!verifiedList.any((v) => v['name'] == mapItem['name'] || v['email'] == mapItem['email'])) {
        verifiedList.insert(0, mapItem);
      }
    }

    // 4. Read live shop verification status submitted by shop owner
    final shopName = prefs.getString('shop_verification_name') ?? 'BuildRight Hardware';
    final shopEmail = prefs.getString('userEmail') ?? DummyData.currentUser.email;
    final shopAddress = prefs.getString('shop_verification_address') ?? 'T. Nagar, Chennai';
    final shopPhone = prefs.getString('shop_verification_phone') ?? '+91 98765 43210';
    final shopStatus = prefs.getString('shop_verification_status') ?? 'pending';

    final liveItem = {
      'id': 'live_shop_${shopEmail.replaceAll('.', '_')}',
      'name': shopName.isNotEmpty ? shopName : 'BuildRight Hardware',
      'email': shopEmail.isNotEmpty ? shopEmail : 'ganesh26200507@gmail.com',
      'location': shopAddress.isNotEmpty ? shopAddress : 'T. Nagar, Chennai',
      'phone': shopPhone.isNotEmpty ? shopPhone : '+91 98765 43210',
      'status': shopStatus,
    };

    if (shopStatus == 'approved') {
      if (!verifiedList.any((v) => v['name'] == liveItem['name'] || v['email'] == liveItem['email'])) {
        verifiedList.insert(0, liveItem);
      }
    } else {
      if (!pendingVendors.any((v) => v['name'] == liveItem['name'] || v['email'] == liveItem['email'])) {
        pendingVendors.insert(0, liveItem);
      }
    }

    if (mounted) {
      setState(() {
        _pendingVendorsList = pendingVendors;
        _verifiedShopsList = verifiedList;
      });
    }
  }

  Future<void> _fetchBackendUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    List<Map<String, dynamic>> combinedUsers = [];
    final prefs = await SharedPreferences.getInstance();

    // 1. Add current logged-in customer account
    final currentUserEmail = prefs.getString('userEmail') ?? prefs.getString('customer_email') ?? '';
    final currentUserName = prefs.getString('userName') ?? prefs.getString('customer_name') ?? 'ganesh26200507';
    if (currentUserEmail.isNotEmpty) {
      combinedUsers.add({
        'id': 'u_real_active',
        'name': currentUserName,
        'email': currentUserEmail,
        'phone': '+91 98765 43210',
        'location': 'Chennai, Tamil Nadu',
        'role': 'customer',
      });
    } else {
      combinedUsers.add({
        'id': 'u_real_default',
        'name': 'ganesh26200507',
        'email': 'ganesh26200507@gmail.com',
        'phone': '+91 98765 43210',
        'location': 'Chennai, Tamil Nadu',
        'role': 'customer',
      });
    }

    // 2. Read registered users from SharedPreferences
    try {
      final String registeredUsersJson = prefs.getString('registered_users') ?? '[]';
      final List<dynamic> localUsers = jsonDecode(registeredUsersJson);

      for (var u in localUsers) {
        if (!combinedUsers.any((cu) => cu['email'] == u['email'])) {
          combinedUsers.add(Map<String, dynamic>.from(u));
        }
      }
    } catch (_) {}

    // 3. Fetch from API if available
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminUsersUrl),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['users'] != null && (data['users'] as List).isNotEmpty) {
          for (var u in data['users']) {
            if (!combinedUsers.any((cu) => cu['email'] == u['email'])) {
              combinedUsers.add(Map<String, dynamic>.from(u));
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _backendUsers = combinedUsers;
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _fetchBackendBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminBookingsUrl),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['bookings'] != null) {
          setState(() {
            _backendBookings = List<Map<String, dynamic>>.from(data['bookings']);
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  void _generateRecentActivity() {
    setState(() {
      _recentActivityList = [
        {
          'title': 'Shop Verification Submitted 📜',
          'subtitle': 'BuildRight Hardware requested vendor approval',
          'time': 'Just now',
          'icon': Icons.store,
          'color': AppTheme.accentOrange,
        },
        {
          'title': 'New Rental Order Created 🏗️',
          'subtitle': 'Bosch Rotary Hammer Drill rented by Alex Thompson',
          'time': '15m ago',
          'icon': Icons.build,
          'color': AppTheme.primaryYellow,
        },
        {
          'title': 'Customer Payment Received 💳',
          'subtitle': '₹7,055.00 security deposit payment from Sarah',
          'time': '1h ago',
          'icon': Icons.payment,
          'color': AppTheme.accentGreen,
        },
        {
          'title': 'Shop Owner Approved ✓',
          'subtitle': 'PowerTools Hub verified as official shop partner',
          'time': '2h ago',
          'icon': Icons.verified,
          'color': AppTheme.accentBlue,
        },
        {
          'title': 'New Customer Registration 👤',
          'subtitle': 'Rajesh Kumar joined ConstructHub',
          'time': '3h ago',
          'icon': Icons.person_add,
          'color': AppTheme.accentBlue,
        },
      ];
    });
  }

  String _calculateTotalRevenue() {
    double total = 0;
    if (_backendBookings.isNotEmpty) {
      for (var b in _backendBookings) {
        double price = 0;
        if (b['totalPrice'] != null) {
          price = (b['totalPrice'] is num)
              ? (b['totalPrice'] as num).toDouble()
              : (double.tryParse(b['totalPrice'].toString()) ?? 0);
        }
        total += price;
      }
    }

    for (var b in DummyData.bookings) {
      total += b.totalPrice;
    }

    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPendingVendors();
              _fetchBackendUsers();
              _fetchBackendBookings();
              _generateRecentActivity();
            },
            tooltip: 'Refresh All Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logoutAdmin,
            tooltip: 'Logout Admin Session',
          ),

        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Customers',
                    value: _backendUsers.isNotEmpty ? _backendUsers.length.toString() : '12',
                    icon: Icons.people,
                    iconColor: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Total Rentals',
                    value: _backendBookings.isNotEmpty
                        ? _backendBookings.length.toString()
                        : DummyData.bookings.length.toString(),
                    icon: Icons.build,
                    iconColor: AppTheme.primaryYellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Revenue',
                    value: _calculateTotalRevenue(),
                    icon: Icons.currency_rupee,
                    iconColor: AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Active Vendors',
                    value: '4',
                    icon: Icons.store,
                    iconColor: AppTheme.accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vendor Approvals Section (Image 1 Fix)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Pending Vendor Approvals',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentOrange),
                  ),
                  child: Text(
                    '${_pendingVendorsList.length} Pending',
                    style: const TextStyle(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _pendingVendorsList.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration(),
                    child: Center(
                      child: Text(
                        'All shop vendor applications have been approved! ✓',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.accentGreen,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  )
                : Column(
                    children: _pendingVendorsList.map((vendor) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppTheme.primaryYellow,
                                  child: Text(
                                    vendor['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlack,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vendor['name'],
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${vendor['location']} • ${vendor['email']}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.mediumGray,
                                            ),
                                      ),
                                      if (vendor['phone'] != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Phone: ${vendor['phone']}',
                                          style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                                                         Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('shop_verification_status', 'approved');
                                      if (vendor['email'] != null) {
                                        await prefs.setString('shop_verification_status_${vendor['email'].toString().toLowerCase()}', 'approved');
                                      }

                                      final approvedItem = {
                                        'id': vendor['id'],
                                        'name': vendor['name'],
                                        'email': vendor['email'],
                                        'location': vendor['location'],
                                        'phone': vendor['phone'] ?? '+91 98765 43210',
                                        'status': 'approved',
                                        'approvedAt': 'Approved Today ✓',
                                      };

                                      final String currentVerifiedJson = prefs.getString('verified_shops') ?? '[]';
                                      List<dynamic> localVerified = jsonDecode(currentVerifiedJson);
                                      if (!localVerified.any((v) => v['email'] == approvedItem['email'])) {
                                        localVerified.insert(0, approvedItem);
                                      }
                                      await prefs.setString('verified_shops', jsonEncode(localVerified));

                                      // Save approval to Firebase Firestore via FirebaseService
                                      await FirebaseService().saveShopVerification(approvedItem);



                                      DummyData.notifications.insert(
                                        0,
                                        NotificationModel(
                                          id: 'notif_verif_${DateTime.now().millisecondsSinceEpoch}',
                                          title: 'Shop Verification Approved 🎉',
                                          message: 'Congratulations! Your shop vendor verification application has been approved by the Admin. You are now a Verified Shop Owner.',
                                          type: 'booking',
                                          targetRole: 'shopowner',
                                          dateTime: DateTime.now(),
                                          isRead: false,
                                        ),
                                      );
                                      setState(() {
                                        _pendingVendorsList.removeWhere((v) => v['id'] == vendor['id']);
                                        _verifiedShopsList.insert(0, approvedItem);
                                        _recentActivityList.insert(0, {
                                          'title': 'Shop Verification Approved ✓',
                                          'subtitle': '${vendor['name']} verified and added to Verified Shops',
                                          'time': 'Just now',
                                          'icon': Icons.verified,
                                          'color': AppTheme.accentGreen,
                                        });
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Vendor "${vendor['name']}" APPROVED & stored as Verified Shop! 🎉'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                                    label: const Text('Approve Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('shop_verification_status', 'rejected');
                                      DummyData.notifications.insert(
                                        0,
                                        NotificationModel(
                                          id: 'notif_verif_${DateTime.now().millisecondsSinceEpoch}',
                                          title: 'Shop Verification Declined ❌',
                                          message: 'Your shop verification request was declined by the Admin. Please review your details and re-apply.',
                                          type: 'warning',
                                          targetRole: 'shopowner',
                                          dateTime: DateTime.now(),
                                          isRead: false,
                                        ),
                                      );
                                      setState(() {
                                        _pendingVendorsList.removeWhere((v) => v['id'] == vendor['id']);
                                        _recentActivityList.insert(0, {
                                          'title': 'Shop Verification Declined ❌',
                                          'subtitle': '${vendor['name']} application declined by Admin',
                                          'time': 'Just now',
                                          'icon': Icons.cancel,
                                          'color': Colors.redAccent,
                                        });
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Vendor "${vendor['name']}" application DECLINED.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.cancel, size: 18, color: Colors.redAccent),
                                    label: const Text('Decline', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.redAccent),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 28),

            // Verified Shops & Official Partners Section (Image 3 Request)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Verified Shops & Official Partners',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    '${_verifiedShopsList.length} Verified',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _verifiedShopsList.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(),
                    child: const Center(
                      child: Text(
                        'No verified shops yet.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                : Column(
                    children: _verifiedShopsList.map((shop) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.green,
                              radius: 20,
                              child: Icon(Icons.verified, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop['name'] ?? 'Verified Shop',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${shop['email']} • ${shop['location']}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle, size: 12, color: Colors.greenAccent),
                                  SizedBox(width: 4),
                                  Text('VERIFIED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 28),

            const SizedBox(height: 28),

            // Customers Section (Image 2 Fix - Populated Customer List)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customers',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primaryYellow),
                  onPressed: _fetchBackendUsers,
                  tooltip: 'Refresh Customers',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoadingUsers
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                : _backendUsers.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration(),
                        child: Center(
                          child: Text(
                            'No registered customers found',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.cardDecoration(),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _backendUsers.length,
                          itemBuilder: (context, index) {
                            final user = _backendUsers[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryYellow,
                                  child: Text(
                                    (user['name']?.isNotEmpty ?? false) ? user['name'][0].toUpperCase() : 'C',
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlack,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user['name'] ?? 'Customer',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${user['email']}\n${user['phone'] ?? '+91 98765 43210'}',
                                  style: TextStyle(
                                    color: AppTheme.mediumGray,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryYellow.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'CUSTOMER',
                                    style: TextStyle(
                                      color: AppTheme.primaryYellow,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 28),

            // Revenue Analytics Section Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Revenue Analytics',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.mediumGray.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ['Weeks', 'Months', 'Years'].map((tf) {
                          final isSelected = _revenueTimeframe == tf;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _revenueTimeframe = tf;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryYellow : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tf,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.primaryBlack : AppTheme.mediumGray,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Revenue breakdown in Indian Rupees (₹) by $_revenueTimeframe',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Revenue Chart Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_revenueTimeframe Revenue Usage (INR ₹)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+23% vs last period',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: Builder(
                      builder: (context) {
                        final labels = _getChartLabels();
                        final values = _getChartValues();
                        double maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;

                        return BarChart(
                          BarChartData(
                            maxY: maxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withOpacity(0.15),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int idx = value.toInt();
                                    if (idx >= 0 && idx < labels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          labels[idx],
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 55,
                                  interval: (maxY / 4) > 0 ? (maxY / 4) : 10000,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const Text('₹0');
                                    if (value >= 100000) {
                                      return Text(
                                        '₹${(value / 100000).toStringAsFixed(1)}L',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                      );
                                    }
                                    return Text(
                                      '₹${(value / 1000).toInt()}k',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(labels.length, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: values[i],
                                    color: AppTheme.primaryYellow,
                                    width: 18,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Usage & Revenue Table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(context: context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_revenueTimeframe Usage & Revenue Breakdown Table',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Icon(Icons.table_chart, color: AppTheme.primaryYellow, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.primaryYellow),
                        dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                          return const Color(0xFF1E1E1E);
                        }),
                        columns: const [
                          DataColumn(label: Text('Period', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
                          DataColumn(label: Text('Rentals', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
                          DataColumn(label: Text('Revenue (₹)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
                          DataColumn(label: Text('Status', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
                        ],
                        rows: _getRevenueTableData().map((row) {
                          return DataRow(cells: [
                            DataCell(Text(row['period'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                            DataCell(Text('${row['rentals']} rentals', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                            DataCell(Text(
                              row['revenue'].toString(),
                              style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13),
                            )),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                              ),
                              child: const Text('Active', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 11)),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Recent Activity Section (Image 3 Fix - Dynamic Recent Work)
            Text(
              'Recent Activity & Work Updates',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: List.generate(_recentActivityList.length, (index) {
                  final act = _recentActivityList[index];
                  return Column(
                    children: [
                      _buildActivityItem(
                        act['title'].toString(),
                        act['subtitle'].toString(),
                        act['icon'] as IconData,
                        act['color'] as Color,
                        act['time'].toString(),
                      ),
                      if (index < _recentActivityList.length - 1) const Divider(height: 24),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  ),
);
}


  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, String time) {

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryYellow,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
