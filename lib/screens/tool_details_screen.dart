import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tool_model.dart';
import '../dummy_data/dummy_data.dart';
import '../themes/app_theme.dart';
import '../widgets/vendor_card.dart';
import '../widgets/review_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tool_card.dart';
import 'vendor_detail_screen.dart';

class ToolDetailsScreen extends StatefulWidget {
  final ToolModel tool;

  const ToolDetailsScreen({super.key, required this.tool});

  @override
  State<ToolDetailsScreen> createState() => _ToolDetailsScreenState();
}

class _ToolDetailsScreenState extends State<ToolDetailsScreen> {
  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryWhite,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image carousel
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 1.0,
                      autoPlay: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImage = index;
                        });
                      },
                    ),
                    items: widget.tool.imageUrls.map((imageUrl) {
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.lightGray,
                          child: const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.lightGray,
                          child: const Icon(Icons.error_outline),
                        ),
                      );
                    }).toList(),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryBlack.withOpacity(0.3),
                          Colors.transparent,
                          Colors.transparent,
                          AppTheme.primaryBlack.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  // Image indicator
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.tool.imageUrls.asMap().entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImage == entry.key
                                ? AppTheme.primaryYellow
                                : AppTheme.primaryWhite.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and availability
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.tool.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (widget.tool.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.accentGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Available',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.accentGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cancel,
                                color: AppTheme.accentRed,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Unavailable',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.accentRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Category and rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.tool.category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: AppTheme.primaryYellow, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        widget.tool.rating.toString(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.tool.reviewCount} reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price
                  Row(
                    children: [
                      Text(
                        '₹${widget.tool.pricePerDay.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppTheme.primaryYellow,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/day',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.tool.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Specifications
                  Text(
                    'Specifications',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.tool.specifications.map((spec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          spec,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Vendor card
                  Text(
                    'Vendor',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  VendorCard(
                    vendor: widget.tool.vendor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendorDetailScreen(vendor: widget.tool.vendor),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Reviews
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryYellow,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...DummyData.reviews.take(3).map((review) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReviewCard(review: review),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  // Related tools
                  Text(
                    'Related Tools',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: DummyData.tools.take(4).length,
                      itemBuilder: (context, index) {
                        final tool = DummyData.tools[index];
                        if (tool.id == widget.tool.id) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 180,
                            child: ToolCard(
                              tool: tool,
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ToolDetailsScreen(tool: tool),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom sheet with book button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryWhite,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlack.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Price',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                    ),
                    Text(
                      '₹${widget.tool.pricePerDay.toStringAsFixed(0)}/day',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryYellow,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Book now button
              Expanded(
                flex: 2,
                child: GradientButton(
                  text: 'Book Now',
                  onPressed: widget.tool.isAvailable
                      ? () {
                          Navigator.pushNamed(context, '/booking', arguments: widget.tool);
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
