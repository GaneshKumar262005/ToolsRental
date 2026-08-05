import 'package:flutter/material.dart';
import '../dummy_data/dummy_data.dart';
import '../models/tool_model.dart';
import '../themes/app_theme.dart';
import '../widgets/vendor_card.dart';
import '../widgets/tool_card.dart';
import '../widgets/dark_location_map.dart';
import 'booking_screen.dart';

import 'vendor_detail_screen.dart';

class NearbyRentalsScreen extends StatefulWidget {
  const NearbyRentalsScreen({super.key});

  @override
  State<NearbyRentalsScreen> createState() => _NearbyRentalsScreenState();
}

class _NearbyRentalsScreenState extends State<NearbyRentalsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Rentals'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: DarkLocationMap(
              height: 260,
              title: 'Nearby Equipment & Shop Map',
              showCategoryFilter: true,
              showLegend: true,
            ),
          ),

          // Vendor list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: DummyData.vendors.length,
              itemBuilder: (context, index) {
                final vendor = DummyData.vendors[index];
                return Column(
                  children: [
                    VendorCard(
                      vendor: vendor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VendorDetailScreen(vendor: vendor),
                          ),
                        );
                      },
                    ),
                    if (index < DummyData.vendors.length - 1) const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showVendorBottomSheet(VendorModel vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.primaryWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.mediumGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Vendor info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(vendor.imageUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppTheme.mediumGray),
                            const SizedBox(width: 4),
                            Text(
                              vendor.location,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${vendor.distance}km',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryYellow,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Available tools
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.of(context).size.width;
                  final crossAxisCount = width >= 1200 ? 4 : (width >= 800 ? 3 : 2);
                  final childAspectRatio = width >= 1200 ? 0.90 : (width >= 800 ? 0.85 : 0.64);
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: DummyData.tools.take(4).length,
                        itemBuilder: (context, index) {
                          final tool = DummyData.tools[index];
                          return ToolCard(
                            tool: tool,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(tool: tool),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
