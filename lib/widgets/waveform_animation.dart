import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveformAnimation extends StatefulWidget {
  final bool isActive;
  final Color? color;
  
  const WaveformAnimation({
    super.key,
    required this.isActive,
    this.color,
  });
  
  @override
  State<WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<WaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 60),
          painter: WaveformPainter(
            animationValue: _controller.value,
            color: widget.color ?? Colors.white,
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  
  WaveformPainter({
    required this.animationValue,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final barWidth = 4.0;
    final spacing = 6.0;
    final maxHeight = size.height * 0.8;
    final minHeight = size.height * 0.2;
    final barCount = (size.width / (barWidth + spacing)).floor();
    
    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing) + barWidth / 2;
      final phase = (i / barCount + animationValue) * 2 * math.pi;
      final height = minHeight + (maxHeight - minHeight) * (math.sin(phase) * 0.5 + 0.5);
      final startY = (size.height - height) / 2;
      final endY = startY + height;
      
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, endY),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

