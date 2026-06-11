import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../themes/app_theme.dart';

class ToolCard extends StatelessWidget {
  final ToolModel tool;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const ToolCard({
    super.key,
    required this.tool,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.mediumGray.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                tool.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Category
              Text(
                tool.category,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
              ),
              const SizedBox(height: 8),
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
                    tool.rating.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${tool.reviewCount})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Price and Location
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${tool.pricePerDay.toStringAsFixed(0)}/day',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryYellow,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        tool.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
