import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/logger.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  final _log = AppLogger.instance;

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
    return (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();
  }

  /// Watch all categories.
  Stream<List<Category>> watchAllCategories() {
    return (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).watch();
  }

  /// Get a single category by ID.
  Future<Category?> getCategoryById(int id) {
    return (select(
      categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new category.
  Future<int> insertCategory(CategoriesCompanion category) async {
    try {
      final id = await into(categories).insert(category);
      _log.db(
        'INSERT category id=$id name="${category.name.value}" '
        'type=${category.type.value}',
      );
      return id;
    } catch (e, st) {
      _log.error('INSERT category FAILED name="${category.name.value}"', e, st);
      rethrow;
    }
  }

  /// Update an existing category.
  Future<bool> updateCategory(CategoriesCompanion category) async {
    try {
      final rows = await (update(
        categories,
      )..where((c) => c.id.equals(category.id.value))).write(category);
      final success = rows > 0;
      _log.db(
        'UPDATE category id=${category.id.value} '
        'name="${category.name.value}" success=$success',
      );
      return success;
    } catch (e, st) {
      _log.error('UPDATE category id=${category.id.value} FAILED', e, st);
      rethrow;
    }
  }

  /// Delete a category.
  Future<void> deleteCategory(int categoryId) async {
    try {
      await (delete(categories)..where((c) => c.id.equals(categoryId))).go();
      _log.db('DELETE category id=$categoryId');
    } catch (e, st) {
      _log.error('DELETE category id=$categoryId FAILED', e, st);
      rethrow;
    }
  }
}
