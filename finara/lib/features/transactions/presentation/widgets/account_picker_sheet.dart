/// Bottom sheet for selecting an account.
library;

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';

class AccountPickerSheet extends StatelessWidget {
  final List<Account> accounts;
  final int? selectedId;
  final int? excludeId; // For transfers â€” exclude source account
  final String title;

  const AccountPickerSheet({
    super.key,
    required this.accounts,
    this.selectedId,
    this.excludeId,
    this.title = 'Select Account',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = excludeId != null
        ? accounts.where((a) => a.id != excludeId).toList()
        : accounts;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title, style: AppTypography.headlineSmall),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final account = filtered[index];
                final isSelected = account.id == selectedId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: isSelected
                        ? AppColors.accentViolet.withValues(alpha: 0.1)
                        : isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () =>
                          Navigator.pop(context, account),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Color(account.color)
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(account.icon,
                                    style: const TextStyle(
                                        fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(account.name,
                                      style: AppTypography.bodyMedium
                                          .copyWith(
                                              fontWeight:
                                                  FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    account.type.toUpperCase(),
                                    style: AppTypography.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.compact(
                                  account.currentBalance),
                              style:
                                  AppTypography.currencySmall.copyWith(
                                color: account.currentBalance >= 0
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle,
                                  color: AppColors.accentViolet,
                                  size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
