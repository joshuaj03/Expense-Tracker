/// Enums used across the Finara app data model.
library;

/// Account types supported by the app.
enum AccountType {
  cash,
  bank,
  upi,
  wallet,
  creditCard,
  investment,
  loan;

  String get displayName => switch (this) {
    cash => 'Cash',
    bank => 'Bank Account',
    upi => 'UPI',
    wallet => 'Wallet',
    creditCard => 'Credit Card',
    investment => 'Investment',
    loan => 'Loan',
  };

  String get icon => switch (this) {
    cash => '💵',
    bank => '🏦',
    upi => '📱',
    wallet => '👛',
    creditCard => '💳',
    investment => '📈',
    loan => '📉',
  };
}

/// Transaction types.
enum TransactionType {
  income,
  expense,
  transfer,
  creditCardPayment,
  loanPrincipalRepayment,
  loanInterest;

  String get displayName => switch (this) {
    income => 'Income',
    expense => 'Expense',
    transfer => 'Transfer',
    creditCardPayment => 'Credit Card Payment',
    loanPrincipalRepayment => 'Principal Repayment',
    loanInterest => 'Interest Payment',
  };

  /// Whether this transaction type should be excluded from analytics by default.
  bool get excludedFromAnalytics => switch (this) {
    transfer => true,
    creditCardPayment => true,
    loanPrincipalRepayment => true,
    _ => false,
  };
}

/// Category type â€” income or expense.
enum CategoryType {
  income,
  expense;

  String get displayName => switch (this) {
    income => 'Income',
    expense => 'Expense',
  };
}
