/// Drift table definitions for the Finara database.
library;

import 'package:drift/drift.dart';

/// Accounts table — cash, bank, UPI, wallet, credit card, investment.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // AccountType enum stored as string
  TextColumn get icon => text().withDefault(const Constant('💰'))();
  IntColumn get color => integer().withDefault(const Constant(0xFF6C63FF))();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Categories table — income and expense categories.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // CategoryType enum stored as string
  TextColumn get icon => text().withDefault(const Constant('📁'))();
  IntColumn get color => integer().withDefault(const Constant(0xFF6C63FF))();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  BoolColumn get isSystem =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Transactions table — the core financial record.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // TransactionType enum stored as string
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId =>
      integer().nullable().references(Accounts, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))(); // comma-separated
  BoolColumn get isExcludedFromAnalytics =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Budgets table — per-category monthly budget limits.
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get month => integer()(); // 1–12
  IntColumn get year => integer()();
  RealColumn get limitAmount => real()();
  BoolColumn get rollover =>
      boolean().withDefault(const Constant(false))();
}
