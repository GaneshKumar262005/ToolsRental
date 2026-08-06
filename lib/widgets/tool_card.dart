import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../themes/app_theme.dart';
import 'app_image.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final imageHeight = isMobile ? 105.0 : 135.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppTheme.primaryWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppTheme.primaryYellow.withOpacity(0.2)
                : AppTheme.mediumGray.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medium Image Box (Product style) with Most Liked Badge Tag
            Stack(
              children: [
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  margin: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AppImage(
                        imageUrl: tool.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (tool.hasRealFeedback)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            'RATED ${tool.lastFeedbackRating ?? tool.rating}★ BY CUSTOMER',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Text details & website layout
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 2 : 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tool.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryYellow,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      tool.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.primaryBlack,
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.primaryYellow, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          '${tool.rating}',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.primaryBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${tool.reviewCount})',
                          style: const TextStyle(color: AppTheme.mediumGray, fontSize: 9),
                        ),
                        const Spacer(),
                        const Icon(Icons.location_on_outlined, color: AppTheme.mediumGray, size: 10),
                        Text(
                          ' ${tool.location}',
                          style: const TextStyle(color: AppTheme.mediumGray, fontSize: 9),
                        ),
                      ],
                    ),
                    if (tool.hasRealFeedback && tool.lastFeedbackComment != null && tool.lastFeedbackComment!.isNotEmpty)
                      Text(
                        '💬 "${tool.lastFeedbackComment}"',
                        style: const TextStyle(
                          color: AppTheme.primaryYellow,
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Rental Price',
                              style: TextStyle(color: AppTheme.mediumGray, fontSize: 8),
                            ),
                            Text(
                              '₹${tool.pricePerDay.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                color: AppTheme.primaryYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Rent',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
