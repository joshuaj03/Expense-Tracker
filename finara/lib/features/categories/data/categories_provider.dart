import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/providers.dart';
import 'categories_dao.dart';

part 'categories_provider.g.dart';

@Riverpod(keepAlive: true)
CategoriesDao categoriesDao(CategoriesDaoRef ref) {
  return ref.watch(databaseProvider).categoriesDao;
}
