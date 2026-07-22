import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/glass_card.dart';
import '../../../../core/design_system/widgets/amount_text.dart';
import '../../../../core/design_system/widgets/budget_progress_bar.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/daos/transactions_dao.dart';

/// Provider to track whether balances are hidden.
final balanceHiddenProvider = StateProvider<bool>((ref) => false);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('F',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Text('Finara', style: AppTypography.displaySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BalanceHeroCard(),
            const SizedBox(height: 20),
            _QuickActions(),
            const SizedBox(height: 24),
            _SectionHeader(
                title: 'Recent Transactions',
                onSeeAll: () {
                  final shell = StatefulNavigationShell.of(context);
                  shell.goBranch(1);
                }),
            const SizedBox(height: 12),
            _RecentTransactionsList(),
            const SizedBox(height: 24),
            _SectionHeader(
                title: 'Budget Overview',
                onSeeAll: () {
                  final shell = StatefulNavigationShell.of(context);
                  shell.goBranch(3);
                }),
            const SizedBox(height: 12),
            _BudgetSnapshotSection(),
          ],
        ),
      ),
    );
  }
}

class _BalanceHeroCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsDao = ref.watch(accountsDaoProvider);
    final transactionsDao = ref.watch(transactionsDaoProvider);
    final isHidden = ref.watch(balanceHiddenProvider);
    final now = DateTime.now();

    return StreamBuilder<double>(
      stream: accountsDao.watchTotalBalance(),
      builder: (context, balanceSnap) {
        return StreamBuilder(
          stream: transactionsDao.watchMonthlyTotals(now.year, now.month),
          builder: (context, totalsSnap) {
            final totalBalance = balanceSnap.data ?? 0.0;
            final income = totalsSnap.data?.income ?? 0.0;
            final expense = totalsSnap.data?.expense ?? 0.0;

            return Container(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentViolet.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: GlassCard(
                opacity: 0.12,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Balance',
                          style: AppTypography.labelMedium
                              .copyWith(color: Colors.white70),
                        ),
                        // Eye toggle
                        GestureDetector(
                          onTap: () {
                            ref.read(balanceHiddenProvider.notifier).state =
                                !isHidden;
                          },
                          child: Icon(
                            isHidden
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white60,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHidden
                          ? '₹ ••••••'
                          : CurrencyFormatter.format(totalBalance),
                      style: AppTypography.currencyLarge
                          .copyWith(color: Colors.white, fontSize: 32),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Income',
                            amount: income,
                            icon: Icons.arrow_downward,
                            color: AppColors.incomeLight,
                            isHidden: isHidden,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Expenses',
                            amount: expense,
                            icon: Icons.arrow_upward,
                            color: AppColors.expenseLight,
                            isHidden: isHidden,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isHidden;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isHidden = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style:
                    AppTypography.labelSmall.copyWith(color: Colors.white60)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isHidden ? '₹ ••••' : CurrencyFormatter.compact(amount),
          style: AppTypography.currencySmall
              .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionChip(
          icon: Icons.search,
          label: 'Search',
          onTap: () => context.push('/search'),
        ),
        const SizedBox(width: 10),
        _ActionChip(
          icon: Icons.category_outlined,
          label: 'Categories',
          onTap: () => context.push('/categories'),
        ),
        const SizedBox(width: 10),
        _ActionChip(
          icon: Icons.backup_outlined,
          label: 'Backup',
          onTap: () => context.push('/backup'),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, size: 22, color: AppColors.accentViolet),
                const SizedBox(height: 6),
                Text(label, style: AppTypography.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headlineSmall),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text('See all',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.accentViolet)),
          ),
      ],
    );
  }
}

class _RecentTransactionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(transactionsDaoProvider);

    return StreamBuilder<List<TransactionWithDetails>>(
      stream: dao.watchAllTransactionsWithDetails(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const EmptyState(
            icon: '📝',
            title: 'No transactions yet',
            subtitle: 'Tap + to add your first transaction',
          );
        }

        final transactions = snapshot.data!;
        return Column(
          children: transactions.map((txn) {
            return _TransactionTile(txn: txn);
          }).toList(),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionWithDetails txn;

  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final t = txn.transaction;
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHidden =
        ProviderScope.containerOf(context).read(balanceHiddenProvider);

    final icon = isTransfer ? '🔄' : (txn.categoryIcon ?? '📌');
    final title = isTransfer
        ? '${txn.accountName} → ${txn.toAccountName ?? '?'}'
        : (txn.categoryName ?? 'Uncategorized');
    final subtitle = isTransfer ? 'Transfer' : txn.accountName;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            context.push('/add-transaction?editId=${t.id}');
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color(txn.categoryColor ?? 0xFF6C63FF)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '$subtitle • ${DateFormatter.relative(t.date)}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                isHidden
                    ? Text('₹ ••••',
                        style: AppTypography.currencySmall
                            .copyWith(color: AppColors.accentViolet))
                    : AmountText(
                        amount: isIncome ? t.amount : -t.amount,
                        size: AmountSize.small,
                        colored: !isTransfer,
                        overrideColor:
                            isTransfer ? AppColors.transfer : null,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetSnapshotSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsDao = ref.watch(budgetsDaoProvider);
    final now = DateTime.now();

    return StreamBuilder(
      stream: budgetsDao.watchBudgetsForMonth(now.year, now.month),
      builder: (context, budgetSnap) {
        if (!budgetSnap.hasData || budgetSnap.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('📊', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('No budgets set', style: AppTypography.bodyMedium),
                const SizedBox(height: 4),
                Text('Set category budgets to track spending',
                    style: AppTypography.bodySmall),
              ],
            ),
          );
        }

        return FutureBuilder<Map<int, double>>(
          future: budgetsDao.getSpendingForMonth(now.year, now.month),
          builder: (context, spendingSnap) {
            final spending = spendingSnap.data ?? {};
            final budgets = budgetSnap.data!;

            budgets.sort((a, b) {
              final aSpent = spending[a.budget.categoryId] ?? 0;
              final bSpent = spending[b.budget.categoryId] ?? 0;
              final aRatio = a.budget.limitAmount > 0
                  ? aSpent / a.budget.limitAmount
                  : 0.0;
              final bRatio = b.budget.limitAmount > 0
                  ? bSpent / b.budget.limitAmount
                  : 0.0;
              return bRatio.compareTo(aRatio);
            });

            final top = budgets.take(3).toList();

            return Column(
              children: top.map((bwc) {
                final spent = spending[bwc.budget.categoryId] ?? 0;
                final remaining = bwc.budget.limitAmount - spent;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(bwc.categoryIcon,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(bwc.categoryName,
                                  style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${CurrencyFormatter.compact(spent)} / ${CurrencyFormatter.compact(bwc.budget.limitAmount)}',
                                style: AppTypography.bodySmall,
                              ),
                              Text(
                                remaining >= 0
                                    ? '${CurrencyFormatter.compact(remaining)} left'
                                    : '${CurrencyFormatter.compact(remaining.abs())} over',
                                style: AppTypography.labelSmall.copyWith(
                                  color: remaining >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BudgetProgressBar(
                        spent: spent,
                        limit: bwc.budget.limitAmount,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
