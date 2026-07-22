/// Enums used across the Finara app data model.
library;

/// Account types supported by the app.
enum AccountType {
  cash,
  bank,
  upi,
  wallet,
  creditCard,
  investment;

  String get displayName => switch (this) {
        cash => 'Cash',
        bank => 'Bank Account',
        upi => 'UPI',
        wallet => 'Wallet',
        creditCard => 'Credit Card',
        investment => 'Investment',
      };

  String get icon => switch (this) {
        cash => '💵',
        bank => '🏦',
        upi => '📱',
        wallet => '👛',
        creditCard => '💳',
        investment => '📈',
      };
}

/// Transaction types.
enum TransactionType {
  income,
  expense,
  transfer;

  String get displayName => switch (this) {
        income => 'Income',
        expense => 'Expense',
        transfer => 'Transfer',
      };

  /// Whether this transaction type should be excluded from analytics by default.
  bool get excludedFromAnalytics => this == transfer;
}

/// Category type — income or expense.
enum CategoryType {
  income,
  expense;

  String get displayName => switch (this) {
        income => 'Income',
        expense => 'Expense',
      };
}
