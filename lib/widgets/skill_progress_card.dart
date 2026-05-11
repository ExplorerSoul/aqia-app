import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Progress card for home page: skill name, score, progress bar (e.g. Technical 60, Communication 80)
class SkillProgressCard extends StatelessWidget {
  final String title;
  final int score;
  final int maxScore;
  final Color? barColor;

  const SkillProgressCard({
    super.key,
    required this.title,
    required this.score,
    this.maxScore = 100,
    this.barColor,
  });

  double get _progress => (score / maxScore).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final color = barColor ?? AppTheme.gradientBlue;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.whiteText.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.whiteText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'out of $maxScore',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.whiteText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: AppTheme.carbonGray,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
