/// AmountText â€” auto-colored currency display with sign.
/// Green for positive/income, red/coral for negative/expense.
library;

import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import '../../utils/currency_formatter.dart';

enum AmountSize { large, medium, small }

class AmountText extends StatelessWidget {
  final double amount;
  final AmountSize size;
  final bool showSign;
  final bool colored;
  final Color? overrideColor;

  const AmountText({
    super.key,
    required this.amount,
    this.size = AmountSize.medium,
    this.showSign = true,
    this.colored = true,
    this.overrideColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = switch (size) {
      AmountSize.large => AppTypography.currencyLarge,
      AmountSize.medium => AppTypography.currencyMedium,
      AmountSize.small => AppTypography.currencySmall,
    };

    final color =
        overrideColor ??
        (colored
            ? (amount >= 0 ? AppColors.income : AppColors.expense)
            : Theme.of(context).textTheme.bodyLarge?.color);

    final prefix = showSign ? (amount >= 0 ? '+ ' : '- ') : '';
    final formatted = CurrencyFormatter.format(amount.abs());

    return Text('$prefix$formatted', style: style.copyWith(color: color));
  }
}
