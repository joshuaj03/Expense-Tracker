import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/amount_text.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import 'package:finara/features/accounts/data/accounts_provider.dart';
import 'package:finara/features/transactions/data/transactions_provider.dart';
import 'package:finara/features/transactions/data/transactions_dao.dart';
import 'package:finara/features/transactions/data/records_time_view_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/presentation/widgets/transaction_detail_dialog.dart';

class AccountDetailScreen extends ConsumerWidget {
  final int accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountDao = ref.watch(accountsDaoProvider);
    final txDao = ref.watch(transactionsDaoProvider);
    final timeState = ref.watch(recordsTimeViewNotifierProvider);
    final (start, end) = timeState.getDateRange();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit-account/$accountId'),
          ),
        ],
      ),
      body: FutureBuilder<Account?>(
        future: accountDao.getAccountById(accountId),
        builder: (context, accSnapshot) {
          if (accSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final account = accSnapshot.data;
          if (account == null) {
            return const Center(child: Text('Account not found'));
          }

          return StreamBuilder<List<TransactionWithDetails>>(
            stream: txDao.watchTransactionsForAccountAndDateRange(
              accountId,
              start,
              end,
            ),
            builder: (context, txSnapshot) {
              if (txSnapshot.connectionState == ConnectionState.waiting &&
                  !txSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final transactions = txSnapshot.data ?? [];
              double income = 0;
              double expense = 0;

              for (final t in transactions) {
                if (t.transaction.type == 'income') {
                  income += t.transaction.amount;
                } else if (t.transaction.type == 'expense') {
                  expense += t.transaction.amount;
                }
              }
              final netAmount = income - expense;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Color(
                                    account.color,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    account.icon,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name,
                                      style: AppTypography.headlineMedium,
                                    ),
                                    Text(
                                      account.type.toUpperCase(),
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Net Amount
                          Text(
                            'Net Amount (${timeState.view.name})',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          AmountText(
                            amount: netAmount,
                            size: AmountSize.large,
                            overrideColor: netAmount >= 0
                                ? AppColors.income
                                : AppColors.expense,
                          ),

                          const SizedBox(height: 24),

                          // Billing history if Credit Card
                          if (account.type == 'creditCard') ...[
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (ctx) =>
                                        _BillHistorySheet(accountId: accountId),
                                  );
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('View Bill History'),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Transactions count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transactions',
                                style: AppTypography.labelLarge,
                              ),
                              Text(
                                '${transactions.length} records',
                                style: AppTypography.labelSmall,
                              ),
                            ],
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),

                  // Transactions List
                  if (transactions.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: '📄',
                        title: 'No transactions',
                        subtitle: 'No records found for this period.',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = transactions[index];
                        final txn = item.transaction;
                        final isIncome = txn.type == 'income';
                        final isTransfer =
                            txn.type == 'transfer' ||
                            txn.type == 'creditCardPayment';

                        return ListTile(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  TransactionDetailDialog(txn: item),
                            );
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isTransfer
                                  ? AppColors.accentViolet.withValues(
                                      alpha: 0.1,
                                    )
                                  : (item.categoryColor != null
                                            ? Color(item.categoryColor!)
                                            : Colors.grey)
                                        .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                isTransfer ? '↔️' : (item.categoryIcon ?? '📄'),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          title: Text(
                            isTransfer
                                ? 'Transfer to ${item.toAccountName}'
                                : (item.categoryName ?? 'Uncategorized'),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${txn.date.day}/${txn.date.month}/${txn.date.year}',
                            style: AppTypography.labelSmall,
                          ),
                          trailing: AmountText(
                            amount: txn.amount,
                            size: AmountSize.medium,
                            overrideColor: isTransfer
                                ? AppColors.lightTextPrimary
                                : (isIncome
                                      ? AppColors.income
                                      : AppColors.expense),
                          ),
                        );
                      }, childCount: transactions.length),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BillHistorySheet extends ConsumerWidget {
  final int accountId;

  const _BillHistorySheet({required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountDao = ref.watch(accountsDaoProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Billing History', style: AppTypography.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<CreditCardBill>>(
                  stream: accountDao.watchBillsForAccount(accountId),
                  builder: (context, billSnapshot) {
                    if (billSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!billSnapshot.hasData) return const SizedBox();
                    final bills = billSnapshot.data!.toList();
                    if (bills.isEmpty) {
                      return const Center(
                        child: Text('No bills generated yet.'),
                      );
                    }

                    bills.sort((a, b) {
                      final aVal = a.billingYear * 12 + a.billingMonth;
                      final bVal = b.billingYear * 12 + b.billingMonth;
                      return bVal.compareTo(aVal);
                    });

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: bills.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        final monthStr = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ][bill.billingMonth - 1];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '$monthStr ${bill.billingYear} Statement',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Amount: ${CurrencyFormatter.format(bill.billAmount ?? 0.0)}',
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: bill.isPaid
                                  ? AppColors.income.withValues(alpha: 0.1)
                                  : AppColors.expense.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              bill.isPaid ? 'PAID' : 'UNPAID',
                              style: TextStyle(
                                color: bill.isPaid
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
