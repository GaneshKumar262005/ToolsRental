import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../themes/app_theme.dart';
import '../widgets/dark_location_map.dart';
import '../widgets/app_image.dart';
import '../dummy_data/dummy_data.dart';

class VendorDetailScreen extends StatefulWidget {
  final VendorModel vendor;

  const VendorDetailScreen({
    super.key,
    required this.vendor,
  });

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 5.0;
  late List<ReviewModel> _vendorReviews;

  @override
  void initState() {
    super.initState();
    // Copy dummy reviews or create specific reviews for vendor
    _vendorReviews = List.from(DummyData.reviews);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _showAddReviewDialog() {
    double tempRating = 5.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.rate_review, color: AppTheme.primaryYellow),
              SizedBox(width: 10),
              Text(
                'Write a Review',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating for ${widget.vendor.name}:',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < tempRating ? Icons.star : Icons.star_border,
                      color: AppTheme.primaryYellow,
                      size: 30,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        tempRating = (index + 1).toDouble();
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Share your rental experience with this vendor...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reviewController.text.trim().isNotEmpty) {
                  setState(() {
                    _vendorReviews.insert(
                      0,
                      ReviewModel(
                        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                        userName: DummyData.currentUser.name,
                        userImageUrl: DummyData.currentUser.imageUrl,
                        rating: tempRating,
                        comment: _reviewController.text.trim(),
                        date: DateTime.now(),
                      ),
                    );
                  });
                  _reviewController.clear();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Review submitted successfully! Thank you for your feedback.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.vendor.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing ${widget.vendor.name} profile...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor Banner & Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppImage(
                      imageUrl: widget.vendor.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.vendor.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                '✓ Verified',
                                style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppTheme.mediumGray, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.vendor.location} • ${widget.vendor.distance} km away',
                              style: const TextStyle(color: AppTheme.mediumGray, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppTheme.primaryYellow, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.vendor.rating}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              ' (${widget.vendor.reviewCount} total reviews)',
                              style: const TextStyle(color: AppTheme.mediumGray, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Vendor Action Buttons (Call, Directions, Message)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${widget.vendor.name}... (+91 98765 43210)')),
                        );
                      },
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('Call Shop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showAddReviewDialog,
                      icon: const Icon(Icons.rate_review_outlined, color: AppTheme.primaryYellow, size: 16),
                      label: const Text('Write Review', style: TextStyle(color: AppTheme.primaryYellow)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryYellow),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Interactive Live Google Maps View Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vendor Live Map Location',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.vendor.distance} km from you',
                        style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DarkLocationMap(
                    height: 250,
                    showCategoryFilter: false,
                    showLegend: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Full Customer Reviews Breakdown Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Customer Reviews & Ratings',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_vendorReviews.length} Reviews',
                        style: const TextStyle(color: AppTheme.mediumGray, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Rating Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              '${widget.vendor.rating}',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => const Icon(Icons.star, color: AppTheme.primaryYellow, size: 14),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.vendor.reviewCount} Ratings',
                              style: const TextStyle(color: AppTheme.mediumGray, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              _buildRatingBar(5, 0.85),
                              _buildRatingBar(4, 0.10),
                              _buildRatingBar(3, 0.03),
                              _buildRatingBar(2, 0.01),
                              _buildRatingBar(1, 0.01),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // List of Reviews
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vendorReviews.length,
                    itemBuilder: (context, index) {
                      final rev = _vendorReviews[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(rev.userImageUrl),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rev.userName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Row(
                                        children: [
                                          ...List.generate(
                                            5,
                                            (i) => Icon(
                                              i < rev.rating ? Icons.star : Icons.star_border,
                                              color: AppTheme.primaryYellow,
                                              size: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${rev.date.day}/${rev.date.month}/${rev.date.year}',
                                            style: const TextStyle(color: AppTheme.mediumGray, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryYellow.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Verified Rental',
                                    style: TextStyle(color: AppTheme.primaryYellow, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              rev.comment,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars ★', style: const TextStyle(color: AppTheme.mediumGray, fontSize: 10)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white10,
                color: AppTheme.primaryYellow,
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
