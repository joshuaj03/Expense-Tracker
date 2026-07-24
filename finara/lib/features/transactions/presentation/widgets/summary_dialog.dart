import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finara/core/design_system/app_colors.dart';
import 'package:finara/core/design_system/app_typography.dart';
import 'package:finara/features/transactions/data/transactions_dao.dart';
import 'package:finara/core/utils/currency_formatter.dart';

class SummaryDialog extends StatelessWidget {
  final List<TransactionWithDetails> transactions;
  final String dateRangeString;

  const SummaryDialog({
    super.key,
    required this.transactions,
    required this.dateRangeString,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate expenses by category
    final expensesByCategory = <String, double>{};
    final categoryColors = <String, Color>{};
    double totalExpense = 0;

    for (final txn in transactions) {
      if (txn.transaction.type == 'expense') {
        final catName = txn.categoryName ?? 'Uncategorized';
        expensesByCategory[catName] =
            (expensesByCategory[catName] ?? 0) + txn.transaction.amount;
        if (!categoryColors.containsKey(catName)) {
          categoryColors[catName] = Color(txn.categoryColor ?? 0xFF6C63FF);
        }
        totalExpense += txn.transaction.amount;
      }
    }

    final sortedCategories = expensesByCategory.keys.toList()
      ..sort(
        (a, b) => expensesByCategory[b]!.compareTo(expensesByCategory[a]!),
      );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Summary', style: AppTypography.headlineMedium),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(dateRangeString, style: AppTypography.labelLarge),
            const SizedBox(height: 24),
            if (totalExpense == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No expenses in this period.'),
                ),
              )
            else ...[
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sortedCategories.map((cat) {
                      final amount = expensesByCategory[cat]!;
                      final percentage = (amount / totalExpense * 100)
                          .toStringAsFixed(0);
                      return PieChartSectionData(
                        color: categoryColors[cat],
                        value: amount,
                        title: '$percentage%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Expense Breakdown',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    final cat = sortedCategories[index];
                    final amount = expensesByCategory[cat]!;
                    final color = categoryColors[cat];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(cat, overflow: TextOverflow.ellipsis),
                          ),
                          Text(CurrencyFormatter.format(amount)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
