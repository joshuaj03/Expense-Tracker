import sys

def modify_file():
    with open('finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Imports
    if 'ui_preferences_provider' not in content:
        content = content.replace(
            "import '../../../../core/utils/logger.dart';",
            "import '../../../../core/utils/logger.dart';\nimport 'package:finara/features/settings/data/ui_preferences_provider.dart';\nimport 'package:intl/intl.dart';"
        )

    # 2. Add state variables
    state_vars = """
  // Dynamic fields
  bool _isCreditCardBill = false;
  DateTime _billingMonth = DateTime.now();
  bool _isLoanInterest = false;
  bool _includePrincipalInAnalytics = false;
"""
    if 'bool _isCreditCardBill' not in content:
        content = content.replace(
            "final _customShareController = TextEditingController();",
            "final _customShareController = TextEditingController();\n" + state_vars
        )

    # 3. Fix loading existing txns
    load_db_logic = """
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
"""
    content = content.replace("""
          _type = TransactionType.values.firstWhere(
            (t) => t.name == txn.type,
            orElse: () => TransactionType.expense,
          );
""", load_db_logic)

    # 4. Fix _saveTransaction
    save_logic = """
    TransactionType finalType = _type;
    bool excludeFromAnalytics = _type.excludedFromAnalytics;

    if (_type == TransactionType.transfer) {
      if (_selectedToAccount?.type == AccountType.creditCard && _isCreditCardBill) {
        finalType = TransactionType.creditCardPayment;
        excludeFromAnalytics = finalType.excludedFromAnalytics;
      } else if (_selectedToAccount?.type == AccountType.loan) {
        if (_isLoanInterest) {
          finalType = TransactionType.loanInterest;
          excludeFromAnalytics = finalType.excludedFromAnalytics;
        } else {
          finalType = TransactionType.loanPrincipalRepayment;
          excludeFromAnalytics = !_includePrincipalInAnalytics;
        }
      }
    }

    final companion = TransactionsCompanion(
      type: Value(finalType.name),
      accountId: Value(_selectedAccount!.id),
      toAccountId:
          (_type == TransactionType.transfer)
          ? Value(_selectedToAccount?.id)
          : const Value(null),
      categoryId:
          (_type != TransactionType.transfer)
          ? Value(_selectedCategory?.id)
          : const Value(null),
      amount: Value(amount),
      date: Value(_date),
      note: Value(notes),
      isExcludedFromAnalytics: Value(excludeFromAnalytics),
"""
    content = content.replace("""
    final companion = TransactionsCompanion(
      type: Value(_type.name),
      accountId: Value(_selectedAccount!.id),
      toAccountId:
          (_type == TransactionType.transfer ||
              _type == TransactionType.creditCardPayment)
          ? Value(_selectedToAccount?.id)
          : const Value(null),
      categoryId:
          (_type != TransactionType.transfer &&
              _type != TransactionType.creditCardPayment)
          ? Value(_selectedCategory?.id)
          : const Value(null),
      amount: Value(amount),
      date: Value(_date),
      note: Value(notes),
      isExcludedFromAnalytics: Value(_type.excludedFromAnalytics),
""", save_logic)

    content = content.replace("""
    if (_type != TransactionType.transfer &&
        _type != TransactionType.creditCardPayment &&
        _selectedCategory == null) {
""", """
    if (_type != TransactionType.transfer && _selectedCategory == null) {
""")
    content = content.replace("""
    if ((_type == TransactionType.transfer ||
            _type == TransactionType.creditCardPayment) &&
        _selectedToAccount == null) {
""", """
    if (_type == TransactionType.transfer && _selectedToAccount == null) {
""")
    content = content.replace("""
    if (_type == TransactionType.creditCardPayment &&
        _selectedToAccount != null) {
      try {
        final accountsDao = ref.read(accountsDaoProvider);
        await accountsDao.markBillAsPaid(
          _selectedToAccount!.id,
          _date.month,
          _date.year,
        );
""", """
    if (finalType == TransactionType.creditCardPayment && _selectedToAccount != null) {
      try {
        final accountsDao = ref.read(accountsDaoProvider);
        await accountsDao.markBillAsPaid(
          _selectedToAccount!.id,
          _billingMonth.month,
          _billingMonth.year,
        );
""")

    # 5. Build method updates
    #   Remove keyboard check
    content = content.replace("""
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
""", "")
    content = content.replace("""
                  if (!isKeyboardOpen)
                    Padding(
""", """
                  Padding(
""")

    #   Add UI setting read
    content = content.replace("""
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
""", """
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSideBySide = ref.watch(sideBySideTransactionUINotifierProvider);
""")

    #   Update segmented control
    content = content.replace("""
                  SegmentedControl<TransactionType>(
                    segments: TransactionType.values,
                    selected: _type,
                    labelBuilder: (t) => t.displayName,
                    colorBuilder: (t) => switch (t) {
                      TransactionType.income => AppColors.income,
                      TransactionType.expense => AppColors.expense,
                      TransactionType.transfer => AppColors.transfer,
                      TransactionType.creditCardPayment => AppColors.transfer,
                      TransactionType.loanPrincipalRepayment =>
                        AppColors.transfer,
                      TransactionType.loanInterest => AppColors.expense,
                    },
                    onChanged: (t) => setState(() {
                      _type = t;
                      _selectedCategory = null;
                    }),
                  ),
""", """
                  SegmentedControl<TransactionType>(
                    segments: const [TransactionType.income, TransactionType.expense, TransactionType.transfer],
                    selected: _type,
                    labelBuilder: (t) => t.displayName.toUpperCase(),
                    colorBuilder: (t) => switch (t) {
                      TransactionType.income => AppColors.income,
                      TransactionType.expense => AppColors.expense,
                      TransactionType.transfer => AppColors.transfer,
                      _ => AppColors.transfer,
                    },
                    onChanged: (t) => setState(() {
                      _type = t;
                      _selectedCategory = null;
                    }),
                  ),
""")

    #   Layout accounts and categories
    old_account_ui = """
                  // Account selector tile
                  _PickerTile(
                    label: 'Account',
                    icon: _selectedAccount?.icon ?? '💳',
                    value: _selectedAccount?.name ?? 'Select account',
                    onTap: () => _openAccountPicker(),
                  ),

                  // To Account (transfers & payments)
                  if (_type == TransactionType.transfer ||
                      _type == TransactionType.creditCardPayment) ...[
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: _type == TransactionType.creditCardPayment
                          ? 'To Credit Card'
                          : 'To Account',
                      icon: _selectedToAccount?.icon ?? '💳',
                      value: _selectedToAccount?.name ?? 'Select destination',
                      onTap: () => _openAccountPicker(isTo: true),
                    ),
                  ],

                  // Category selector (not for transfers & payments)
                  if (_type != TransactionType.transfer &&
                      _type != TransactionType.creditCardPayment) ...[
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: 'Category',
                      icon: _selectedCategory?.icon ?? '📌',
                      value: _selectedCategory?.name ?? 'Select category',
                      onTap: _openCategoryPicker,
                    ),
                  ],
"""

    new_account_ui = """
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
                              value: _selectedToAccount?.name ?? 'Select destination',
                              onTap: () => _openAccountPicker(isTo: true),
                              isCompact: true,
                            ),
                          )
                        else
                          Expanded(
                            child: _PickerTile(
                              label: 'Category',
                              icon: _selectedCategory?.icon ?? '📌',
                              value: _selectedCategory?.name ?? 'Select category',
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

                    if (_type != TransactionType.transfer) ...[
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
                    if (_selectedToAccount?.type == AccountType.creditCard) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              title: Text('Credit card bill payment?', style: AppTypography.bodyMedium),
                              value: _isCreditCardBill,
                              onChanged: (v) => setState(() => _isCreditCardBill = v ?? false),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.accentViolet,
                            ),
                            if (_isCreditCardBill)
                              ListTile(
                                leading: const Icon(Icons.calendar_month, color: AppColors.accentViolet),
                                title: const Text('Billing Month'),
                                trailing: Text(DateFormat('MMM yyyy').format(_billingMonth), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                contentPadding: EdgeInsets.zero,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _billingMonth,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() => _billingMonth = date);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (_selectedToAccount?.type == AccountType.loan) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Type', style: AppTypography.labelMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Principal'),
                                    selected: !_isLoanInterest,
                                    onSelected: (v) => setState(() => _isLoanInterest = !v),
                                    selectedColor: AppColors.accentViolet.withValues(alpha: 0.2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Interest'),
                                    selected: _isLoanInterest,
                                    onSelected: (v) => setState(() => _isLoanInterest = v),
                                    selectedColor: AppColors.accentViolet.withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
                            ),
                            if (!_isLoanInterest) ...[
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                title: Text('Include as Expense (Analytics)', style: AppTypography.bodyMedium),
                                subtitle: Text('Check if paying someone else\\'s loan', style: AppTypography.bodySmall),
                                value: _includePrincipalInAnalytics,
                                onChanged: (v) => setState(() => _includePrincipalInAnalytics = v ?? false),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: AppColors.accentViolet,
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ],
"""
    content = content.replace(old_account_ui, new_account_ui)

    # 6. Update _PickerTile class
    old_picker_tile = """
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Text(
                      value,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
"""

    new_picker_tile = """
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
        border: isCompact ? Border.all(color: AppColors.outline.withValues(alpha: 0.5)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: isCompact ? 10 : 14),
            child: Row(
              children: [
                Text(icon, style: TextStyle(fontSize: isCompact ? 24 : 20)),
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
                if (!isCompact)
                  const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""
    content = content.replace(old_picker_tile, new_picker_tile)

    with open('finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

modify_file()
