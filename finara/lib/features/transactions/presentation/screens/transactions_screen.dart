import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/amount_text.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/database/daos/transactions_dao.dart';
import '../../../../core/utils/currency_formatter.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(transactionsDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionWithDetails>>(
        stream: dao.watchAllTransactionsWithDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: '📝',
              title: 'No transactions yet',
              subtitle: 'Tap the + button to add your first transaction',
            );
          }

          final transactions = snapshot.data!;

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

              // Calculate day total
              double dayTotal = 0;
              for (final t in dayTransactions) {
                if (t.transaction.type == 'income') {
                  dayTotal += t.transaction.amount;
                } else if (t.transaction.type == 'expense') {
                  dayTotal -= t.transaction.amount;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index > 0) const SizedBox(height: 16),
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateKey, style: AppTypography.labelLarge),
                        AmountText(
                          amount: dayTotal,
                          size: AmountSize.small,
                        ),
                      ],
                    ),
                  ),
                  // Transactions
                  ...dayTransactions.map((txn) =>
                      _TransactionItem(txn: txn, ref: ref)),
                ],
              );
            },
          );
        },
      ),
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

    final icon = isTransfer ? '🔄' : (txn.categoryIcon ?? '📌');
    final title = isTransfer
        ? '${txn.accountName} → ${txn.toAccountName ?? '?'}'
        : (txn.categoryName ?? 'Uncategorized');

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
      confirmDismiss: (_) async {
        return true;
      },
      onDismissed: (_) {
        final dao = ref.read(transactionsDaoProvider);
        dao.deleteTransaction(t.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Re-insert would need full transaction data stored
                // For alpha, we just show the snackbar
              },
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
              // TODO: Transaction detail view
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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
                      child:
                          Text(icon, style: const TextStyle(fontSize: 20)),
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
                        if (t.note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(t.note,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '${txn.accountName} • ${DateFormatter.time(t.date)}',
                          style: AppTypography.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  AmountText(
                    amount: isIncome ? t.amount : -t.amount,
                    size: AmountSize.small,
                    colored: !isTransfer,
                    overrideColor: isTransfer ? AppColors.transfer : null,
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
