import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/amount_text.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import 'package:finara/features/transactions/data/transactions_provider.dart';
import '../../data/records_time_view_provider.dart';
import 'package:finara/features/transactions/data/transactions_dao.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/transaction_detail_dialog.dart';
import '../widgets/summary_dialog.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(transactionsDaoProvider);
    final timeState = ref.watch(recordsTimeViewNotifierProvider);
    final (start, end) = timeState.getDateRange();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('Finara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionWithDetails>>(
        stream: dao.watchTransactionsForDateRange(start, end),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;

          return Column(
            children: [
              _TimeViewHeader(timeState: timeState, ref: ref),
              _TotalsHeader(transactions: transactions, timeState: timeState),
              Expanded(
                child: transactions.isEmpty
                    ? const EmptyState(
                        icon: '📄',
                        title: 'No transactions yet',
                        subtitle:
                            'Tap the + button to add your first transaction',
                      )
                    : _TransactionList(transactions: transactions, ref: ref),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimeViewHeader extends StatelessWidget {
  final RecordsTimeState timeState;
  final WidgetRef ref;

  const _TimeViewHeader({required this.timeState, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref
                    .read(recordsTimeViewNotifierProvider.notifier)
                    .previous(),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<RecordsTimeView>(
                        initialValue: timeState.view,
                        onSelected: (view) => ref
                            .read(recordsTimeViewNotifierProvider.notifier)
                            .setView(view),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: RecordsTimeView.daily,
                            child: Text('Daily'),
                          ),
                          PopupMenuItem(
                            value: RecordsTimeView.weekly,
                            child: Text('Weekly'),
                          ),
                          PopupMenuItem(
                            value: RecordsTimeView.monthly,
                            child: Text('Monthly'),
                          ),
                          PopupMenuItem(
                            value: RecordsTimeView.yearly,
                            child: Text('Yearly'),
                          ),
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeState.view.name.replaceFirst(
                                timeState.view.name[0],
                                timeState.view.name[0].toUpperCase(),
                              ),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.accentViolet,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppColors.accentViolet,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => ref
                            .read(recordsTimeViewNotifierProvider.notifier)
                            .resetToToday(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentViolet.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Current',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accentViolet,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timeState.getFormattedDateRange(),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    ref.read(recordsTimeViewNotifierProvider.notifier).next(),
              ),
            ],
          ),
          if (timeState.view == RecordsTimeView.monthly)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MonthToggleBtn(
                    label: '1M',
                    value: 1,
                    current: timeState.monthSpan,
                    ref: ref,
                  ),
                  const SizedBox(width: 8),
                  _MonthToggleBtn(
                    label: '3M',
                    value: 3,
                    current: timeState.monthSpan,
                    ref: ref,
                  ),
                  const SizedBox(width: 8),
                  _MonthToggleBtn(
                    label: '6M',
                    value: 6,
                    current: timeState.monthSpan,
                    ref: ref,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthToggleBtn extends StatelessWidget {
  final String label;
  final int value;
  final int current;
  final WidgetRef ref;

  const _MonthToggleBtn({
    required this.label,
    required this.value,
    required this.current,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return InkWell(
      onTap: () => ref
          .read(recordsTimeViewNotifierProvider.notifier)
          .setMonthSpan(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accentViolet
                : AppColors.lightTextSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.lightTextSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  final List<TransactionWithDetails> transactions;
  final RecordsTimeState timeState;

  const _TotalsHeader({required this.transactions, required this.timeState});

  @override
  Widget build(BuildContext context) {
    double expense = 0;
    double income = 0;

    for (final txn in transactions) {
      if (txn.transaction.type == 'expense') {
        expense += txn.transaction.amount;
      } else if (txn.transaction.type == 'income') {
        income += txn.transaction.amount;
      }
    }
    final total = income - expense;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TotalItem(
                label: 'Income',
                amount: income,
                color: AppColors.income,
              ),
              _TotalItem(
                label: 'Expense',
                amount: expense,
                color: AppColors.expense,
              ),
              _TotalItem(label: 'Total', amount: total, color: null),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SummaryDialog(
                    transactions: transactions,
                    dateRangeString: timeState.getFormattedDateRange(),
                  ),
                );
              },
              icon: const Icon(Icons.pie_chart_outline, size: 18),
              label: const Text('View Summary'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _TotalItem({required this.label, required this.amount, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 4),
        AmountText(
          amount: amount,
          size: AmountSize.small,
          colored: false,
          overrideColor: color,
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<TransactionWithDetails> transactions;
  final WidgetRef ref;

  const _TransactionList({required this.transactions, required this.ref});

  @override
  Widget build(BuildContext context) {
    // Group by date
    final grouped = <String, List<TransactionWithDetails>>{};
    for (final txn in transactions) {
      final key = DateFormatter.relative(txn.transaction.date);
      grouped.putIfAbsent(key, () => []).add(txn);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dayTransactions = grouped[dateKey]!;

        double dayTotal = 0;
        for (final t in dayTransactions) {
          final amt = t.transaction.userShareAmount ?? t.transaction.amount;
          if (t.transaction.type == 'income') {
            dayTotal += amt;
          } else if (t.transaction.type == 'expense') {
            dayTotal -= amt;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateKey, style: AppTypography.labelLarge),
                  AmountText(amount: dayTotal, size: AmountSize.small),
                ],
              ),
            ),
            ...dayTransactions.map(
              (txn) => _TransactionItem(txn: txn, ref: ref),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionWithDetails txn;
  final WidgetRef ref;

  const _TransactionItem({required this.txn, required this.ref});

  @override
  Widget build(BuildContext context) {
    final t = txn.transaction;
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSettle = t.type == 'settle';

    final icon = isTransfer ? '🔄' : (isSettle ? '✅' : (txn.categoryIcon ?? '📌'));
    final title = isTransfer
        ? '${txn.accountName} → ${txn.toAccountName ?? '?'}'
        : (isSettle ? 'Settle' : (txn.categoryName ?? 'Uncategorized'));

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.expense),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) {
        final dao = ref.read(transactionsDaoProvider);
        dao.deleteTransaction(t.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {}, // Placeholder
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => TransactionDetailDialog(txn: txn),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Color(
                        txn.categoryColor ?? 0xFF6C63FF,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: icon.startsWith('http')
                          ? (icon.endsWith('.svg')
                              ? SvgPicture.network(
                                  icon,
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).iconTheme.color ?? Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: icon,
                                    width: 24,
                                    height: 24,
                                    errorWidget: (c, u, e) => const Text(
                                      '📌',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ))
                          : Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (t.note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            t.note,
                            style: AppTypography.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '${txn.accountName} \u2022 ${DateFormatter.time(t.date)}',
                          style: AppTypography.labelSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AmountText(
                    amount: (isIncome || (isSettle && !t.isDebt)) ? (t.userShareAmount ?? t.amount) : -(t.userShareAmount ?? t.amount),
                    size: AmountSize.small,
                    colored: !isTransfer && !isSettle,
                    overrideColor: isTransfer 
                        ? AppColors.transfer 
                        : (isSettle ? (!t.isDebt ? AppColors.income : AppColors.expense) : null),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
