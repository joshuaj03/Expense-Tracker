import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Watch all categories of a given type.
  Stream<List<Category>> watchCategoriesByType(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Get all categories of a given type.
  Future<List<Category>> getCategoriesByType(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Get all categories.
  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Watch all categories.
  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Get a single category by ID.
  Future<Category?> getCategoryById(int id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new category.
  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// Update an existing category.
  Future<bool> updateCategory(CategoriesCompanion category) {
    return (update(categories)
          ..where((c) => c.id.equals(category.id.value)))
        .write(category)
        .then((rows) => rows > 0);
  }

  /// Delete a category.
  Future<void> deleteCategory(int categoryId) {
    return (delete(categories)..where((c) => c.id.equals(categoryId))).go();
  }
}
