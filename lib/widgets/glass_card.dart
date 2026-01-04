import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/design_system.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 10.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? DesignSystem.glassWhite,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: DesignSystem.glassBorder, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
