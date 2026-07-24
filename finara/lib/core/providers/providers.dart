/// Riverpod providers for database and DAOs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// The single AppDatabase instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Accounts DAO provider.
final accountsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).accountsDao;
});

/// Categories DAO provider.
final categoriesDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).categoriesDao;
});

/// Transactions DAO provider.
final transactionsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).transactionsDao;
});

/// Budgets DAO provider.
final budgetsDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).budgetsDao;
});
