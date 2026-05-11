import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(
          borderRadius: borderRadius ?? 16,
          color: color,
        ),
        child: child,
      ),
    );
  }
}

