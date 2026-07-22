import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/currency_formatter.dart';

class CreditCardRemindersCard extends ConsumerWidget {
  const CreditCardRemindersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(accountsDaoProvider);
    final now = DateTime.now();

    return StreamBuilder<List<Account>>(
      stream: dao.watchAllAccounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final ccAccounts = snapshot.data!
            .where((a) =>
                a.type == 'creditCard' && a.billGenerationDay != null)
            .toList();

        if (ccAccounts.isEmpty) return const SizedBox.shrink();

        return Column(
          children: ccAccounts.map((account) {
            return StreamBuilder<List<CreditCardBill>>(
              stream: dao.watchBillsForAccount(account.id),
              builder: (context, billSnap) {
                if (!billSnap.hasData) return const SizedBox.shrink();

                final bills = billSnap.data!;
                
                // Determine the billing month we are currently in
                // E.g., if today is 15th and gen is 10th -> billing month is current month
                // if today is 5th and gen is 10th -> billing month is previous month
                DateTime currentBillGenDate = DateTime(now.year, now.month, account.billGenerationDay!, 0, 0);
                if (now.isBefore(currentBillGenDate)) {
                  currentBillGenDate = DateTime(now.year, now.month - 1, account.billGenerationDay!, 0, 0);
                }

                // Check if paid
                final isPaid = bills.any((b) =>
                    b.billingMonth == currentBillGenDate.month &&
                    b.billingYear == currentBillGenDate.year &&
                    b.isPaid);

                if (isPaid) return const SizedBox.shrink();

                // It is unpaid, show the card
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.expense, width: 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.expense),
                          const SizedBox(width: 8),
                          Text(
                            'Action Required',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.expense),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your ${account.name} bill is generated and due on Day ${account.dueDay ?? '?'}.',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Mark as paid
                                await dao.markBillAsPaid(
                                  account.id,
                                  currentBillGenDate.month,
                                  currentBillGenDate.year,
                                );
                                // Cancel notifications for this account
                                await ref.read(notificationServiceProvider).cancelAccountReminders(account.id);
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${account.name} bill marked as paid!')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Mark as Paid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.expense,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
