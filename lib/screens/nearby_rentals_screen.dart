import 'package:flutter/material.dart';
import '../dummy_data/dummy_data.dart';
import '../models/tool_model.dart';
import '../themes/app_theme.dart';
import '../widgets/vendor_card.dart';
import '../widgets/tool_card.dart';
import 'booking_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              // Show map view
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                // Mock map background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.lightGray,
                        AppTheme.mediumGray.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Map markers
                ...DummyData.vendors.asMap().entries.map((entry) {
                  final index = entry.key;
                  return Positioned(
                    left: 50 + (index * 80),
                    top: 60 + (index * 30 % 80),
                    child: GestureDetector(
                      onTap: () {
                        // Scroll to vendor
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlack.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryBlack,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                // Current location marker
                const Positioned(
                  left: 150,
                  top: 100,
                  child: Icon(
                    Icons.my_location,
                    color: AppTheme.accentBlue,
                    size: 32,
                  ),
                ),
              ],
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
                        _showVendorBottomSheet(vendor);
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
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
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
          ],
        ),
      ),
    );
  }
}
