import sys

def modify_file():
    with open('finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Center the top SegmentedControl
    old_top_control = """                  // Transaction type selector
                  SegmentedControl<TransactionType>("""
    new_top_control = """                  // Transaction type selector
                  Center(
                    child: SegmentedControl<TransactionType>("""
    
    # We also need to close the Center() widget.
    old_top_control_end = """                      _selectedCategory = null;
                    }),
                  ),
                  const SizedBox(height: 20),"""
    new_top_control_end = """                      _selectedCategory = null;
                    }),
                  ),
                  ),
                  const SizedBox(height: 20),"""
    
    content = content.replace(old_top_control, new_top_control)
    content = content.replace(old_top_control_end, new_top_control_end)

    # 2. Replace credit card logic
    old_cc_logic = """                        child: Column(
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
                        ),"""

    new_cc_logic = """                        child: Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('Credit card bill payment?', style: AppTypography.bodyMedium),
                                value: _isCreditCardBill,
                                onChanged: (v) => setState(() => _isCreditCardBill = v ?? false),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: AppColors.accentViolet,
                              ),
                            ),
                            if (_isCreditCardBill)
                              GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _billingMonth,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    initialDatePickerMode: DatePickerMode.year,
                                  );
                                  if (date != null) {
                                    setState(() => _billingMonth = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentViolet.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.accentViolet.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_month, size: 16, color: AppColors.accentViolet),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('MMM yyyy').format(_billingMonth),
                                        style: AppTypography.labelMedium.copyWith(color: AppColors.accentViolet, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),"""
    
    content = content.replace(old_cc_logic, new_cc_logic)

    # 3. Replace loan logic
    old_loan_logic = """                            Text('Payment Type', style: AppTypography.labelMedium),
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
                            ),"""

    new_loan_logic = """                            Text('Payment Type', style: AppTypography.labelMedium),
                            const SizedBox(height: 8),
                            Center(
                              child: SegmentedControl<bool>(
                                segments: const [false, true],
                                selected: _isLoanInterest,
                                labelBuilder: (isInterest) => isInterest ? 'Interest' : 'Principal',
                                onChanged: (v) => setState(() => _isLoanInterest = v),
                              ),
                            ),"""

    content = content.replace(old_loan_logic, new_loan_logic)

    with open('finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

modify_file()
