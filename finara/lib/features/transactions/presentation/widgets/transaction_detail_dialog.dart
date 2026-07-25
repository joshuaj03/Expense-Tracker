import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finara/core/design_system/app_colors.dart';
import 'package:finara/core/design_system/app_typography.dart';
import 'package:finara/core/design_system/widgets/amount_text.dart';
import 'package:finara/features/transactions/data/transactions_dao.dart';
import 'package:finara/features/transactions/data/transactions_provider.dart';
import 'package:finara/core/utils/currency_formatter.dart';

class TransactionDetailDialog extends ConsumerWidget {
  final TransactionWithDetails txn;

  const TransactionDetailDialog({super.key, required this.txn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = txn.transaction;
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSettle = t.type == 'settle';

    final icon = isTransfer ? '🔄' : (isSettle ? '✅' : (txn.categoryIcon ?? '📌'));
    final title = isTransfer
        ? '${txn.accountName} → ${txn.toAccountName ?? '?'}'
        : (isSettle ? 'Settle' : (txn.categoryName ?? 'Uncategorized'));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar with Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(
                      txn.categoryColor ?? 0xFF6C63FF,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: icon.startsWith('http')
                        ? (icon.endsWith('.svg')
                            ? SvgPicture.network(
                                icon,
                                width: 28,
                                height: 28,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).iconTheme.color ?? Colors.black,
                                  BlendMode.srcIn,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: icon,
                                  width: 28,
                                  height: 28,
                                  errorWidget: (c, u, e) => const Text(
                                    '📌',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ))
                        : Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      tooltip: 'Duplicate (Today)',
                      onPressed: () {
                        context.pop();
                        context.push('/add-transaction?duplicateId=${t.id}');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      tooltip: 'Edit',
                      onPressed: () {
                        context.pop();
                        context.push('/add-transaction?editId=${t.id}');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.expense,
                      ),
                      tooltip: 'Delete',
                      onPressed: () {
                        final dao = ref.read(transactionsDaoProvider);
                        dao.deleteTransaction(t.id);
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaction deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                // Full undo requires saving the exact state.
                                // For now it's just a placeholder as before.
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            Text(title, style: AppTypography.headlineMedium),
            const SizedBox(height: 4),
            Text(
              '${DateFormatter.full(t.date)} at ${DateFormatter.time(t.date)}',
              style: AppTypography.bodySmall,
            ),
            if (t.type == 'transfer' && (t.isSplit || t.isDebt)) ...[
              const SizedBox(height: 4),
              Text(
                'Debt • ${t.isSplit ? 'Lend' : 'Borrow'}',
                style: AppTypography.bodySmall.copyWith(
                  color: t.isSplit ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else if (t.type == 'settle') ...[
              const SizedBox(height: 4),
              Text(
                'Debt Payment • ${!t.isDebt ? 'Recover' : 'Pay Back'}',
                style: AppTypography.bodySmall.copyWith(
                  color: !t.isDebt ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount', style: AppTypography.bodyMedium),
                      AmountText(
                        amount: t.amount,
                        size: AmountSize.medium,
                        colored: !isTransfer,
                        overrideColor: isTransfer
                            ? AppColors.transfer
                            : (isIncome ? AppColors.income : AppColors.expense),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account', style: AppTypography.bodyMedium),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          txn.accountName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (t.type == 'transfer' && txn.toAccountName != null) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To Account', style: AppTypography.bodyMedium),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            txn.toAccountName!,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            if (t.itemizedListJson != null &&
                t.itemizedListJson!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Items', style: AppTypography.labelSmall),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Builder(
                  builder: (context) {
                    try {
                      final items =
                          jsonDecode(t.itemizedListJson!) as List<dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: items.map((e) {
                          final item = e['item'] as String? ?? '';
                          final qty = (e['qty'] as num?)?.toDouble() ?? 1;
                          final price = (e['price'] as num?)?.toDouble() ?? 0;
                          final total = qty * price;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${qty == qty.toInt() ? qty.toInt() : qty} x',
                                    style: AppTypography.bodySmall,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    CurrencyFormatter.format(price),
                                    style: AppTypography.bodySmall,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    CurrencyFormatter.format(total),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    } catch (_) {
                      return Text(
                        'Error loading items',
                        style: AppTypography.bodySmall,
                      );
                    }
                  },
                ),
              ),
            ],

            if (t.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Notes', style: AppTypography.labelSmall),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t.note, style: AppTypography.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
