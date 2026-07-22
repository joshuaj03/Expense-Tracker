/// Riverpod providers for database and DAOs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Theme mode provider (persisted).
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, int>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<int> {
  ThemeModeNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('theme_mode') ?? 0; // 0=system, 1=dark, 2=light
  }

  Future<void> setMode(int mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode);
  }
}
