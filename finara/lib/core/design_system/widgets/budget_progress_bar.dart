/// BudgetProgressBar — gradient fill with over-budget state.
library;

import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double limit;
  final String? label;

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.limit,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.5) : 0.0;
    final isOverBudget = spent > limit;
    final percentage = (progress * 100).round();

    final barColor = isOverBudget
        ? AppColors.expense
        : progress > 0.8
            ? AppColors.warning
            : AppColors.income;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label!, style: AppTypography.labelMedium),
              Text(
                '$percentage%',
                style: AppTypography.labelMedium.copyWith(
                  color: barColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: barColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
