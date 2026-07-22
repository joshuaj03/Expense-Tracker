/// Default seed data for categories — pre-populated on first launch.
library;

import 'package:drift/drift.dart';
import 'app_database.dart';

/// Default expense categories with curated icons and colors.
final List<CategoriesCompanion> defaultExpenseCategories = [
  _cat('Food & Dining', 'expense', '🍕', 0xFFFF6B6B, 0),
  _cat('Groceries', 'expense', '🛒', 0xFFFF8E53, 1),
  _cat('Transport', 'expense', '🚗', 0xFF4ECDC4, 2),
  _cat('Shopping', 'expense', '🛍️', 0xFFE040FB, 3),
  _cat('Entertainment', 'expense', '🎬', 0xFFAB47BC, 4),
  _cat('Bills & Utilities', 'expense', '💡', 0xFFFFB74D, 5),
  _cat('Health', 'expense', '🏥', 0xFF66BB6A, 6),
  _cat('Education', 'expense', '📚', 0xFF42A5F5, 7),
  _cat('Rent', 'expense', '🏠', 0xFF78909C, 8),
  _cat('Personal Care', 'expense', '💇', 0xFFEC407A, 9),
  _cat('Clothing', 'expense', '👗', 0xFFBA68C8, 10),
  _cat('Travel', 'expense', '✈️', 0xFF26C6DA, 11),
  _cat('Insurance', 'expense', '🛡️', 0xFF7E57C2, 12),
  _cat('Gifts & Donations', 'expense', '🎁', 0xFFEF5350, 13),
  _cat('Subscriptions', 'expense', '📺', 0xFF5C6BC0, 14),
  _cat('Other', 'expense', '📌', 0xFF8D6E63, 15),
];

/// Default income categories.
final List<CategoriesCompanion> defaultIncomeCategories = [
  _cat('Salary', 'income', '💰', 0xFF66BB6A, 0),
  _cat('Freelance', 'income', '💻', 0xFF42A5F5, 1),
  _cat('Business', 'income', '📊', 0xFF26A69A, 2),
  _cat('Investments', 'income', '📈', 0xFFAB47BC, 3),
  _cat('Rental Income', 'income', '🏠', 0xFF78909C, 4),
  _cat('Interest', 'income', '🏦', 0xFF5C6BC0, 5),
  _cat('Cashback', 'income', '🔄', 0xFFFF7043, 6),
  _cat('Other Income', 'income', '✨', 0xFF8D6E63, 7),
];

CategoriesCompanion _cat(
    String name, String type, String icon, int color, int order) {
  return CategoriesCompanion.insert(
    name: name,
    type: type,
    icon: Value(icon),
    color: Value(color),
    isSystem: const Value(true),
    sortOrder: Value(order),
  );
}

/// Seed the database with default categories if none exist.
Future<void> seedDefaultCategories(
    Future<List<Category>> Function() getAll,
    Future<int> Function(CategoriesCompanion) insert) async {
  final existing = await getAll();
  if (existing.isNotEmpty) return;

  for (final cat in defaultExpenseCategories) {
    await insert(cat);
  }
  for (final cat in defaultIncomeCategories) {
    await insert(cat);
  }
}
