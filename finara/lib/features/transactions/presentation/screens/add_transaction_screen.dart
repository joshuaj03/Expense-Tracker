import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/numeric_keypad.dart';
import '../../../../core/design_system/widgets/segmented_control.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/account_picker_sheet.dart';
import '../widgets/itemized_notes.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final int? editTransactionId;

  const AddTransactionScreen({super.key, this.editTransactionId});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
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
  bool _isItemized = false;
  final List<ItemEntry> _itemEntries = [];

  // Split mode
  bool _isSplit = false;
  int _splitPeople = 2;
  bool _splitCustomShare = false;
  final _customShareController = TextEditingController();

  bool get _isEditing => widget.editTransactionId != null;

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

    setState(() {
      _accounts = accounts;
      _categories = categories;
      if (accounts.isNotEmpty) {
        _selectedAccount = accounts.first;
      }
    });

    // Load existing transaction for editing
    if (_isEditing) {
      final dao = ref.read(transactionsDaoProvider);
      final txn = await dao.getTransactionById(widget.editTransactionId!);
      if (txn != null) {
        setState(() {
          _type = TransactionType.values.firstWhere(
              (t) => t.name == txn.type,
              orElse: () => TransactionType.expense);
          _amount = txn.amount.toString();
          _date = txn.date;
          _noteController.text = txn.note;
          _selectedAccount =
              accounts.where((a) => a.id == txn.accountId).firstOrNull;
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
    final amount = _effectiveAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    if (_type != TransactionType.transfer && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_type == TransactionType.transfer && _selectedToAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination account')),
      );
      return;
    }

    // Build notes
    String notes = _noteController.text.trim();
    if (_isItemized && _itemEntries.isNotEmpty) {
      notes = itemizedToText(_itemEntries);
    }

    // Split info JSON
    String splitInfo = '';
    if (_isSplit) {
      splitInfo = jsonEncode({
        'totalAmount': double.tryParse(_amount) ?? 0,
        'people': _splitPeople,
        'myShare': _effectiveAmount,
        'isCustom': _splitCustomShare,
      });
    }

    final dao = ref.read(transactionsDaoProvider);

    final companion = TransactionsCompanion(
      type: Value(_type.name),
      accountId: Value(_selectedAccount!.id),
      toAccountId: _type == TransactionType.transfer
          ? Value(_selectedToAccount?.id)
          : const Value(null),
      categoryId: _type != TransactionType.transfer
          ? Value(_selectedCategory?.id)
          : const Value(null),
      amount: Value(amount),
      date: Value(_date),
      note: Value(notes),
      isExcludedFromAnalytics: Value(_type.excludedFromAnalytics),
    );

    if (_isEditing) {
      await dao.updateTransaction(
        widget.editTransactionId!,
        companion,
      );
    } else {
      await dao.insertTransaction(companion);
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
        transactionType:
            _type == TransactionType.income ? 'income' : 'expense',
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.expense),
              onPressed: _confirmDelete,
            ),
          TextButton(
            onPressed: _saveTransaction,
            child: Text('Save',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.accentViolet)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable top section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction type selector
                  SegmentedControl<TransactionType>(
                    segments: TransactionType.values,
                    selected: _type,
                    labelBuilder: (t) => t.displayName,
                    colorBuilder: (t) => switch (t) {
                      TransactionType.income => AppColors.income,
                      TransactionType.expense => AppColors.expense,
                      TransactionType.transfer => AppColors.transfer,
                    },
                    onChanged: (t) => setState(() {
                      _type = t;
                      _selectedCategory = null;
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Amount display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _amount.isEmpty ? '₹0' : '₹$_amount',
                          style: AppTypography.currencyLarge.copyWith(
                            fontSize: 40,
                            color: switch (_type) {
                              TransactionType.income => AppColors.income,
                              TransactionType.expense => AppColors.expense,
                              TransactionType.transfer =>
                                AppColors.transfer,
                            },
                          ),
                        ),
                        if (_isSplit) ...[
                          const SizedBox(height: 4),
                          Text(
                            'My share: ₹${_effectiveAmount.toStringAsFixed(2)}',
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.accentViolet),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account selector tile
                  _PickerTile(
                    label: 'Account',
                    icon: _selectedAccount?.icon ?? '🏦',
                    value: _selectedAccount?.name ?? 'Select account',
                    onTap: () => _openAccountPicker(),
                  ),

                  // To Account (transfers)
                  if (_type == TransactionType.transfer) ...[
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: 'To Account',
                      icon: _selectedToAccount?.icon ?? '🏦',
                      value:
                          _selectedToAccount?.name ?? 'Select destination',
                      onTap: () => _openAccountPicker(isTo: true),
                    ),
                  ],

                  // Category selector (not for transfers)
                  if (_type != TransactionType.transfer) ...[
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: 'Category',
                      icon: _selectedCategory?.icon ?? '📌',
                      value: _selectedCategory?.name ?? 'Select category',
                      onTap: _openCategoryPicker,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Notes section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notes', style: AppTypography.labelLarge),
                      Row(
                        children: [
                          // Itemized toggle
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isItemized = !_isItemized;
                                if (_isItemized &&
                                    _itemEntries.isEmpty) {
                                  _itemEntries.add(ItemEntry());
                                }
                              });
                            },
                            icon: Icon(
                              _isItemized
                                  ? Icons.notes
                                  : Icons.list_alt,
                              size: 16,
                            ),
                            label: Text(
                                _isItemized ? 'Text' : 'Itemize'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_isItemized)
                    ItemizedNotes(
                      items: _itemEntries,
                      onTotalChanged: (total) {
                        setState(() {
                          _amount = total.toStringAsFixed(2);
                        });
                      },
                    )
                  else
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'Add a note...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      minLines: 3,
                    ),
                  const SizedBox(height: 12),

                  // Split payment toggle
                  _SplitPaymentSection(
                    isSplit: _isSplit,
                    onSplitChanged: (v) => setState(() => _isSplit = v),
                    people: _splitPeople,
                    onPeopleChanged: (v) =>
                        setState(() => _splitPeople = v),
                    isCustomShare: _splitCustomShare,
                    onCustomChanged: (v) =>
                        setState(() => _splitCustomShare = v),
                    customShareController: _customShareController,
                    totalAmount: double.tryParse(_amount) ?? 0,
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
                      value: _amount,
                      onValueChanged: (v) =>
                          setState(() => _amount = v),
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
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 1)),
                              );
                              if (date != null) {
                                setState(() => _date = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    _date.hour,
                                    _date.minute));
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
                                initialTime:
                                    TimeOfDay.fromDateTime(_date),
                              );
                              if (time != null) {
                                setState(() => _date = DateTime(
                                    _date.year,
                                    _date.month,
                                    _date.day,
                                    time.hour,
                                    time.minute));
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
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.expense))),
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

  const _PickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.labelSmall),
                    const SizedBox(height: 2),
                    Text(value,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  const _SplitPaymentSection({
    required this.isSplit,
    required this.onSplitChanged,
    required this.people,
    required this.onPeopleChanged,
    required this.isCustomShare,
    required this.onCustomChanged,
    required this.customShareController,
    required this.totalAmount,
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
                  Text('Split Payment',
                      style: AppTypography.bodyMedium),
                ],
              ),
              Switch.adaptive(
                value: isSplit,
                onChanged: onSplitChanged,
                activeColor: AppColors.accentViolet,
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
                    selectedColor:
                        AppColors.accentViolet.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Custom Share'),
                    selected: isCustomShare,
                    onSelected: (_) => onCustomChanged(true),
                    selectedColor:
                        AppColors.accentViolet.withValues(alpha: 0.2),
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
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          AppColors.accentViolet.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$people people',
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    onPressed: () => onPeopleChanged(people + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              )
            else
              // Custom share input
              TextField(
                controller: customShareController,
                decoration: const InputDecoration(
                  labelText: 'My share amount',
                  prefixText: '₹ ',
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
              ),

            const SizedBox(height: 8),
            // Summary
            if (totalAmount > 0)
              Text(
                isCustomShare
                    ? 'Total: ₹${totalAmount.toStringAsFixed(2)}'
                    : 'Total: ₹${totalAmount.toStringAsFixed(2)} ÷ $people = ₹${(totalAmount / people).toStringAsFixed(2)} each',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.accentViolet),
              ),
          ],
        ],
      ),
    );
  }
}
