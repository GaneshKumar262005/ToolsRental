import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../themes/app_theme.dart';
import '../widgets/app_image.dart';

class VendorCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback? onTap;

  const VendorCard({
    super.key,
    required this.vendor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage(
                imageUrl: vendor.imageUrl,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    vendor.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vendor.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
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
                  const SizedBox(height: 6),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppTheme.primaryYellow,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vendor.rating.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${vendor.reviewCount} reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppTheme.mediumGray,
            ),
          ],
        ),
      ),
    );
  }
}
