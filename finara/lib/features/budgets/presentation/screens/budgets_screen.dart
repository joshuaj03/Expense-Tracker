import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/budgets_dao.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/budget_progress_bar.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_formatter.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _showAddBudgetDialog() async {
    final categoriesDao = ref.read(categoriesDaoProvider);
    final expenseCategories =
        await categoriesDao.getCategoriesByType('expense');

    if (!mounted) return;

    int? selectedCategoryId;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Set Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: expenseCategories.map((cat) {
                    final isSelected = cat.id == selectedCategoryId;
                    return ChoiceChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (_) => setDialogState(
                          () => selectedCategoryId = cat.id),
                      avatar: Text(cat.icon,
                          style: const TextStyle(fontSize: 14)),
                      selectedColor:
                          Color(cat.color).withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Limit',
                    prefixText: '₹ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedCategoryId == null) return;
                final amount =
                    double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;

                final budgetsDao = ref.read(budgetsDaoProvider);
                await budgetsDao.upsertBudget(BudgetsCompanion(
                  categoryId: Value(selectedCategoryId!),
                  month: Value(_month),
                  year: Value(_year),
                  limitAmount: Value(amount),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetsDao = ref.watch(budgetsDaoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBudgetDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _month--;
                      if (_month < 1) {
                        _month = 12;
                        _year--;
                      }
                    });
                  },
                ),
                Text(
                  DateFormatter.monthYear(DateTime(_year, _month)),
                  style: AppTypography.headlineMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _month++;
                      if (_month > 12) {
                        _month = 1;
                        _year++;
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Budget list
          Expanded(
            child: StreamBuilder<List<BudgetWithCategory>>(
              stream:
                  budgetsDao.watchBudgetsForMonth(_year, _month),
              builder: (context, budgetSnap) {
                if (!budgetSnap.hasData ||
                    budgetSnap.data!.isEmpty) {
                  return EmptyState(
                    icon: '📊',
                    title: 'No budgets set',
                    subtitle:
                        'Set spending limits for your categories',
                    action: FilledButton.icon(
                      onPressed: _showAddBudgetDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Budget'),
                    ),
                  );
                }

                return FutureBuilder<Map<int, double>>(
                  future: budgetsDao.getSpendingForMonth(
                      _year, _month),
                  builder: (context, spendingSnap) {
                    final spending = spendingSnap.data ?? {};
                    final budgets = budgetSnap.data!;

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          16, 8, 16, 100),
                      itemCount: budgets.length,
                      itemBuilder: (context, index) {
                        final bwc = budgets[index];
                        final spent = spending[
                                bwc.budget.categoryId] ??
                            0;
                        final remaining =
                            bwc.budget.limitAmount - spent;

                        return Dismissible(
                          key: ValueKey(bwc.budget.id),
                          direction:
                              DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.only(right: 20),
                            margin:
                                const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.expense
                                  .withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: const Icon(
                                Icons.delete_outline,
                                color: AppColors.expense),
                          ),
                          onDismissed: (_) {
                            budgetsDao
                                .deleteBudget(bwc.budget.id);
                          },
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Color(bwc
                                                .categoryColor)
                                            .withValues(
                                                alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(
                                                10),
                                      ),
                                      child: Center(
                                        child: Text(
                                            bwc.categoryIcon,
                                            style:
                                                const TextStyle(
                                                    fontSize:
                                                        18)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        bwc.categoryName,
                                        style: AppTypography
                                            .bodyMedium
                                            .copyWith(
                                                fontWeight:
                                                    FontWeight
                                                        .w600),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .end,
                                      children: [
                                        Text(
                                          '${CurrencyFormatter.compact(spent)} / ${CurrencyFormatter.compact(bwc.budget.limitAmount)}',
                                          style: AppTypography
                                              .bodySmall,
                                        ),
                                        Text(
                                          remaining >= 0
                                              ? '${CurrencyFormatter.compact(remaining)} left'
                                              : '${CurrencyFormatter.compact(remaining.abs())} over',
                                          style: AppTypography
                                              .labelSmall
                                              .copyWith(
                                            color: remaining >= 0
                                                ? AppColors
                                                    .income
                                                : AppColors
                                                    .expense,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                BudgetProgressBar(
                                  spent: spent,
                                  limit:
                                      bwc.budget.limitAmount,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
