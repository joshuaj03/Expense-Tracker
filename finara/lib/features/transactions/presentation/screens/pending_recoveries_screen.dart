import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/database/enums.dart';
import '../../data/transactions_dao.dart';
import '../../data/transactions_provider.dart';
import 'package:finara/features/categories/data/categories_provider.dart';
import 'package:finara/features/accounts/data/accounts_provider.dart';
import '../widgets/transaction_detail_dialog.dart';

class PendingRecoveriesScreen extends ConsumerStatefulWidget {
  const PendingRecoveriesScreen({super.key});

  @override
  ConsumerState<PendingRecoveriesScreen> createState() => _PendingRecoveriesScreenState();
}

class _PendingRecoveriesScreenState extends ConsumerState<PendingRecoveriesScreen> {
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accountsDao = ref.read(accountsDaoProvider);
    final categoriesDao = ref.read(categoriesDaoProvider);
    final accounts = await accountsDao.getAllAccounts();
    final categories = await categoriesDao.getAllCategories();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingRecoveriesAsync = ref.watch(pendingRecoveriesProvider);
    final settledRecoveriesAsync = ref.watch(settledRecoveriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Recoveries'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : pendingRecoveriesAsync.when(
            data: (pendingTransactions) {
              return settledRecoveriesAsync.when(
                data: (settledTransactions) {
                  if (pendingTransactions.isEmpty && settledTransactions.isEmpty) {
                    return Center(
                      child: Text(
                        'No pending recoveries or debts!',
                        style: AppTypography.bodyLarge,
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...pendingTransactions.map((txn) => _buildTransactionCard(txn, isDark)),
                      if (settledTransactions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text('History', style: AppTypography.headlineSmall),
                            children: settledTransactions.map((txn) => _buildTransactionCard(txn, isDark)).toList(),
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
    );
  }

  Widget _buildTransactionCard(Transaction txn, bool isDark) {
    final sourceAccount = _accounts.firstWhere((a) => a.id == txn.accountId, orElse: () => _accounts.first);
    final category = _categories.firstWhere((c) => c.id == txn.categoryId, orElse: () => _categories.first);

    bool isIncome = true;
    if (txn.isSplit) {
      isIncome = true; // Lending
    } else if (txn.isDebt) {
      if (txn.type == 'expense') isIncome = true;
      else if (txn.type == 'income') isIncome = false;
      else if (txn.type == 'transfer') isIncome = false; // Borrowing
    }

    final original = (txn.isSplit && txn.type != 'transfer') 
        ? (txn.amount - (txn.userShareAmount ?? txn.amount)) 
        : txn.amount;
    final remaining = original - txn.settledAmount;
    final progress = original > 0 ? (txn.settledAmount / original) : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showDialog(
          context: context,
          builder: (_) {
            return TransactionDetailDialog(
              txn: TransactionWithDetails(
                transaction: txn,
                accountName: sourceAccount.name,
                categoryName: category.name,
                categoryIcon: category.icon,
                categoryColor: category.color,
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isIncome
                ? AppColors.income.withValues(alpha: 0.3)
                : AppColors.expense.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.note.isNotEmpty ? txn.note : (txn.isSplit ? (txn.type == 'transfer' ? 'Lent' : 'Split Payment') : 'Borrowed'),
                        style: AppTypography.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${category.icon} ${category.name} • ${sourceAccount.name}',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? AppColors.income.withValues(alpha: 0.1)
                        : AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isIncome ? 'TO RECOVER' : 'TO PAY BACK',
                    style: AppTypography.labelSmall.copyWith(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountColumn('Original', original),
                _buildAmountColumn('Settled', txn.settledAmount),
                _buildAmountColumn('Remaining', remaining, isHighlighted: true),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '\u20B9${amount.toStringAsFixed(2)}',
          style: isHighlighted
              ? AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)
              : AppTypography.bodyMedium,
        ),
      ],
    );
  }
}
