import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/providers/providers.dart';

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

    final balance =
        double.tryParse(_balanceController.text.trim()) ?? 0;

    final dao = ref.read(accountsDaoProvider);

    if (_isEditing) {
      await dao.updateAccount(AccountsCompanion(
        id: Value(widget.editAccountId!),
        name: Value(name),
        type: Value(_accountType.name),
        icon: Value(_accountType.icon),
        color: Value(_selectedColor),
        currentBalance: Value(balance),
      ));
    } else {
      await dao.insertAccount(AccountsCompanion(
        name: Value(name),
        type: Value(_accountType.name),
        icon: Value(_accountType.icon),
        color: Value(_selectedColor),
        initialBalance: Value(balance),
        currentBalance: Value(balance),
      ));
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
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.expense),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text(
                        'This will remove the account. Transactions will not be deleted.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style:
                                  TextStyle(color: AppColors.expense))),
                    ],
                  ),
                );
                if (confirm == true) _delete();
              },
            ),
          TextButton(
            onPressed: _save,
            child: Text('Save',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.accentViolet)),
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
                onSelected: (_) =>
                    setState(() => _accountType = type),
                avatar: Text(type.icon,
                    style: const TextStyle(fontSize: 14)),
                selectedColor:
                    AppColors.accentViolet.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Initial balance
          TextField(
            controller: _balanceController,
            decoration: InputDecoration(
              labelText:
                  _isEditing ? 'Current Balance' : 'Initial Balance',
              prefixText: '₹ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
          ),
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
                onTap: () =>
                    setState(() => _selectedColor = color.toARGB32()),
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
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
