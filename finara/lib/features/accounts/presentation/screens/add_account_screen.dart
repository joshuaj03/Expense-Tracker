import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import 'package:finara/core/services/notification_service.dart';
import 'package:finara/features/accounts/data/accounts_provider.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  final int? editAccountId;

  const AddAccountScreen({super.key, this.editAccountId});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  AccountType _accountType = AccountType.bank;
  int _selectedColor = AppColors.categoryPalette[0].toARGB32();
  bool _isEditing = false;

  final _creditLimitController = TextEditingController();
  final _billGenerationDayController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _loanPrincipalController = TextEditingController();
  final _loanInterestRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editAccountId != null) {
      _isEditing = true;
      _loadAccount();
    }
  }

  Future<void> _loadAccount() async {
    final dao = ref.read(accountsDaoProvider);
    final account = await dao.getAccountById(widget.editAccountId!);
    if (account != null) {
      setState(() {
        _nameController.text = account.name;
        _balanceController.text = account.currentBalance.toString();
        _accountType = AccountType.values.firstWhere(
          (t) => t.name == account.type,
          orElse: () => AccountType.bank,
        );
        _selectedColor = account.color;

        _creditLimitController.text = account.creditLimit?.toString() ?? '';
        _billGenerationDayController.text =
            account.billGenerationDay?.toString() ?? '';
        _dueDayController.text = account.dueDay?.toString() ?? '';
        _loanPrincipalController.text =
            account.loanOriginalPrincipal?.toString() ?? '';
        _loanInterestRateController.text =
            account.loanInterestRate?.toString() ?? '';
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an account name')),
      );
      return;
    }

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0;

    final dao = ref.read(accountsDaoProvider);

    final companion = AccountsCompanion(
      name: Value(name),
      type: Value(_accountType.name),
      icon: Value(_accountType.icon),
      color: Value(_selectedColor),
      creditLimit: _accountType == AccountType.creditCard
          ? Value(double.tryParse(_creditLimitController.text))
          : const Value(null),
      billGenerationDay: _accountType == AccountType.creditCard
          ? Value(int.tryParse(_billGenerationDayController.text))
          : const Value(null),
      dueDay: _accountType == AccountType.creditCard
          ? Value(int.tryParse(_dueDayController.text))
          : const Value(null),
      loanOriginalPrincipal: _accountType == AccountType.loan
          ? Value(double.tryParse(_loanPrincipalController.text))
          : const Value(null),
      loanInterestRate: _accountType == AccountType.loan
          ? Value(double.tryParse(_loanInterestRateController.text))
          : const Value(null),
    );

    int accountId;
    if (widget.editAccountId != null) {
      await dao.updateAccount(
        companion.copyWith(id: Value(widget.editAccountId!)),
      );
      accountId = widget.editAccountId!;
    } else {
      accountId = await dao.insertAccount(
        companion.copyWith(
          initialBalance: Value(balance),
          currentBalance: Value(balance),
        ),
      );
    }

    if (_accountType == AccountType.creditCard) {
      final billGen = int.tryParse(_billGenerationDayController.text) ?? 1;
      final due = int.tryParse(_dueDayController.text) ?? 20;
      await ref
          .read(notificationServiceProvider)
          .scheduleCreditCardReminders(
            accountId: accountId,
            accountName: name,
            billGenerationDay: billGen,
            dueDay: due,
            currentDate: DateTime.now(),
          );
    }

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    final dao = ref.read(accountsDaoProvider);
    await dao.deleteAccount(widget.editAccountId!);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _billGenerationDayController.dispose();
    _dueDayController.dispose();
    _loanPrincipalController.dispose();
    _loanInterestRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Account' : 'Add Account'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text(
                      'This will remove the account. Transactions will not be deleted.',
                    ),
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
                if (confirm == true) _delete();
              },
            ),
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.accentViolet,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              hintText: 'e.g. HDFC Savings',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: !_isEditing,
          ),
          const SizedBox(height: 20),

          // Account type
          Text('Account Type', style: AppTypography.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AccountType.values.map((type) {
              final isSelected = type == _accountType;
              return ChoiceChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (_) => setState(() => _accountType = type),
                avatar: Text(type.icon, style: const TextStyle(fontSize: 14)),
                selectedColor: AppColors.accentViolet.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Initial balance
          TextField(
            controller: _balanceController,
            decoration: InputDecoration(
              labelText: _isEditing ? 'Current Balance' : 'Initial Balance',
              prefixText: '\u20B9 ',
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),

          if (_accountType == AccountType.creditCard) ...[
            const SizedBox(height: 20),
            Text('Credit Card Details', style: AppTypography.labelLarge),
            const SizedBox(height: 10),
            TextField(
              controller: _creditLimitController,
              decoration: const InputDecoration(
                labelText: 'Credit Limit',
                prefixText: '\u20B9 ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _billGenerationDayController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Gen Day (1-31)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dueDayController,
                    decoration: const InputDecoration(
                      labelText: 'Due Day (1-31)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],

          if (_accountType == AccountType.loan) ...[
            const SizedBox(height: 20),
            Text('Loan Details', style: AppTypography.labelLarge),
            const SizedBox(height: 10),
            TextField(
              controller: _loanPrincipalController,
              decoration: const InputDecoration(
                labelText: 'Original Principal',
                prefixText: '\u20B9 ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _loanInterestRateController,
              decoration: const InputDecoration(
                labelText: 'Monthly Interest Rate',
                suffixText: '%',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Color picker
          Text('Color', style: AppTypography.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColors.categoryPalette.map((color) {
              final isSelected = color.toARGB32() == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color.toARGB32()),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),

          if (_isEditing &&
              _accountType == AccountType.creditCard &&
              widget.editAccountId != null) ...[
            const SizedBox(height: 30),
            Text('Billing History', style: AppTypography.labelLarge),
            const SizedBox(height: 10),
            StreamBuilder<List<CreditCardBill>>(
              stream: ref
                  .read(accountsDaoProvider)
                  .watchBillsForAccount(widget.editAccountId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bills = snapshot.data?.toList() ?? [];
                if (bills.isEmpty) {
                  return Text(
                    'No billing history available.',
                    style: AppTypography.bodySmall,
                  );
                }

                // Sort by year, then month descending
                bills.sort((a, b) {
                  final aVal = a.billingYear * 12 + a.billingMonth;
                  final bVal = b.billingYear * 12 + b.billingMonth;
                  return bVal.compareTo(aVal);
                });

                return Column(
                  children: bills.map((bill) {
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
                      title: Text('$monthStr ${bill.billingYear} Statement'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
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
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
