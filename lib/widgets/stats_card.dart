import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ Attractive gradient instead of plain white
        gradient: LinearGradient(
          colors: [
            (iconColor ?? AppTheme.primaryYellow).withOpacity(0.85),
            (iconColor ?? AppTheme.primaryYellow),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (iconColor ?? AppTheme.primaryYellow).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ prevent overflow
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8), // ✅ reduced from 10
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22, // ✅ reduced from 24
            ),
          ),
          const SizedBox(height: 10), // ✅ reduced from 12
          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22, // ✅ controlled size
                ),
          ),
          const SizedBox(height: 2), // ✅ reduced from 4
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}