import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color? iconColor;
  final String? trend;
  
  const ProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.trend,
  });
  
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (iconColor ?? AppTheme.bluePrimary).withValues(alpha: 0.4),
                      (iconColor ?? AppTheme.bluePrimary).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (iconColor ?? AppTheme.bluePrimary).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (iconColor ?? AppTheme.bluePrimary).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.blueBright,
                  size: 24,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(delay: 500.ms, duration: 2000.ms, begin: const Offset(1, 1), end: const Offset(1.05, 1.05), curve: Curves.easeInOut)
                  .then()
                  .scale(duration: 2000.ms, begin: const Offset(1.05, 1.05), end: const Offset(1, 1), curve: Curves.easeInOut),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.blueLight.withValues(alpha: 0.4),
                        AppTheme.bluePrimary.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.bluePrimary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    trend!,
                    style: const TextStyle(
                      color: AppTheme.blueBright,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.whiteText,
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
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

