/// SegmentedControl â€” Income / Expense / Transfer selector.
library;

import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

class SegmentedControl<T> extends StatelessWidget {
  final List<T> segments;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final Color Function(T)? colorBuilder;

  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    this.colorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: segments.map((segment) {
            final isSelected = segment == selected;
            final color = colorBuilder?.call(segment) ?? AppColors.accentViolet;

            return GestureDetector(
              onTap: () => onChanged(segment),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: color.withValues(alpha: 0.3))
                      : null,
                ),
                child: Text(
                  labelBuilder(segment),
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected
                        ? color
                        : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
