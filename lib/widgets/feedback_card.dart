import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class FeedbackCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  
  const FeedbackCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.4),
                  color.withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppTheme.blueBright,
              size: 28,
            ),
          )
              .animate()
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 2000.ms, color: color.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.whiteText,
            ),
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.whiteText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

