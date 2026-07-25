import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import 'package:finara/features/accounts/data/accounts_provider.dart';
import 'package:finara/features/transactions/data/transactions_provider.dart';
import 'package:finara/features/transactions/data/records_time_view_provider.dart';
import 'package:finara/features/settings/data/ui_preferences_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/design_system/widgets/amount_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../transactions/presentation/screens/pending_recoveries_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _isBalanceVisible = false;

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(accountsDaoProvider);
    final txDao = ref.watch(transactionsDaoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final timeState = ref.watch(recordsTimeViewNotifierProvider);
    final (start, end) = timeState.getDateRange();
    final enableSplitSettle = ref.watch(enableSplitAndSettleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('Finara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-account'),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Time View Header (Sticky)
          SliverPersistentHeader(
            pinned: true,
            delegate: _TimeViewHeaderDelegate(
              child: _TimeViewHeader(timeState: timeState, ref: ref),
              isMonthly: timeState.view == RecordsTimeView.monthly,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Summary Header
                  StreamBuilder<double>(
                    stream: dao.watchTotalBalance(),
                    builder: (context, balSnapshot) {
                      final totalBalance = balSnapshot.data ?? 0.0;
                      return StreamBuilder<({double income, double expense})>(
                        stream: txDao.watchTotalsForDateRange(start, end),
                        builder: (context, txSnapshot) {
                          final totals =
                              txSnapshot.data ?? (income: 0.0, expense: 0.0);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanDown: (_) {
                              setState(() {
                                _isBalanceVisible = true;
                              });
                            },
                            onPanEnd: (_) {
                              setState(() {
                                _isBalanceVisible = false;
                              });
                            },
                            onPanCancel: () {
                              setState(() {
                                _isBalanceVisible = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'All Accounts Balance',
                                    style: AppTypography.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isBalanceVisible ? CurrencyFormatter.format(totalBalance) : '****',
                                    style: AppTypography.currencyLarge.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _TotalItem(
                                        label: 'Income',
                                        amount: totals.income,
                                        color: AppColors.income,
                                        isObscured: !_isBalanceVisible,
                                      ),
                                      _TotalItem(
                                        label: 'Expense',
                                        amount: totals.expense,
                                        color: AppColors.expense,
                                        isObscured: !_isBalanceVisible,
                                      ),
                                      _TotalItem(
                                        label: 'Net',
                                        amount: totals.income - totals.expense,
                                        color: (totals.income - totals.expense) >= 0 ? AppColors.income : AppColors.expense,
                                        isObscured: !_isBalanceVisible,
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
                  ),
                  const SizedBox(height: 16),
                  if (enableSplitSettle)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PendingRecoveriesScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentViolet.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accentViolet.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentViolet.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.handshake_outlined, color: AppColors.accentViolet),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pending Recoveries & Debts', style: AppTypography.labelLarge),
                                  Text('Tap to view and settle', style: AppTypography.bodySmall),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.accentViolet),
                          ],
                        ),
                      ),
                    ),
                  if (enableSplitSettle) const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Accounts', style: AppTypography.headlineSmall),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          StreamBuilder<List<Account>>(
            stream: dao.watchAllAccounts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final accounts = snapshot.data ?? [];
              if (accounts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: '🏦',
                    title: 'No accounts yet',
                    subtitle: 'Add your first account to start tracking',
                    action: FilledButton.icon(
                      onPressed: () => context.push('/add-account'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Account'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final account = accounts[index];
                    final isIgnored = account.isIgnored;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push('/account/${account.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Opacity(
                                  opacity: isIgnored ? 0.4 : 1.0,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        account.color,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: isIgnored
                                          ? const Text(
                                              '🚫',
                                              style: TextStyle(fontSize: 22),
                                            )
                                          : account.icon.startsWith('http')
                                          ? (account.icon.endsWith('.svg')
                                              ? SvgPicture.network(
                                                  account.icon,
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
                                                    imageUrl: account.icon,
                                                    width: 24,
                                                    height: 24,
                                                    errorWidget: (c, u, e) => const Text(
                                                      '🏦',
                                                      style: TextStyle(fontSize: 22),
                                                    ),
                                                  ),
                                                ))
                                          : Text(
                                              account.icon,
                                              style: const TextStyle(
                                                fontSize: 22,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Opacity(
                                    opacity: isIgnored ? 0.4 : 1.0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.name,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                decoration: isIgnored
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          account.type.toUpperCase() +
                                              (isIgnored ? ' (IGNORED)' : ''),
                                          style: AppTypography.labelSmall,
                                        ),
                                        if (!isIgnored &&
                                            account.type == 'creditCard' &&
                                            account.creditLimit != null &&
                                            account.creditLimit! > 0) ...[
                                          const SizedBox(height: 4),
                                          Builder(
                                            builder: (context) {
                                              final utilization =
                                                  (account.currentBalance
                                                              .abs() /
                                                          account.creditLimit!)
                                                      .clamp(0.0, 1.0);
                                              final utilColor =
                                                  utilization > 0.7
                                                  ? AppColors.expense
                                                  : utilization > 0.3
                                                  ? Colors.orange
                                                  : AppColors.income;
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Limit: ${CurrencyFormatter.format(account.creditLimit!)} \u2022 Due: Day ${account.dueDay ?? '?'}',
                                                        style: AppTypography
                                                            .labelSmall
                                                            .copyWith(
                                                              color: AppColors
                                                                  .accentViolet,
                                                            ),
                                                      ),
                                                      Text(
                                                        '${(utilization * 100).toStringAsFixed(1)}%',
                                                        style: AppTypography
                                                            .labelSmall
                                                            .copyWith(
                                                              color: utilColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    child: LinearProgressIndicator(
                                                      value: utilization,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .dividerColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                      minHeight: 6,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(utilColor),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                        if (!isIgnored &&
                                            account.type == 'loan' &&
                                            account.loanOriginalPrincipal !=
                                                null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Principal: ${CurrencyFormatter.format(account.loanOriginalPrincipal!)} \u2022 ${account.loanInterestRate ?? 0}% /mo',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                                  color: AppColors.accentViolet,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: isIgnored ? 0.4 : 1.0,
                                  child: Text(
                                    CurrencyFormatter.format(
                                      account.currentBalance,
                                    ),
                                    style: AppTypography.currencySmall.copyWith(
                                      color: account.currentBalance >= 0
                                          ? AppColors.income
                                          : AppColors.expense,
                                    ),
                                  ),
                                ),
                                // 3-dots Menu
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      context.push(
                                        '/edit-account/${account.id}',
                                      );
                                    } else if (value == 'ignore') {
                                      await dao.toggleIgnoreAccount(
                                        account.id,
                                        !isIgnored,
                                      );
                                    } else if (value == 'delete') {
                                      // Show Delete Prompt
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Account'),
                                          content: const Text(
                                            'Do you want to permanently delete this account and all its past records, or just softly delete it (archive)?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                await dao.archiveAccount(
                                                  account.id,
                                                );
                                              },
                                              child: const Text('Soft Delete'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                await dao.hardDeleteAccount(
                                                  account.id,
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.expense,
                                              ),
                                              child: const Text('Hard Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'ignore',
                                      child: Text(
                                        isIgnored ? 'Un-Ignore' : 'Ignore',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: accounts.length),
                ),
              );
            },
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
  final bool isObscured;

  const _TotalItem({
    required this.label, 
    required this.amount, 
    this.color,
    this.isObscured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: 4),
        if (isObscured)
          Text(
            '****',
            style: AppTypography.currencySmall.copyWith(
              color: color,
            ),
          )
        else
          AmountText(
            amount: amount,
            size: AmountSize.small,
            overrideColor: color,
          ),
      ],
    );
  }
}

// Reusable Time View Header

class _TimeViewHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isMonthly;

  _TimeViewHeaderDelegate({required this.child, required this.isMonthly});

  @override
  double get minExtent => isMonthly ? 116.0 : 72.0;

  @override
  double get maxExtent => isMonthly ? 116.0 : 72.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _TimeViewHeaderDelegate oldDelegate) {
    return isMonthly != oldDelegate.isMonthly || true;
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
