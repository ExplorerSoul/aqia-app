import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A decorative background with subtle star-like speckles.
class StarryBackground extends StatelessWidget {
  final Widget child;

  const StarryBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F0A1E),
                Color(0xFF1A1225),
                AppTheme.blackBackground,
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),
        CustomPaint(
          size: Size.infinite,
          painter: _StarryPainter(),
        ),
        child,
      ],
    );
  }
}

class _StarryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (var i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.0;
      final opacity = 0.1 + random.nextDouble() * 0.3;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
