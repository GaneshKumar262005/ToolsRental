import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import '../config/api_config.dart';
import '../dummy_data/dummy_data.dart';
import '../services/firebase_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    List<dynamic> combinedBookings = [];

    // 1. Read real-time Cloud Firestore bookings for cross-device updates
    try {
      final cloudList = await FirebaseService().fetchBookingsFromCloud();
      for (var cb in cloudList) {
        if (!combinedBookings.any((b) => b['id'].toString() == cb['id'].toString())) {
          combinedBookings.add(cb);
        }
      }
    } catch (_) {}

    // 2. Read real customer bookings from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final List<String>? listStrings = prefs.getStringList('customer_real_bookings');
      if (listStrings != null && listStrings.isNotEmpty) {
        for (var str in listStrings) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is Map<String, dynamic>) {
              final String dId = decoded['id'].toString();
              final existingIdx = combinedBookings.indexWhere((b) => b['id'].toString() == dId);
              if (existingIdx == -1) {
                combinedBookings.add(decoded);
              } else {
                if (decoded['status'] != null && combinedBookings[existingIdx]['status'] == 'pending') {
                  combinedBookings[existingIdx]['status'] = decoded['status'];
                }
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 2. Load from in-memory DummyData bookings
    for (var b in DummyData.bookings) {
      final mapData = {
        'id': b.id,
        'status': b.status,
        'startDate': b.startDate.toIso8601String(),
        'endDate': b.endDate.toIso8601String(),
        'totalPrice': b.totalPrice,
        'tool': {
          'id': b.tool.id,
          'name': b.tool.name,
          'category': b.tool.category,
          'pricePerDay': b.tool.pricePerDay,
          'imageUrl': b.tool.imageUrl,
        }
      };
      if (!combinedBookings.any((cb) => cb['id'] == b.id)) {
        combinedBookings.add(mapData);
      }
    }

    // 3. Fallback sample booking if list is completely empty
    if (combinedBookings.isEmpty) {
      combinedBookings = [
        {
          'id': 'BK100982',
          'status': 'accepted',
          'startDate': DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'rentalDays': 3,
          'totalPrice': 11205.0,
          'userName': 'ganesh26200507',
          'userPhone': '+91 98765 43210',
          'userAddress': 'Chennai, Tamil Nadu',
          'tool': {
            'id': 'cm_1',
            'name': 'Electric Cement Mixer',
            'category': 'Concrete Mixes',
            'pricePerDay': 3735.0,
            'imageUrl': 'assets/images/cm_electric_cement_mixer.png',
          }
        }
      ];
    }

    if (mounted) {
      setState(() {
        _bookings = combinedBookings;
        _isLoading = false;
      });
    }
  }

  Future<void> _showReturnToolModal(Map<String, dynamic> booking) async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;
    String? base64Image;
    final notesController = TextEditingController();
    double userRating = 5.0;
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final tool = booking['tool'] ?? {};
            final orderId = booking['id'] ?? 'Order';

            Future<void> pickPhoto(ImageSource source) async {
              try {
                final image = await picker.pickImage(
                  source: source,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 80,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setModalState(() {
                    pickedFile = image;
                    base64Image = base64Encode(bytes);
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error selecting image: $e')),
                );
              }
            }

            Future<void> submitReturn() async {
              setModalState(() {
                isSubmitting = true;
              });

              final returnData = {
                'orderId': orderId,
                'toolId': tool['id'] ?? '',
                'toolName': tool['name'] ?? 'Equipment Item',
                'userName': booking['userName'] ?? 'Customer',
                'userPhone': booking['userPhone'] ?? '',
                'userRating': userRating,
                'returnNotes': notesController.text.trim(),
                'returnPhotoBase64': base64Image ?? '',
                'returnedAt': DateTime.now().toIso8601String(),
                'status': 'RETURNED',
              };

              // 1. Save tool return to Cloud Firestore
              await FirebaseService().saveToolReturn(returnData);

              // 2. Save real customer tool rating & feedback review
              final String toolId = (tool['id'] ?? '').toString();
              final String toolName = (tool['name'] ?? '').toString();
              final String customerName = booking['userName'] ?? 'Customer';
              final String reviewText = notesController.text.trim();

              await FirebaseService().saveToolRatingAndReview(
                toolId: toolId.isNotEmpty ? toolId : toolName,
                rating: userRating,
                comment: reviewText.isEmpty ? 'Tool returned in excellent condition.' : reviewText,
                userName: customerName,
              );

              // Save locally to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final localRev = jsonEncode({
                'toolId': toolId,
                'toolName': toolName,
                'rating': userRating,
                'comment': reviewText,
                'userName': customerName,
                'createdAt': DateTime.now().toIso8601String(),
              });
              final List<String> localRevs = prefs.getStringList('local_customer_reviews') ?? [];
              localRevs.insert(0, localRev);
              await prefs.setStringList('local_customer_reviews', localRevs);

              // Update DummyData.tools in memory immediately! Match by ID OR Name
              for (var t in DummyData.tools) {
                final bool idMatches = toolId.isNotEmpty && t.id.toLowerCase() == toolId.toLowerCase();
                final bool nameMatches = toolName.isNotEmpty && t.name.toLowerCase().trim() == toolName.toLowerCase().trim();
                if (idMatches || nameMatches) {
                  t.rating = userRating;
                  t.reviewCount += 1;
                  t.hasRealFeedback = true;
                  t.lastFeedbackRating = userRating;
                  t.lastFeedbackComment = reviewText.isEmpty ? 'Returned & rated by customer.' : reviewText;
                  t.lastFeedbackTime = DateTime.now();
                }
              }

              // 3. Try sending to backend server API
              try {
                await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/api/return-tool'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(returnData),
                ).timeout(const Duration(seconds: 4));
              } catch (e) {
                print('ℹ️ Backend return API notice: $e');
              }

              // 4. Update local booking storage
              final List<String> listStrings = prefs.getStringList('customer_real_bookings') ?? [];
              List<String> updatedList = [];

              for (var str in listStrings) {
                try {
                  var item = jsonDecode(str);
                  if (item is Map<String, dynamic> && item['id'] == orderId) {
                    item['status'] = 'returned';
                    item['returnNotes'] = notesController.text.trim();
                    item['returnPhotoBase64'] = base64Image;
                    item['returnedAt'] = DateTime.now().toIso8601String();
                    item['userRating'] = userRating;
                    updatedList.add(jsonEncode(item));
                  } else {
                    updatedList.add(str);
                  }
                } catch (_) {
                  updatedList.add(str);
                }
              }
              await prefs.setStringList('customer_real_bookings', updatedList);

              // 5. Save Shop Owner notification
              final List<String> shopNotifs = prefs.getStringList('shop_owner_notifications') ?? [];
              final notifItem = jsonEncode({
                'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
                'title': 'Tool Returned with ${userRating}★ Rating! 📦',
                'message': 'Customer ${booking['userName'] ?? 'User'} returned ${tool['name'] ?? 'Tool'} (Rated ${userRating}★).',
                'orderId': orderId,
                'toolName': tool['name'],
                'returnNotes': notesController.text.trim(),
                'returnPhotoBase64': base64Image,
                'createdAt': DateTime.now().toIso8601String(),
                'read': false,
              });
              shopNotifs.insert(0, notifItem);
              await prefs.setStringList('shop_owner_notifications', shopNotifs);

              // 6. Update local state in screen
              if (mounted) {
                setState(() {
                  for (var b in _bookings) {
                    if (b['id'] == orderId) {
                      b['status'] = 'returned';
                      b['returnNotes'] = notesController.text.trim();
                      b['returnPhotoBase64'] = base64Image;
                      b['returnedAt'] = DateTime.now().toIso8601String();
                      b['userRating'] = userRating;
                    }
                  }
                });
              }

              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⭐ Thank you! Real feedback recorded & tool rating updated in Popular Tools!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Return Tool & Give Feedback',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined, color: AppTheme.primaryYellow, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Order #${orderId} • ${tool['name'] ?? 'Equipment'}',
                              style: const TextStyle(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interactive Customer Star Rating Section
                    const Text(
                      'Rate Tool Performance (Real Customer Rating)',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              final starVal = index + 1.0;
                              final isFilled = starVal <= userRating;
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isFilled ? Icons.star : Icons.star_border,
                                  color: AppTheme.primaryYellow,
                                  size: 30,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    userRating = starVal;
                                  });
                                },
                              );
                            }),
                          ),
                          Text(
                            '${userRating.toStringAsFixed(1)} ★',
                            style: const TextStyle(
                              color: AppTheme.primaryYellow,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Capture Return Photo',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => pickPhoto(ImageSource.camera),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                        ),
                        child: (base64Image != null && base64Image!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  base64Decode(base64Image!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryYellow, size: 36),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Tap to capture tool return photo',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Verify equipment condition upon return',
                                    style: TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera, size: 16, color: AppTheme.primaryYellow),
                          label: const Text('Use Camera', style: TextStyle(color: AppTheme.primaryYellow)),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () => pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 16, color: Colors.white70),
                          label: const Text('From Gallery', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Real Customer Feedback & Return Notes',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Excellent tool performance, worked smoothly...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : submitReturn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Submit Return & Real Feedback ⭐',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text('No bookings yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final tool = booking['tool'] ?? {};
                    final String status = (booking['status'] ?? 'pending').toString().toLowerCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  tool['imageUrl'] ?? '',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryYellow.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.build,
                                        color: AppTheme.primaryYellow,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tool['name'] ?? 'Unknown Tool',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Order #${booking['id'] ?? 'N/A'} • ${tool['category'] ?? 'General'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.black54,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Total Price',
                              '₹${booking['totalPrice']?.toStringAsFixed(0) ?? '0'}'),
                          _buildDetailRow('Rental Days',
                              '${booking['rentalDays'] ?? 0} day(s)'),
                          _buildDetailRow('Start Date',
                              _formatDate(booking['startDate'])),
                          _buildDetailRow('End Date',
                              _formatDate(booking['endDate'])),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(status),
                                        color: _getStatusColor(status),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Status: ${status.toUpperCase()}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (status != 'returned') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showReturnToolModal(booking),
                                icon: const Icon(Icons.assignment_return, size: 18, color: Colors.black),
                                label: const Text(
                                  'Return Tool 🔄',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryYellow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Return submitted & shop owner notified.',
                                      style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return Icons.assignment_turned_in;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }
}

