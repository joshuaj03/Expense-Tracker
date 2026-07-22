/// GlassCard — frosted glassmorphism container used sparingly
/// for hero sections, bottom nav, and modal sheets.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 20,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: isDark
                ? AppColors.glassWhite(opacity)
                : AppColors.glassBlack(opacity * 0.5),
            border: Border.all(
              color: isDark
                  ? AppColors.glassWhite(0.12)
                  : AppColors.glassBlack(0.06),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
