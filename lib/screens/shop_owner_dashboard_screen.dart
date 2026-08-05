import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../themes/app_theme.dart';
import '../config/api_config.dart';
import '../models/tool_model.dart';
import '../dummy_data/dummy_data.dart';
import '../widgets/dark_location_map.dart';
import '../services/firebase_service.dart';




class ShopOwnerDashboardScreen extends StatefulWidget {
  const ShopOwnerDashboardScreen({super.key});

  @override
  State<ShopOwnerDashboardScreen> createState() => _ShopOwnerDashboardScreenState();
}

class _ShopOwnerDashboardScreenState extends State<ShopOwnerDashboardScreen> {
  int _selectedNavIndex = 0; // Default to Bookings Dashboard
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  // Shop Verification State & Controllers
  String _verificationStatus = 'not_submitted'; // 'not_submitted', 'pending', 'approved', 'rejected'
  final _shopNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmittingVerification = false;

  // Profile DP State & User Identity
  String _selectedDp = 'assets/images/avatar.jpg';
  String? _profileBase64;
  String _userName = 'ganesh26200507';
  String _userEmail = 'ganesh26200507@gmail.com';
  double _earnedRevenue = 48500.0;
  List<Map<String, String>> _dynamicReceipts = [];

  final List<Map<String, String>> _availableAvatars = [
    {'name': 'Engineer', 'icon': '👷', 'asset': 'assets/images/avatar.jpg'},
    {'name': 'Master Craftsman', 'icon': '🛠️', 'asset': 'assets/images/avatar_craft.jpg'},
    {'name': 'Heavy Specialist', 'icon': '🏗️', 'asset': 'assets/images/avatar_heavy.jpg'},
    {'name': 'Vendor Partner', 'icon': '🏢', 'asset': 'assets/images/vendor_logo.jpg'},
  ];


