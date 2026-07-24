import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/providers.dart';
import 'budgets_dao.dart';

part 'budgets_provider.g.dart';

@Riverpod(keepAlive: true)
BudgetsDao budgetsDao(BudgetsDaoRef ref) {
  return ref.watch(databaseProvider).budgetsDao;
}
