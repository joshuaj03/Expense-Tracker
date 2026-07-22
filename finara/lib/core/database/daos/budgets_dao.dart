import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'budgets_dao.g.dart';

/// Budget with its category info and current spend.
class BudgetWithCategory {
  final Budget budget;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;

  BudgetWithCategory({
    required this.budget,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });
}

@DriftAccessor(tables: [Budgets, Categories, Transactions])
class BudgetsDao extends DatabaseAccessor<AppDatabase>
    with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  /// Watch all budgets for a given month with category info.
  Stream<List<BudgetWithCategory>> watchBudgetsForMonth(
      int year, int month) {
    final query = select(budgets).join([
      innerJoin(categories, categories.id.equalsExp(budgets.categoryId)),
    ]);
    query.where(
      budgets.year.equals(year) & budgets.month.equals(month),
    );

    return query.watch().map((rows) => rows.map((row) {
          final budget = row.readTable(budgets);
          final category = row.readTable(categories);
          return BudgetWithCategory(
            budget: budget,
            categoryName: category.name,
            categoryIcon: category.icon,
            categoryColor: category.color,
          );
        }).toList());
  }

  /// Get a budget by category and month.
  Future<Budget?> getBudget(int categoryId, int year, int month) {
    return (select(budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              b.year.equals(year) &
              b.month.equals(month)))
        .getSingleOrNull();
  }

  /// Insert or update a budget.
  Future<void> upsertBudget(BudgetsCompanion budget) async {
    final existing = await getBudget(
      budget.categoryId.value,
      budget.year.value ?? 0,
      budget.month.value ?? 0,
    );
    if (existing != null) {
      await (update(budgets)..where((b) => b.id.equals(existing.id)))
          .write(budget);
    } else {
      await into(budgets).insert(budget);
    }
  }

  /// Delete a budget.
  Future<void> deleteBudget(int budgetId) {
    return (delete(budgets)..where((b) => b.id.equals(budgetId))).go();
  }

  /// Get spending for budget categories in a month.
  Future<Map<int, double>> getSpendingForMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final txns = await (select(transactions)
          ..where((t) =>
              t.date.isBetweenValues(startDate, endDate) &
              t.type.equals('expense') &
              t.isExcludedFromAnalytics.equals(false)))
        .get();

    final map = <int, double>{};
    for (final t in txns) {
      if (t.categoryId != null) {
        map[t.categoryId!] = (map[t.categoryId!] ?? 0) + t.amount;
      }
    }
    return map;
  }
}
