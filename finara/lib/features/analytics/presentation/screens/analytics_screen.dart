import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import 'package:finara/features/transactions/data/transactions_dao.dart';
import 'package:finara/features/categories/data/categories_dao.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';

import '../../../../core/design_system/widgets/empty_state.dart';
import 'package:finara/features/categories/data/categories_provider.dart';
import 'package:finara/features/transactions/data/transactions_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

typedef MonthlyTrend = ({int year, int month, double income, double expense});

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth--;
      if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth >= now.month) return;
    setState(() {
      _selectedMonth++;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsDao = ref.watch(transactionsDaoProvider);
    final categoriesDao = ref.watch(categoriesDaoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month selector
            _MonthSelector(
              year: _selectedYear,
              month: _selectedMonth,
              onPrevious: _previousMonth,
              onNext: _nextMonth,
            ),
            const SizedBox(height: 20),

            // Cash flow summary
            _CashFlowSummary(
              dao: transactionsDao,
              year: _selectedYear,
              month: _selectedMonth,
            ),
            const SizedBox(height: 24),

            // Spending donut chart
            Text('Spending by Category', style: AppTypography.headlineSmall),
            const SizedBox(height: 16),
            _SpendingDonutChart(
              transactionsDao: transactionsDao,
              categoriesDao: categoriesDao,
              year: _selectedYear,
              month: _selectedMonth,
            ),
            const SizedBox(height: 24),

            // Monthly trend bar chart
            Text('Monthly Trend', style: AppTypography.headlineSmall),
            const SizedBox(height: 16),
            _MonthlyTrendChart(dao: transactionsDao),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.year,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevious),
        Text(
          DateFormatter.monthYear(DateTime(year, month)),
          style: AppTypography.headlineMedium,
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
      ],
    );
  }
}

class _CashFlowSummary extends StatelessWidget {
  final TransactionsDao dao;
  final int year;
  final int month;

  const _CashFlowSummary({
    required this.dao,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<({double income, double expense})>(
      stream: dao.watchMonthlyTotals(year, month),
      builder: (context, snapshot) {
        final income = snapshot.data?.income ?? 0.0;
        final expense = snapshot.data?.expense ?? 0.0;
        final net = income - expense;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Income',
                amount: income,
                color: AppColors.income,
                icon: Icons.arrow_downward,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Expense',
                amount: expense,
                color: AppColors.expense,
                icon: Icons.arrow_upward,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Net',
                amount: net,
                color: net >= 0 ? AppColors.income : AppColors.expense,
                icon: net >= 0 ? Icons.trending_up : Icons.trending_down,
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.compact(amount),
            style: AppTypography.currencySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SpendingDonutChart extends StatelessWidget {
  final TransactionsDao transactionsDao;
  final CategoriesDao categoriesDao;
  final int year;
  final int month;

  const _SpendingDonutChart({
    required this.transactionsDao,
    required this.categoriesDao,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<int, double>>(
      stream: transactionsDao.watchCategorySpending(year, month),
      builder: (context, spendingSnap) {
        if (!spendingSnap.hasData || spendingSnap.data!.isEmpty) {
          return const SizedBox(
            height: 200,
            child: EmptyState(
              icon: '📊',
              title: 'No spending data',
              subtitle: 'Add expenses to see your breakdown',
            ),
          );
        }

        final spending = spendingSnap.data!;
        final total = spending.values.fold<double>(0, (s, v) => s + v);

        return FutureBuilder<List<Category>>(
          future: categoriesDao.getAllCategories(),
          builder: (context, catSnap) {
            final categories = catSnap.data ?? [];
            final catMap = {for (var c in categories) c.id: c};

            final entries = spending.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: entries.map((e) {
                        final cat = catMap[e.key];
                        final pct = total > 0 ? e.value / total * 100 : 0.0;
                        return PieChartSectionData(
                          value: e.value,
                          title: pct >= 5 ? '${pct.round()}%' : '',
                          color: Color(cat?.color ?? 0xFF6C63FF),
                          radius: 35,
                          titleStyle: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                ...entries.take(8).map((e) {
                  final cat = catMap[e.key];
                  final pct = total > 0 ? (e.value / total * 100) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(cat?.color ?? 0xFF6C63FF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat?.icon ?? '📌',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cat?.name ?? 'Unknown',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.compact(e.value),
                          style: AppTypography.currencySmall,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${pct.round()}%',
                            style: AppTypography.labelSmall,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  final TransactionsDao dao;

  const _MonthlyTrendChart({required this.dao});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<MonthlyTrend>>(
      future: dao.getMonthlyTrend(6),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 200);
        }

        final data = snapshot.data!;
        final maxVal = data.fold<double>(0, (m, d) {
          return [m, d.income, d.expense].reduce((a, b) => a > b ? a : b);
        });

        return Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal > 0 ? maxVal * 1.2 : 1000,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < data.length) {
                        return Text(
                          DateFormatter.monthAbbr(data[idx].month),
                          style: AppTypography.labelSmall,
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        CurrencyFormatter.compact(value),
                        style: AppTypography.labelSmall,
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(data.length, (i) {
                final d = data[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: d.income,
                      color: AppColors.income.withValues(alpha: 0.8),
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: d.expense,
                      color: AppColors.expense.withValues(alpha: 0.8),
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