  Timer? _autoSyncTimer;
  StreamSubscription? _bookingsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _loadVerificationStatus();
    _loadProfileDp();
    _setupRealtimeBookingSync();
  }

  void _setupRealtimeBookingSync() {
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _fetchBookings();
      }
    });

    try {
      final stream = FirebaseService().getBookingsStream();
      if (stream != null) {
        _bookingsSubscription = stream.listen((snapshot) {
          if (mounted) {
            _fetchBookings();
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _bookingsSubscription?.cancel();
    _shopNameController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileDp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDp = prefs.getString('profileImagePath') ?? 'assets/images/avatar.jpg';
    final base64Image = prefs.getString('profile_base64_image');
    final storedName = prefs.getString('userName') ?? prefs.getString('registered_username') ?? DummyData.currentUser.name;
    final storedEmail = prefs.getString('userEmail') ?? DummyData.currentUser.email;
    final storedRevenue = prefs.getDouble('shop_owner_total_earnings') ?? 48500.0;

    setState(() {
      _selectedDp = savedDp;
      _profileBase64 = base64Image;
      _userName = storedName;
      _userEmail = storedEmail;
      _earnedRevenue = storedRevenue;
    });
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_base64_image', base64Str);
        await prefs.setString('profileImagePath', file.path);
        setState(() {
          _profileBase64 = base64Str;
          _selectedDp = file.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully from device! ✓'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAvatarWidget({double radius = 32}) {
    if (_profileBase64 != null && _profileBase64!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.primaryYellow,
        backgroundImage: MemoryImage(base64Decode(_profileBase64!)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryYellow,
      child: Text(
        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlack,
        ),
      ),
    );
  }

  void _showDpPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Change Profile Photo / Avatar',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Real Device Camera & Gallery Upload Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromSource(ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.black),
                    label: const Text('Take Photo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromSource(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('From Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Or Select Preset Avatar:',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _availableAvatars.map((av) {
                final isSelected = _selectedDp == av['asset'];
                return GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('profile_base64_image');
                    await prefs.setString('profileImagePath', av['asset']!);
                    setState(() {
                      _profileBase64 = null;
                      _selectedDp = av['asset']!;
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryYellow : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryYellow.withOpacity(0.2),
                          child: Text(av['icon']!, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        av['name']!,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryYellow : Colors.white70,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  Future<void> _loadVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String email = prefs.getString('userEmail') ?? DummyData.currentUser.email;

    String status = 'pending';
    try {
      final cloudVerifications = await FirebaseService().fetchShopVerifications();
      final myVerif = cloudVerifications.firstWhere(
        (v) => v['email']?.toString().toLowerCase().trim() == email.toLowerCase().trim(),
        orElse: () => {},
      );
      if (myVerif.isNotEmpty && myVerif['status'] != null) {
        status = myVerif['status'].toString();
      } else {
        final String emailStatus = prefs.getString('shop_verification_status_${email.toLowerCase()}') ?? '';
        final String globalStatus = prefs.getString('shop_verification_status') ?? '';
        if (emailStatus.isNotEmpty) {
          status = emailStatus;
        } else if (globalStatus.isNotEmpty) {
          status = globalStatus;
        } else {
          status = 'pending';
        }
      }
    } catch (_) {
      final String emailStatus = prefs.getString('shop_verification_status_${email.toLowerCase()}') ?? '';
      final String globalStatus = prefs.getString('shop_verification_status') ?? '';
      if (emailStatus.isNotEmpty) {
        status = emailStatus;
      } else if (globalStatus.isNotEmpty) {
        status = globalStatus;
      } else {
        status = 'pending';
      }
    }

    setState(() {
      _verificationStatus = status;
      _shopNameController.text = prefs.getString('shop_verification_name') ?? 'BuildRight Hardware';
      _gstController.text = prefs.getString('shop_verification_gst') ?? '33AAAAA0000A1Z5';
      _addressController.text = prefs.getString('shop_verification_address') ?? 'T. Nagar, Chennai';
      _phoneController.text = prefs.getString('shop_verification_phone') ?? '+91 98765 43210';

      // Default to Bookings Dashboard
      _selectedNavIndex = 0;
    });
  }


  Future<void> _submitVerification() async {
    if (_shopNameController.text.isEmpty || _gstController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all shop verification details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingVerification = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String shopEmail = prefs.getString('userEmail') ?? DummyData.currentUser.email;

    const newStatus = 'pending';

    await prefs.setString('shop_verification_status', newStatus);
    await prefs.setString('shop_verification_status_${shopEmail.toLowerCase()}', newStatus);
    await prefs.setString('shop_verification_name', _shopNameController.text.trim());
    await prefs.setString('shop_verification_gst', _gstController.text.trim());
    await prefs.setString('shop_verification_address', _addressController.text.trim());
    await prefs.setString('shop_verification_phone', _phoneController.text.trim());

    final vendorData = {
      'id': 'v_shop_${DateTime.now().millisecondsSinceEpoch}',
      'name': _shopNameController.text.trim(),
      'gst': _gstController.text.trim(),
      'email': shopEmail,
      'location': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'status': newStatus,
      'submittedAt': DateTime.now().toIso8601String(),
    };

    final pendingJson = prefs.getString('pending_vendors') ?? '[]';
    List<dynamic> pendingList = jsonDecode(pendingJson);
    if (!pendingList.any((v) => v['name'] == vendorData['name'] || v['email'] == vendorData['email'])) {
      pendingList.insert(0, vendorData);
    }
    await prefs.setString('pending_vendors', jsonEncode(pendingList));

    // Save to Firebase Firestore via FirebaseService
    await FirebaseService().saveShopVerification(vendorData);

    DummyData.notifications.insert(
      0,
      NotificationModel(
        id: 'notif_so_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Verification Request Submitted 📜',
        message: 'Your shop application for ${_shopNameController.text.trim()} has been sent to Admin for review.',
        type: 'reminder',
        targetRole: 'shopowner',
        dateTime: DateTime.now(),
        isRead: false,
      ),
    );

    if (mounted) {
      setState(() {
        _verificationStatus = 'pending';
        _isSubmittingVerification = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop verification request submitted! Awaiting Admin Acceptance ⏳'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _approveShopByAdmin() async {
    setState(() {
      _isSubmittingVerification = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String shopEmail = prefs.getString('userEmail') ?? DummyData.currentUser.email;
    const newStatus = 'approved';

    await prefs.setString('shop_verification_status', newStatus);
    await prefs.setString('shop_verification_status_${shopEmail.toLowerCase()}', newStatus);

    final approvedVendorData = {
      'id': 'v_shop_${DateTime.now().millisecondsSinceEpoch}',
      'name': _shopNameController.text.trim().isNotEmpty ? _shopNameController.text.trim() : 'BuildRight Hardware',
      'gst': _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : '33AAAAA0000A1Z5',
      'email': shopEmail,
      'location': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'T. Nagar, Chennai',
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '+91 98765 43210',
      'status': newStatus,
      'approvedAt': DateTime.now().toIso8601String(),
    };

    await FirebaseService().saveShopVerification(approvedVendorData);

    if (mounted) {
      setState(() {
        _verificationStatus = newStatus;
        _isSubmittingVerification = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop Application accepted & approved by Admin! ✓ Bookings, Profile & Notifications unlocked.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _fetchBookings() async {
    List<dynamic> allBookings = [];
    final prefs = await SharedPreferences.getInstance();

    // 1. Primary: Fetch real-time Cloud Firestore bookings (Cross-Device Web <-> Mobile Sync)
    try {
      final cloudList = await FirebaseService().fetchBookingsFromCloud();
      for (var cb in cloudList) {
        if (!allBookings.any((b) => b['id'].toString() == cb['id'].toString())) {
          allBookings.add(cb);
        }
      }
    } catch (_) {}

    // 2. Load real customer bookings placed from Payment Screen / Local SharedPreferences
    final List<String> rawRealBookings = prefs.getStringList('customer_real_bookings') ?? [];
    for (var jsonStr in rawRealBookings) {
      try {
        final parsed = jsonDecode(jsonStr);
        final String pId = parsed['id'].toString();
        final int existingIndex = allBookings.indexWhere((b) => b['id'].toString() == pId);
        if (existingIndex == -1) {
          allBookings.add(parsed);
        } else {
          // If cloud has updated status, prefer the latest
          if (parsed['status'] != null && allBookings[existingIndex]['status'] == 'pending') {
            allBookings[existingIndex]['status'] = parsed['status'];
          }
        }
      } catch (_) {}
    }

    // 3. Load API or Dummy bookings fallback
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminBookingsUrl),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['bookings'] != null) {
          for (var ab in (data['bookings'] as List)) {
            if (!allBookings.any((b) => b['id'].toString() == ab['id'].toString())) {
              allBookings.add(ab);
            }
          }
        }
      }
    } catch (_) {}

    if (allBookings.isEmpty) {
      allBookings = DummyData.bookings.map((b) => {
        'id': b.id,
        'status': b.status,
        'startDate': b.startDate.toIso8601String(),
        'endDate': b.endDate.toIso8601String(),
        'rentalDays': b.endDate.difference(b.startDate).inDays + 1,
        'totalPrice': b.totalPrice,
        'userName': DummyData.currentUser.name,
        'userPhone': DummyData.currentUser.phone,
        'userAddress': DummyData.currentUser.location,
        'tool': {
          'id': b.tool.id,
          'name': b.tool.name,
          'category': b.tool.category,
          'pricePerDay': b.tool.pricePerDay,
          'imageUrl': b.tool.imageUrl,
        }
      }).toList();
    }

    // 4. Recalculate Live Revenue from Accepted Customer Orders
    double liveTotal = 48500.0;
    for (var b in allBookings) {
      if (b['status'] == 'accepted' || b['status'] == 'approved') {
        liveTotal += (b['totalPrice'] ?? 0.0);
      }
    }

    if (mounted) {
      setState(() {
        _bookings = allBookings;
        _earnedRevenue = liveTotal;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(dynamic bookingId, String status) async {
    dynamic targetBooking;
    setState(() {
      for (var b in _bookings) {
        if (b['id'].toString() == bookingId.toString()) {
          b['status'] = status;
          targetBooking = b;
          break;
        }
      }
    });

    // Instantly sync updated status to Cloud Firestore for Cross-Device Web <-> Mobile Sync!
    FirebaseService().updateBookingStatusInCloud(bookingId.toString(), status);

    final isAccepted = status == 'accepted';
    String toolName = 'Equipment';
    double bookingPrice = 0.0;

    if (targetBooking != null) {
      toolName = targetBooking['tool']?['name'] ?? 'Equipment';
      bookingPrice = (targetBooking['totalPrice'] as num?)?.toDouble() ?? 0.0;
    }

    // Save updated real bookings to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final List<String> updatedRealList = [];
    for (var b in _bookings) {
      updatedRealList.add(jsonEncode(b));
    }
    await prefs.setStringList('customer_real_bookings', updatedRealList);

    if (isAccepted && bookingPrice > 0) {
      final currentEarned = prefs.getDouble('shop_owner_total_earnings') ?? 48500.0;
      final newTotal = currentEarned + bookingPrice;
      await prefs.setDouble('shop_owner_total_earnings', newTotal);

      final List<String> recentTxns = prefs.getStringList('shop_owner_recent_txns') ?? [];
      recentTxns.insert(0, '$toolName Rental|₹${bookingPrice.toStringAsFixed(0)}|Customer Rental Accepted|Just now');
      await prefs.setStringList('shop_owner_recent_txns', recentTxns);

      setState(() {
        _earnedRevenue = newTotal;
      });
    }

    // Save to SharedPreferences customer_notifications so customer notifications screen loads it
    final String custNotifJson = prefs.getString('customer_notifications') ?? '[]';
    List<dynamic> localCustNotifs = jsonDecode(custNotifJson);
    localCustNotifs.insert(0, {
      'id': 'notif_cust_${DateTime.now().millisecondsSinceEpoch}',
      'title': isAccepted ? 'Booking Accepted 🎉' : 'Booking Declined ❌',
      'message': isAccepted
          ? 'Your rental booking for $toolName (#$bookingId) has been accepted by the shop owner.'
          : 'Your rental booking for $toolName (#$bookingId) was declined by the shop owner.',
      'type': isAccepted ? 'booking_accepted' : 'booking_rejected',
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString('customer_notifications', jsonEncode(localCustNotifs));

    DummyData.notifications.insert(
      0,
      NotificationModel(
        id: 'notif_cust_${DateTime.now().millisecondsSinceEpoch}',
        title: isAccepted ? 'Booking Accepted 🎉' : 'Booking Declined ❌',
        message: isAccepted
            ? 'Your rental booking for $toolName (#$bookingId) has been accepted by the shop owner.'
            : 'Your rental booking for $toolName (#$bookingId) was declined by the shop owner.',
        type: isAccepted ? 'booking' : 'warning',
        targetRole: 'customer',
        dateTime: DateTime.now(),
        isRead: false,
      ),
    );

    DummyData.notifications.insert(
      0,
      NotificationModel(
        id: 'notif_so_b_${DateTime.now().millisecondsSinceEpoch}',
        title: isAccepted ? 'Booking Accepted by You ✓' : 'Booking Rejected by You ❌',
        message: 'You ${isAccepted ? 'accepted' : 'rejected'} booking #$bookingId for $toolName.',
        type: 'booking',
        targetRole: 'shopowner',
        dateTime: DateTime.now(),
        isRead: false,
      ),
    );

    try {
      await http.put(
        Uri.parse(ApiConfig.updateBookingStatusUrl(bookingId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status successfully ✓ Notification dispatched to customer.'),
          backgroundColor: isAccepted ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return Colors.blueAccent;
      case 'accepted':
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _showReturnVerificationDialog(Map<String, dynamic> booking) {
    final tool = booking['tool'] ?? {};
    final base64Str = booking['returnPhotoBase64'] as String?;
    final notes = booking['returnNotes'] as String? ?? 'No condition notes provided.';
    final returnedAt = booking['returnedAt'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.assignment_turned_in, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Return Info: Order #${booking['id']}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Equipment: ${tool['name'] ?? 'Tool'}',
                style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Returned By: ${booking['userName'] ?? 'Customer'} (${booking['userPhone'] ?? 'N/A'})',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                'Verification Photo:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: (base64Str != null && base64Str.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(base64Str),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, color: Colors.white54, size: 44),
                            SizedBox(height: 6),
                            Text('No photo submitted', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Customer Return Notes:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  notes.isEmpty ? 'No notes provided' : notes,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              if (returnedAt.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Submitted on: $returnedAt',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
            child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }


  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? '';

    // Clear Cloud Session
    if (email.isNotEmpty) {
      await FirebaseService().updateSessionState(email, false);
    }
    
    // Selective clear: KEEP registered_users
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('profileImageBase64');
    await prefs.remove('profileImagePath');

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _selectTab(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your Shop Owner Account?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmLogout();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _fetchBookings();
                _loadVerificationStatus();
              },
              tooltip: 'Refresh Dashboard',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _confirmLogout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Container(
          color: const Color(0xFF121212),
          child: _buildSelectedTabContent(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: AppTheme.primaryYellow,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded, color: AppTheme.primaryYellow),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build_rounded, color: AppTheme.primaryYellow),
              label: 'Rentals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_outlined),
              activeIcon: Icon(Icons.notifications_rounded, color: AppTheme.primaryYellow),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded, color: AppTheme.primaryYellow),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedNavIndex) {
      case 0:
        return 'Shop Owner Dashboard';
      case 1:
        return 'Rentals & Accounts Payouts';
      case 2:
        return 'Shop Owner Notifications';
      case 3:
        return 'Vendor Profile & Settings';
      default:
        return 'Shop Owner Dashboard';
    }
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildBookingsTab();
      case 1:
        return _buildAccountsTab();
      case 2:
        return _buildNotificationsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildBookingsTab();
    }
  }

  Widget _buildBookingsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryYellow),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Device Location Tracking Map (Matching Screenshot design)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Live Rented Equipment Location Map',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.gps_fixed, color: AppTheme.primaryYellow, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          const DarkLocationMap(
            height: 310,
            showCategoryFilter: true,
            showLegend: true,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Rental Bookings',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryYellow),
                ),
                child: Text(
                  '${_bookings.length} Total Requests',
                  style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_bookings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 54, color: AppTheme.mediumGray),
                    const SizedBox(height: 12),
                    Text(
                      'No pending rental bookings received yet.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                final status = booking['status'] ?? 'pending';
                final tool = booking['tool'] ?? {};

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tool['name'] ?? 'Equipment Item',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getStatusColor(status)),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      _buildDetailRow('Customer Name:', booking['userName'] ?? 'Alex Thompson'),
                      _buildDetailRow('Contact Phone:', booking['userPhone'] ?? '+91 98765 43210'),
                      _buildDetailRow('Delivery Address:', booking['userAddress'] ?? 'Chennai, Tamil Nadu'),
                      _buildDetailRow('Start Date:', _formatDate(booking['startDate'])),
                      _buildDetailRow('End Date:', _formatDate(booking['endDate'])),
                      _buildDetailRow('Total Amount:', '₹${(booking['totalPrice'] ?? 0.0).toStringAsFixed(0)}'),
                      const SizedBox(height: 14),
                      if (status.toLowerCase() == 'returned') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showReturnVerificationDialog(booking),
                            icon: const Icon(Icons.photo_camera_outlined, size: 16, color: Colors.white),
                            label: const Text(
                              'View Return Verification Photo & Notes 📸',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateBookingStatus(booking['id'].toString(), 'accepted'),
                                icon: const Icon(Icons.check, size: 16, color: Colors.black),
                                label: Text(
                                  status.toLowerCase() == 'accepted' ? 'Approved ✓' : 'Approve Booking',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status.toLowerCase() == 'accepted' ? Colors.green : AppTheme.primaryYellow,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateBookingStatus(booking['id'].toString(), 'rejected'),
                                icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                label: Text(
                                  status.toLowerCase() == 'rejected' ? 'Declined ❌' : 'Decline',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: status.toLowerCase() == 'rejected' ? Colors.red : Colors.redAccent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],


                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildVerificationTab() {
    final isApproved = _verificationStatus == 'approved';
    final isPending = _verificationStatus == 'pending';
    final isRejected = _verificationStatus == 'rejected';

    Color bannerColor = isApproved ? Colors.green : (isPending ? Colors.orange : (isRejected ? Colors.red : AppTheme.primaryYellow));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bannerColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: bannerColor.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bannerColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isApproved ? Icons.verified : (isRejected ? Icons.cancel : (isPending ? Icons.access_time_filled : Icons.warning_amber_rounded)),
                    color: bannerColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isApproved
                            ? 'Verified Shop Partner ✓'
                            : (isRejected
                                ? 'Verification Application Declined ❌'
                                : (isPending ? 'Verification Application Under Review ⏳' : 'Admin Approval Required 📜')),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: bannerColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isApproved
                            ? 'Your shop registration is fully verified by the Admin! You can accept customer rental orders & manage equipment.'
                            : (isRejected
                                ? 'Admin has declined your previous application. Please verify your GST license and address details below then re-submit.'
                                : (isPending
                                    ? 'Your verification application has been submitted to Admin. Bookings Dashboard will unlock automatically upon Admin approval.'
                                    : 'Please submit your Shop Name, GSTIN, Address, and Phone Number below to obtain Admin approval.')),
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            isApproved ? 'Verified Shop Credentials' : 'Shop Verification Application Form',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shop / Company Name', style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _shopNameController,
                  enabled: !isApproved,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.store, color: AppTheme.primaryYellow),
                    fillColor: const Color(0xFF2A2A2A),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('GSTIN / Trade License Number', style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _gstController,
                  enabled: !isApproved,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge, color: AppTheme.primaryYellow),
                    fillColor: const Color(0xFF2A2A2A),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Shop Full Address & City', style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  enabled: !isApproved,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryYellow),
                    fillColor: const Color(0xFF2A2A2A),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Contact Phone Number', style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  enabled: !isApproved,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryYellow),
                    fillColor: const Color(0xFF2A2A2A),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 28),

                if (isApproved)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedNavIndex = 0; // Navigate to Bookings Dashboard
                        });
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                      label: const Text(
                        'Next ➔ Go to Bookings Dashboard',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: AppTheme.primaryBlack,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmittingVerification ? null : _submitVerification,
                          icon: _isSubmittingVerification
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black))
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            isRejected ? 'Re-Submit for Admin Approval' : 'Submit for Admin Approval',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryYellow,
                            foregroundColor: AppTheme.primaryBlack,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmittingVerification ? null : _approveShopByAdmin,
                          icon: const Icon(Icons.verified_user_rounded, color: Colors.greenAccent),
                          label: const Text(
                            'Accept & Approve Application (Admin Action) ✓',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.greenAccent),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.greenAccent, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> combinedNotifs = [];

        if (snapshot.hasData) {
          final rawList = snapshot.data!.getStringList('shop_owner_notifications') ?? [];
          for (var str in rawList) {
            try {
              final decoded = jsonDecode(str);
              if (decoded is Map<String, dynamic>) {
                combinedNotifs.add(decoded);
              }
            } catch (_) {}
          }
        }

        for (var n in DummyData.notifications.where((n) => n.targetRole == 'shopowner')) {
          if (!combinedNotifs.any((cn) => cn['id'] == n.id)) {
            combinedNotifs.add({
              'id': n.id,
              'title': n.title,
              'message': n.message,
              'createdAt': n.dateTime.toIso8601String(),
            });
          }
        }

        if (combinedNotifs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: AppTheme.mediumGray),
                const SizedBox(height: 16),
                Text(
                  'No shop owner notifications received yet.',
                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: combinedNotifs.length,
          itemBuilder: (context, index) {
            final notif = combinedNotifs[index];
            final isReturnNotif = (notif['title'] ?? '').toString().contains('Return');

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isReturnNotif ? Colors.blueAccent.withOpacity(0.5) : AppTheme.primaryYellow.withOpacity(0.25),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isReturnNotif ? Colors.blue.withOpacity(0.2) : AppTheme.primaryYellow.withOpacity(0.2),
                  child: Icon(
                    isReturnNotif ? Icons.assignment_returned : Icons.storefront,
                    color: isReturnNotif ? Colors.blueAccent : AppTheme.primaryYellow,
                  ),
                ),
                title: Text(
                  notif['title'] ?? 'Notification',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    notif['message'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showDpPicker,
                  child: Stack(
                    children: [
                      _buildAvatarWidget(radius: 46),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlack,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.primaryYellow),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryYellow),
                      onPressed: _showEditNameDialog,
                      tooltip: 'Edit Username',
                    ),
                  ],
                ),
                Text(
                  _userEmail,
                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showDpPicker,
                  icon: const Icon(Icons.photo_camera, size: 18),
                  label: const Text('Change Photo / Take Device Picture', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.primaryBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.badge, color: AppTheme.primaryYellow),
                  title: const Text('Registered Shop Owner Username', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  subtitle: Text(_userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.phone, color: AppTheme.primaryYellow),
                  title: const Text('Contact Phone Number', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  subtitle: Text(_phoneController.text.isNotEmpty ? _phoneController.text : '+91 98765 43210', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on, color: AppTheme.primaryYellow),
                  title: const Text('Shop Location Address', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  subtitle: Text(_addressController.text.isNotEmpty ? _addressController.text : 'Chennai, Tamil Nadu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Update User Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter user name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryYellow)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('userName', newName);
                await prefs.setString('registered_username', newName);
                setState(() {
                  _userName = newName;
                });
              }
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
            child: const Text('Save Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsTab() {
    final availablePayout = _earnedRevenue > 6400 ? _earnedRevenue - 6400 : _earnedRevenue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Revenue Card Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E222A), Color(0xFF141820)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.4)),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Total Earned Revenue',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Icon(Icons.account_balance_wallet, color: AppTheme.primaryYellow, size: 28),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_earnedRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('Available for Immediate Bank Payout: ₹${availablePayout.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bank Details Section
          const Text(
            'Bank Account & Payout Settings',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.account_balance, color: AppTheme.primaryYellow, size: 30),
                  title: Text('HDFC Bank Ltd', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Anna Nagar Branch, Chennai', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Account Number:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text('•••• •••• 0192', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('IFSC Code:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text('HDFC0001294', style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Account Holder:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text(_userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payout request of ₹${availablePayout.toStringAsFixed(0)} submitted! Transferred to HDFC Account #••••0192 within 2 hours. 🎉'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send, size: 18, color: Colors.black),
                    label: const Text('Withdraw Payout to Bank Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accounts & Transactions Summary
          const Text(
            'Recent Customer Payment Receipts',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _buildReceiptRow('Electric Cement Mixer Rental', '₹4,500', 'Paid via GPay (UPI)', 'Today, 08:30 AM'),
                const Divider(color: Colors.white12),
                _buildReceiptRow('MIG Welder Pro 3-Day Rental', '₹15,000', 'Paid via PhonePe (UPI)', 'Yesterday'),
                const Divider(color: Colors.white12),
                _buildReceiptRow('Silent Diesel Generator 10kVA', '₹18,500', 'Direct Bank Transfer', '2 days ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildReceiptRow(String title, String amount, String method, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('$method • $time', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

