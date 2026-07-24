import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import 'package:finara/features/accounts/data/accounts_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(accountsDaoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-account'),
          ),
        ],
      ),
      body: StreamBuilder<List<Account>>(
        stream: dao.watchAllAccounts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: 'ðŸ¦',
              title: 'No accounts yet',
              subtitle: 'Add your first account to start tracking',
              action: FilledButton.icon(
                onPressed: () => context.push('/add-account'),
                icon: const Icon(Icons.add),
                label: const Text('Add Account'),
              ),
            );
          }

          final accounts = snapshot.data!;
          final totalBalance = accounts.fold<double>(
            0,
            (sum, a) => sum + a.currentBalance,
          );

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Total balance card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text('Total Balance', style: AppTypography.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalBalance),
                      style: AppTypography.currencyLarge.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Account list
              ...accounts.map((account) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push('/edit-account/${account.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Color(
                                  account.color,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  account.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    account.type.toUpperCase(),
                                    style: AppTypography.labelSmall,
                                  ),
                                  if (account.type == 'creditCard' &&
                                      account.creditLimit != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Limit: ${CurrencyFormatter.format(account.creditLimit!)} \u2022 Due: Day ${account.dueDay ?? '?'}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.accentViolet,
                                      ),
                                    ),
                                  ],
                                  if (account.type == 'loan' &&
                                      account.loanOriginalPrincipal !=
                                          null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Principal: ${CurrencyFormatter.format(account.loanOriginalPrincipal!)} \u2022 ${account.loanInterestRate ?? 0}% /mo',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.accentViolet,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(account.currentBalance),
                              style: AppTypography.currencySmall.copyWith(
                                color: account.currentBalance >= 0
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
