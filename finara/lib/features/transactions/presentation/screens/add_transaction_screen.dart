import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/numeric_keypad.dart';
import '../../../../core/design_system/widgets/segmented_control.dart';
import 'package:finara/features/categories/data/categories_provider.dart';
import 'package:finara/features/accounts/data/accounts_provider.dart';
import 'package:finara/features/transactions/data/transactions_provider.dart';
import 'package:finara/features/transactions/data/transactions_dao.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/account_picker_sheet.dart';
import '../widgets/itemized_notes.dart';
import '../../../../core/utils/logger.dart';
import 'package:finara/features/settings/data/ui_preferences_provider.dart';
import '../widgets/transaction_detail_dialog.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final int? editTransactionId;
  final int? duplicateTransactionId;

  const AddTransactionScreen({
    super.key,
    this.editTransactionId,
    this.duplicateTransactionId,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  String _amount = '';
  Account? _selectedAccount;
  Account? _selectedToAccount;
  Category? _selectedCategory;
  DateTime _date = DateTime.now();
  final _noteController = TextEditingController();

  List<Account> _accounts = [];
  List<Category> _categories = [];

  // Itemized mode

  final List<ItemEntry> _itemEntries = [];

  // Split mode
  bool _isSplit = false;
  int _splitPeople = 2;
  bool _splitCustomShare = false;
  bool _isEditingCustomShare = false;
  final _customShareController = TextEditingController();

  // Dynamic fields
  bool _isCreditCardBill = false;
  DateTime _billingMonth = DateTime.now();
  bool _isLoanInterest = false;
  bool _includePrincipalInAnalytics = false;
  bool _isLendBorrow = false;
  int _transferDebtType = 0; // 0 = Lend, 1 = Borrow
  bool _isSettleIncome = true;
  List<Transaction> _pendingRecoveries = [];
  Map<int, double> _settlementAllocations = {};

  bool get _isEditing => widget.editTransactionId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final log = AppLogger.instance;
    log.ui('AddTransactionScreen loaded (isEditing=$_isEditing)');

    final accountsDao = ref.read(accountsDaoProvider);
    final categoriesDao = ref.read(categoriesDaoProvider);

    final accounts = await accountsDao.getAllAccounts();
    final categories = await categoriesDao.getAllCategories();
    final transactionsDao = ref.read(transactionsDaoProvider);
    final pendingRecoveries = await transactionsDao.getPendingRecoveries();

    setState(() {
      _accounts = accounts;
      _categories = categories;
      _pendingRecoveries = pendingRecoveries;
      if (accounts.isNotEmpty) {
        _selectedAccount = accounts.first;
      }
    });

    // Load existing transaction for editing or duplicating
    if (_isEditing || widget.duplicateTransactionId != null) {
      final dao = ref.read(transactionsDaoProvider);
      final idToLoad =
          widget.editTransactionId ?? widget.duplicateTransactionId!;
      final txn = await dao.getTransactionById(idToLoad);
      if (txn != null) {
        setState(() {
          final dbType = TransactionType.values.firstWhere(
            (t) => t.name == txn.type,
            orElse: () => TransactionType.expense,
          );
          if (dbType == TransactionType.creditCardPayment) {
            _type = TransactionType.transfer;
            _isCreditCardBill = true;
          } else if (dbType == TransactionType.loanInterest) {
            _type = TransactionType.transfer;
            _isLoanInterest = true;
          } else if (dbType == TransactionType.loanPrincipalRepayment) {
            _type = TransactionType.transfer;
            _isLoanInterest = false;
            _includePrincipalInAnalytics = !txn.isExcludedFromAnalytics;
          } else {
            _type = dbType;
          }
          _amount = txn.amount.toString();
          // If duplicating, keep today's date
          if (_isEditing) {
            _date = txn.date;
          }
          _noteController.text = txn.note;
          _selectedAccount = accounts
              .where((a) => a.id == txn.accountId)
              .firstOrNull;
          if (txn.toAccountId != null) {
            _selectedToAccount = accounts
                .where((a) => a.id == txn.toAccountId)
                .firstOrNull;
          }
          if (txn.categoryId != null) {
            _selectedCategory = categories
                .where((c) => c.id == txn.categoryId)
                .firstOrNull;
          }
          if (_type == TransactionType.transfer) {
            if (txn.isSplit) {
              _isLendBorrow = true;
              _transferDebtType = 0; // Lending
            } else if (txn.isDebt) {
              _isLendBorrow = true;
              _transferDebtType = 1; // Borrowing
            }
          } else {
            _isLendBorrow = txn.isDebt;
            if (txn.isSplit) {
              _isSplit = true;
              _splitPeople = txn.splitPeople ?? 2;
            }
          }
          if (txn.itemizedListJson != null &&
              txn.itemizedListJson!.isNotEmpty) {
            try {
              final items = jsonDecode(txn.itemizedListJson!) as List<dynamic>;
              for (final e in items) {
                final item = e['item'] as String? ?? '';
                final qty = (e['qty'] as num?)?.toDouble() ?? 1;
                final price = (e['price'] as num?)?.toDouble() ?? 0;
                _itemEntries.add(ItemEntry(item: item, qty: qty, price: price));
              }
            } catch (e) {
              log.error('Failed to parse itemizedListJson: $e');
            }
          }
        });
      }
    }
  }

  double get _effectiveAmount {
    final total = double.tryParse(_amount) ?? 0;
    if (!_isSplit) return total;
    if (_splitCustomShare) {
      return double.tryParse(_customShareController.text) ?? total;
    }
    return _splitPeople > 0 ? total / _splitPeople : total;
  }

  Future<void> _saveTransaction() async {
    final log = AppLogger.instance;
    final userShare = _effectiveAmount;
    final globalAmount = double.tryParse(_amount) ?? 0.0;
    
    if (globalAmount <= 0) {
      log.ui('Save failed: invalid amount');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedAccount == null) {
      log.ui('Save failed: missing account');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an account')));
      return;
    }

    if (_type != TransactionType.transfer && _type != TransactionType.settle && _selectedCategory == null) {
      log.ui('Save failed: missing category');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_type == TransactionType.transfer && _selectedToAccount == null) {
      log.ui('Save failed: missing destination account');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination account')),
      );
      return;
    }

    // Build notes
    String notes = _noteController.text.trim();
    final validItems = _itemEntries
        .where((e) => e.item.trim().isNotEmpty)
        .toList();

    // Check for itemized vs global amount discrepancy
    if (validItems.isNotEmpty) {
      final itemSum = validItems.fold<double>(0, (sum, e) => sum + e.total);
      if ((globalAmount - itemSum).abs() > 0.01) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Amount Mismatch'),
            content: Text(
              'The total amount (\u20B9${globalAmount.toStringAsFixed(2)}) does not match the sum of your itemized list (\u20B9${itemSum.toStringAsFixed(2)}).\n\nPlease check and correct, or proceed to auto-add the discrepancy to the list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Check and Correct'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Proceed as it is'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          return;
        } else {
          // Add discrepancy entry
          final difference = globalAmount - itemSum;
          setState(() {
            _itemEntries.add(ItemEntry(
              item: difference > 0 ? 'Unaccounted amount' : 'Over-accounted amount',
              qty: 1,
              price: difference,
            ));
          });
          // Append to note text to let user know
          notes += '\nUnaccounted amount: \u20B9${difference.toStringAsFixed(2)}';

          
          // Re-evaluate validItems
          validItems.clear();
          validItems.addAll(_itemEntries.where((e) => e.item.trim().isNotEmpty));
        }
      }
    }

    // Itemized info JSON
    String? itemizedInfo;
    if (validItems.isNotEmpty) {
      itemizedInfo = jsonEncode(
        validItems
            .map((e) => {'item': e.item.trim(), 'qty': e.qty, 'price': e.price})
            .toList(),
      );
    }
    final dao = ref.read(transactionsDaoProvider);

    TransactionType finalType = _type;
    bool excludeFromAnalytics = _type.excludedFromAnalytics;

    if (_type == TransactionType.transfer) {
      if (_selectedToAccount?.type == AccountType.creditCard.name &&
          _isCreditCardBill) {
        finalType = TransactionType.creditCardPayment;
        excludeFromAnalytics = finalType.excludedFromAnalytics;
      } else if (_selectedToAccount?.type == AccountType.loan.name) {
        if (_isLoanInterest) {
          finalType = TransactionType.loanInterest;
          excludeFromAnalytics = finalType.excludedFromAnalytics;
        } else {
          finalType = TransactionType.loanPrincipalRepayment;
          excludeFromAnalytics = !_includePrincipalInAnalytics;
        }
      }
    }

    if (_type == TransactionType.settle && _settlementAllocations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one pending record to settle')),
        );
      }
      return;
    }

    final companionTemplate = TransactionsCompanion(
      type: Value(finalType.name),
      accountId: Value(_selectedAccount!.id),
      toAccountId: (_type == TransactionType.transfer)
          ? Value(_selectedToAccount?.id)
          : const Value(null),
      categoryId: (_type != TransactionType.transfer && _type != TransactionType.settle)
          ? Value(_selectedCategory?.id)
          : const Value(null),
      amount: Value(globalAmount),
      date: Value(_date),
      note: Value(notes),
      isExcludedFromAnalytics: Value(excludeFromAnalytics),
      isSplit: Value(_type == TransactionType.transfer && _isLendBorrow ? (_transferDebtType == 0) : _isSplit),
      isDebt: Value(_type == TransactionType.transfer ? (_isLendBorrow && _transferDebtType == 1) : (_type == TransactionType.settle ? !_isSettleIncome : false)),
      splitPeople: Value(_isSplit ? _splitPeople : null),
      userShareAmount: Value(_isSplit ? userShare : null),
      itemizedListJson: Value(itemizedInfo),
    );

    if (_type == TransactionType.settle) {
      for (final entry in _settlementAllocations.entries) {
        final settleCompanion = companionTemplate.copyWith(
          amount: Value(entry.value),
          settlementForTxnId: Value(entry.key),
          // We need to store if this settle transaction is an income or expense so we adjust balance correctly
          // We can use the 'type' field as income/expense to make balances work seamlessly, 
          // or we can use 'settle' and handle it in DAO.
          // DAO logic says: if (type == 'transfer' || type == 'settle') it subtracts... wait.
          // Let's modify DAO later, for now just pass type as settle.
        );
        await dao.insertTransactionWithBalance(settleCompanion);
        
        // Update the original transaction's settledAmount
        final originalTxn = await dao.getTransactionById(entry.key);
        if (originalTxn != null) {
          final newSettledAmount = originalTxn.settledAmount + entry.value;
          final originalAmount = (originalTxn.isSplit && originalTxn.type != 'transfer') ? (originalTxn.amount - (originalTxn.userShareAmount ?? originalTxn.amount)) : originalTxn.amount;
          final isFullySettled = newSettledAmount >= originalAmount;
          await dao.updateTransaction(
            entry.key, 
            TransactionsCompanion(
              settledAmount: Value(newSettledAmount),
              isFullySettled: Value(isFullySettled),
            ),
          );
        }
      }
      log.ui('Saved settlement transactions');
    } else {
      if (_isEditing) {
        await dao.updateTransaction(widget.editTransactionId!, companionTemplate);
        log.ui('Saved edits to transaction id=${widget.editTransactionId}');
      } else {
        await dao.insertTransactionWithBalance(companionTemplate);
        log.ui('Saved new transaction');
      }
    }

    // Mark credit card bill as paid
    if (finalType == TransactionType.creditCardPayment &&
        _selectedToAccount != null) {
      try {
        final accountsDao = ref.read(accountsDaoProvider);
        await accountsDao.markBillAsPaid(
          _selectedToAccount!.id,
          _billingMonth.month,
          _billingMonth.year,
        );
        log.ui(
          'Marked credit card bill as paid for ${_date.month}/${_date.year}',
        );
      } catch (e) {
        log.error('Failed to mark bill as paid', e);
      }
    }

    if (mounted) {
      context.pop();
    }
  }

  void _openCategoryPicker() async {
    final result = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryPickerSheet(
        categories: _categories,
        selectedId: _selectedCategory?.id,
        transactionType: _type == TransactionType.income ? 'income' : 'expense',
      ),
    );
    if (result != null) {
      setState(() => _selectedCategory = result);
    }
  }

  void _openAccountPicker({bool isTo = false}) async {
    final result = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountPickerSheet(
        accounts: _accounts,
        selectedId: isTo ? _selectedToAccount?.id : _selectedAccount?.id,
        excludeId: isTo ? _selectedAccount?.id : null,
        title: isTo ? 'Transfer To' : 'From Account',
      ),
    );
    if (result != null) {
      setState(() {
        if (isTo) {
          _selectedToAccount = result;
        } else {
          _selectedAccount = result;
        }
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customShareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSideBySide = ref.watch(sideBySideTransactionUINotifierProvider);
    final enableSplitSettle = ref.watch(enableSplitAndSettleNotifierProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
              onPressed: _confirmDelete,
            ),
          TextButton(
            onPressed: _saveTransaction,
            child: Text(
              'Save',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.accentViolet,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable top section
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction type selector
                  Center(
                    child: SegmentedControl<TransactionType>(
                      segments: [
                        TransactionType.income,
                        TransactionType.expense,
                        TransactionType.transfer,
                        if (enableSplitSettle) TransactionType.settle,
                      ],
                      selected: _type,
                      labelBuilder: (t) => t.displayName.toUpperCase(),
                      colorBuilder: (t) => switch (t) {
                        TransactionType.income => AppColors.income,
                        TransactionType.expense => AppColors.expense,
                        TransactionType.transfer => AppColors.transfer,
                        TransactionType.settle => AppColors.accentViolet,
                        _ => AppColors.transfer,
                      },
                      onChanged: (t) => setState(() {
                        _type = t;
                        _selectedCategory = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount display
                  GestureDetector(
                    onTap: () => setState(() => _isEditingCustomShare = false),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _amount.isEmpty ? '\u20B90' : '\u20B9$_amount',
                            style: AppTypography.currencyLarge.copyWith(
                              fontSize: 40,
                              color: switch (_type) {
                                TransactionType.income => AppColors.income,
                                TransactionType.expense => AppColors.expense,
                                TransactionType.transfer => AppColors.transfer,
                                TransactionType.creditCardPayment =>
                                  AppColors.transfer,
                                TransactionType.loanPrincipalRepayment =>
                                  AppColors.transfer,
                                TransactionType.loanInterest =>
                                  AppColors.expense,
                                TransactionType.settle => AppColors.accentViolet,
                              },
                            ),
                          ),
                          if (_isSplit) ...[
                            const SizedBox(height: 4),
                            Text(
                              'My share: \u20B9${_effectiveAmount.toStringAsFixed(2)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.accentViolet,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isSideBySide) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _PickerTile(
                            label: 'Account',
                            icon: _selectedAccount?.icon ?? '💳',
                            value: _selectedAccount?.name ?? 'Select account',
                            onTap: () => _openAccountPicker(),
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_type == TransactionType.transfer)
                          Expanded(
                            child: _PickerTile(
                              label: 'To Account',
                              icon: _selectedToAccount?.icon ?? '💳',
                              value:
                                  _selectedToAccount?.name ??
                                  'Select destination',
                              onTap: () => _openAccountPicker(isTo: true),
                              isCompact: true,
                            ),
                          )
                        else if (_type != TransactionType.settle)
                          Expanded(
                            child: _PickerTile(
                              label: 'Category',
                              icon: _selectedCategory?.icon ?? '📌',
                              value:
                                  _selectedCategory?.name ?? 'Select category',
                              onTap: _openCategoryPicker,
                              isCompact: true,
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    // Account selector tile
                    _PickerTile(
                      label: 'Account',
                      icon: _selectedAccount?.icon ?? '💳',
                      value: _selectedAccount?.name ?? 'Select account',
                      onTap: () => _openAccountPicker(),
                    ),

                    if (_type == TransactionType.transfer) ...[
                      const SizedBox(height: 8),
                      _PickerTile(
                        label: 'To Account',
                        icon: _selectedToAccount?.icon ?? '💳',
                        value: _selectedToAccount?.name ?? 'Select destination',
                        onTap: () => _openAccountPicker(isTo: true),
                      ),
                    ],

                    if (_type != TransactionType.transfer &&
                        _type != TransactionType.settle) ...[
                      const SizedBox(height: 8),
                      _PickerTile(
                        label: 'Category',
                        icon: _selectedCategory?.icon ?? '📌',
                        value: _selectedCategory?.name ?? 'Select category',
                        onTap: _openCategoryPicker,
                      ),
                    ],
                  ],

                  // Dynamic toggles for transfers
                  if (_type == TransactionType.transfer) ...[
                    if (_selectedToAccount?.type ==
                        AccountType.creditCard.name) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text(
                                  'Credit card bill payment?',
                                  style: AppTypography.bodyMedium,
                                ),
                                value: _isCreditCardBill,
                                onChanged: (v) => setState(
                                  () => _isCreditCardBill = v ?? false,
                                ),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: AppColors.accentViolet,
                              ),
                            ),
                            if (_isCreditCardBill)
                              GestureDetector(
                                onTap: () async {
                                  final date = await _showMonthYearPicker(
                                    context,
                                    _billingMonth,
                                  );
                                  if (date != null) {
                                    setState(() => _billingMonth = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentViolet.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.accentViolet.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                        size: 16,
                                        color: AppColors.accentViolet,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat(
                                          'MMM yyyy',
                                        ).format(_billingMonth),
                                        style: AppTypography.labelMedium
                                            .copyWith(
                                              color: AppColors.accentViolet,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (enableSplitSettle) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CheckboxListTile(
                                title: Text(
                                  'Record this as a debt/loan?',
                                  style: AppTypography.bodyMedium,
                                ),
                                value: _isLendBorrow,
                                onChanged: (v) => setState(
                                  () => _isLendBorrow = v ?? false,
                                ),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: AppColors.accentViolet,
                              ),
                              if (_isLendBorrow)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                  child: SegmentedControl<int>(
                                    segments: const [0, 1],
                                    selected: _transferDebtType,
                                    labelBuilder: (v) => v == 0 ? 'I am Lending' : 'I am Borrowing',
                                    onChanged: (index) {
                                      setState(() {
                                        _transferDebtType = index;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                      ),
                    ],

                    if (_selectedToAccount?.type == AccountType.loan.name) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Type',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: SegmentedControl<bool>(
                                segments: const [false, true],
                                selected: _isLoanInterest,
                                labelBuilder: (isInterest) =>
                                    isInterest ? 'Interest' : 'Principal',
                                onChanged: (v) =>
                                    setState(() => _isLoanInterest = v),
                              ),
                            ),
                            if (!_isLoanInterest) ...[
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                title: Text(
                                  'Include as Expense (Analytics)',
                                  style: AppTypography.bodyMedium,
                                ),
                                subtitle: Text(
                                  'Check if paying someone else\'s loan',
                                  style: AppTypography.bodySmall,
                                ),
                                value: _includePrincipalInAnalytics,
                                onChanged: (v) => setState(
                                  () =>
                                      _includePrincipalInAnalytics = v ?? false,
                                ),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: AppColors.accentViolet,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                  if (_type == TransactionType.settle) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: SegmentedControl<bool>(
                        segments: const [true, false],
                        selected: _isSettleIncome,
                        labelBuilder: (isIncome) =>
                            isIncome ? 'Recover' : 'Pay Back',
                        colorBuilder: (isIncome) =>
                            isIncome ? AppColors.income : AppColors.expense,
                        onChanged: (v) => setState(() {
                          _isSettleIncome = v;
                          _settlementAllocations.clear();
                          _amount = '';
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Pending Records', style: AppTypography.labelLarge),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final filteredRecoveries = _pendingRecoveries.where((txn) {
                          if (_isSettleIncome) {
                            return txn.isSplit;
                          } else {
                            return txn.isDebt;
                          }
                        }).toList();

                        if (filteredRecoveries.isEmpty) {
                          return const Text('No pending records found.');
                        }

                        return Column(
                          children: filteredRecoveries.map((txn) {
                            final original = (txn.isSplit && txn.type != 'transfer') 
                                ? (txn.amount - (txn.userShareAmount ?? txn.amount)) 
                                : txn.amount;
                            final remaining = original - txn.settledAmount;
                            final isSelected = _settlementAllocations.containsKey(txn.id);

                            final category = _categories.firstWhere(
                              (c) => c.id == txn.categoryId,
                              orElse: () => Category(id: -1, name: 'Unknown', type: '', icon: '📌', color: 0, isSystem: true, sortOrder: 0),
                            );
                            final account = _accounts.firstWhere(
                              (a) => a.id == txn.accountId,
                              orElse: () => Account(id: -1, name: 'Unknown', type: '', icon: '💰', color: 0, initialBalance: 0, currentBalance: 0, currency: '', archived: false, isIgnored: false, sortOrder: 0, createdAt: DateTime.now()),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (selected) {
                                      setState(() {
                                        if (selected == true) {
                                          _settlementAllocations[txn.id] = remaining;
                                        } else {
                                          _settlementAllocations.remove(txn.id);
                                        }
                                        if (_settlementAllocations.isNotEmpty) {
                                          _amount = _settlementAllocations.values
                                              .fold(0.0, (a, b) => a + b)
                                              .toStringAsFixed(2);
                                        } else {
                                          _amount = '';
                                        }
                                      });
                                    },
                                    activeColor: AppColors.accentViolet,
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => TransactionDetailDialog(
                                            txn: TransactionWithDetails(
                                              transaction: txn,
                                              accountName: account.name,
                                              categoryName: category.name,
                                              categoryIcon: category.icon,
                                              categoryColor: category.color,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(txn.note.isNotEmpty ? txn.note : (txn.isSplit ? (txn.type == 'transfer' ? 'Lent' : 'Split Payment') : 'Borrowed'), style: AppTypography.bodyMedium),
                                          Text('${category.icon} ${category.name} • ${account.name}', style: AppTypography.bodySmall),
                                          Text('Remaining: \u20B9${remaining.toStringAsFixed(2)}', style: AppTypography.bodySmall.copyWith(color: AppColors.expense)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    SizedBox(
                                      width: 80,
                                      child: _SettlementAmountInput(
                                        initialValue: _settlementAllocations[txn.id] ?? 0.0,
                                        onChanged: (newAmt) {
                                          setState(() {
                                            _settlementAllocations[txn.id] = newAmt;
                                            _amount = _settlementAllocations.values
                                                .fold(0.0, (a, b) => a + b)
                                                .toStringAsFixed(2);
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Notes section
                  Text('Notes', style: AppTypography.labelLarge),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: 12),
                  if (_type != TransactionType.settle) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Itemized List', style: AppTypography.labelLarge),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _itemEntries.add(ItemEntry());
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Item'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    if (_itemEntries.isNotEmpty)
                      ItemizedNotes(
                        items: _itemEntries,
                        onTotalChanged: (total) {
                          setState(() {
                            _amount = total.toStringAsFixed(2);
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                  ],

                  // Split payment toggle
                  if (_type != TransactionType.settle && enableSplitSettle)
                    _SplitPaymentSection(
                      isSplit: _isSplit,
                      onSplitChanged: (v) => setState(() => _isSplit = v),
                      people: _splitPeople,
                      onPeopleChanged: (v) => setState(() => _splitPeople = v),
                      isCustomShare: _splitCustomShare,
                      onCustomChanged: (v) =>
                          setState(() => _splitCustomShare = v),
                      customShareController: _customShareController,
                      totalAmount: double.tryParse(_amount) ?? 0,
                      isEditingCustomShare: _isEditingCustomShare,
                      onCustomShareTap: () =>
                          setState(() => _isEditingCustomShare = true),
                    ),
                ],
              ),
            ),
          ),

          // Fixed bottom: Keypad → Date/Time
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Numeric keypad
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: NumericKeypad(
                      value: _isEditingCustomShare
                          ? _customShareController.text
                          : _amount,
                      onValueChanged: (v) {
                        setState(() {
                          if (_isEditingCustomShare) {
                            _customShareController.text = v;
                          } else {
                            _amount = v;
                            if (_type == TransactionType.settle && _settlementAllocations.isNotEmpty) {
                              final totalAmt = double.tryParse(v) ?? 0.0;
                              if (totalAmt >= 0) {
                                double totalRemaining = 0;
                                final List<MapEntry<int, double>> eligible = [];
                                for (final txn in _pendingRecoveries) {
                                  if (_settlementAllocations.containsKey(txn.id)) {
                                    final original = (txn.isSplit && txn.type != 'transfer') 
                                        ? (txn.amount - (txn.userShareAmount ?? txn.amount)) 
                                        : txn.amount;
                                    final remaining = original - txn.settledAmount;
                                    totalRemaining += remaining;
                                    eligible.add(MapEntry(txn.id, remaining));
                                  }
                                }
                                
                                if (totalRemaining > 0) {
                                  double remainingToDistribute = totalAmt;
                                  for (int i = 0; i < eligible.length; i++) {
                                    if (i == eligible.length - 1) {
                                      _settlementAllocations[eligible[i].key] = remainingToDistribute;
                                    } else {
                                      final share = (totalAmt * (eligible[i].value / totalRemaining)).floorToDouble();
                                      _settlementAllocations[eligible[i].key] = share;
                                      remainingToDistribute -= share;
                                    }
                                  }
                                } else {
                                  _settlementAllocations.updateAll((key, value) => 0.0);
                                }
                              }
                            }
                          }
                        });
                      },
                    ),
                  ),
                  // Date/Time row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DateTimeChip(
                            icon: Icons.calendar_today,
                            label: DateFormatter.relative(_date),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 1),
                                ),
                              );
                              if (date != null) {
                                setState(
                                  () => _date = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    _date.hour,
                                    _date.minute,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DateTimeChip(
                            icon: Icons.access_time,
                            label: DateFormatter.time(_date),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_date),
                              );
                              if (time != null) {
                                setState(
                                  () => _date = DateTime(
                                    _date.year,
                                    _date.month,
                                    _date.day,
                                    time.hour,
                                    time.minute,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final dao = ref.read(transactionsDaoProvider);
      await dao.deleteTransaction(widget.editTransactionId!);
      if (mounted) context.pop();
    }
  }
}

/// Tile widget that opens a bottom sheet picker.
class _PickerTile extends StatelessWidget {
  final String label;
  final String icon;
  final String value;
  final VoidCallback onTap;
  final bool isCompact;

  const _PickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: isCompact
            ? Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 10 : 14,
            ),
            child: Row(
              children: [
                icon.startsWith('http')
                    ? (icon.endsWith('.svg')
                        ? SvgPicture.network(
                            icon,
                            width: isCompact ? 24 : 20,
                            height: isCompact ? 24 : 20,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).iconTheme.color ?? Colors.black,
                              BlendMode.srcIn,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: icon,
                              width: isCompact ? 24 : 20,
                              height: isCompact ? 24 : 20,
                              errorWidget: (c, u, e) => Text(
                                '💳',
                                style: TextStyle(fontSize: isCompact ? 24 : 20),
                              ),
                            ),
                          ))
                    : Text(icon, style: TextStyle(fontSize: isCompact ? 24 : 20)),
                SizedBox(width: isCompact ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTypography.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isCompact) const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Date/time chip for the bottom row.
class _DateTimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.accentViolet),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Split payment section.
class _SplitPaymentSection extends StatelessWidget {
  final bool isSplit;
  final ValueChanged<bool> onSplitChanged;
  final int people;
  final ValueChanged<int> onPeopleChanged;
  final bool isCustomShare;
  final ValueChanged<bool> onCustomChanged;
  final TextEditingController customShareController;
  final double totalAmount;
  final bool isEditingCustomShare;
  final VoidCallback onCustomShareTap;

  const _SplitPaymentSection({
    required this.isSplit,
    required this.onSplitChanged,
    required this.people,
    required this.onPeopleChanged,
    required this.isCustomShare,
    required this.onCustomChanged,
    required this.customShareController,
    required this.totalAmount,
    required this.isEditingCustomShare,
    required this.onCustomShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.group_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('Split Payment', style: AppTypography.bodyMedium),
                ],
              ),
              Switch.adaptive(
                value: isSplit,
                onChanged: onSplitChanged,
                activeTrackColor: AppColors.accentViolet,
              ),
            ],
          ),
          if (isSplit) ...[
            const SizedBox(height: 8),
            // Toggle: Equal split vs Custom
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Equal Split'),
                    selected: !isCustomShare,
                    onSelected: (_) => onCustomChanged(false),
                    selectedColor: AppColors.accentViolet.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Custom Share'),
                    selected: isCustomShare,
                    onSelected: (_) => onCustomChanged(true),
                    selectedColor: AppColors.accentViolet.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!isCustomShare)
              // Equal split: people counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: people > 2
                        ? () => onPeopleChanged(people - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentViolet.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$people people',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onPeopleChanged(people + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              )
            else
              // Custom share input
              GestureDetector(
                onTap: onCustomShareTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEditingCustomShare
                          ? AppColors.accentViolet
                          : Theme.of(context).dividerColor,
                      width: isEditingCustomShare ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My share amount', style: AppTypography.labelSmall),
                      const SizedBox(height: 4),
                      Text('\u20B9 ', style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),
            // Summary
            if (totalAmount > 0)
              Text(
                isCustomShare
                    ? 'Total: \u20B9${totalAmount.toStringAsFixed(2)}'
                    : 'Total: \u20B9${totalAmount.toStringAsFixed(2)} ÷ $people = \u20B9${(totalAmount / people).toStringAsFixed(2)} each',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accentViolet,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

Future<DateTime?> _showMonthYearPicker(
  BuildContext context,
  DateTime initialDate,
) async {
  DateTime selected = initialDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  Text('Select Month', style: AppTypography.headlineSmall),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 130, // Reduced height to show fewer items (3-4 items)
              child: Transform.scale(
                scale: 1.15, // Zoom in slightly
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.monthYear,
                  initialDateTime: initialDate,
                  onDateTimeChanged: (DateTime newDate) {
                    selected = newDate;
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SettlementAmountInput extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;

  const _SettlementAmountInput({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_SettlementAmountInput> createState() => _SettlementAmountInputState();
}

class _SettlementAmountInputState extends State<_SettlementAmountInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue > 0 ? widget.initialValue.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(covariant _SettlementAmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      final currentText = _controller.text;
      final newValStr = widget.initialValue > 0 ? widget.initialValue.toStringAsFixed(2) : '';
      if (currentText != newValStr) {
        _controller.value = TextEditingValue(
          text: newValStr,
          selection: TextSelection.collapsed(offset: newValStr.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      style: AppTypography.bodyMedium,
      decoration: const InputDecoration(
        prefixText: '\u20B9',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onChanged: (val) {
        final newAmt = double.tryParse(val) ?? 0.0;
        widget.onChanged(newAmt);
      },
    );
  }
}
