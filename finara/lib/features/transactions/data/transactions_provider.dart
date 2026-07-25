import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/providers.dart';
import '../../../core/database/app_database.dart';
import 'transactions_dao.dart';

part 'transactions_provider.g.dart';

@Riverpod(keepAlive: true)
TransactionsDao transactionsDao(TransactionsDaoRef ref) {
  return ref.watch(databaseProvider).transactionsDao;
}

@riverpod
Future<List<Transaction>> pendingRecoveries(PendingRecoveriesRef ref) {
  final dao = ref.watch(transactionsDaoProvider);
  return dao.getPendingRecoveries();
}

@riverpod
Future<List<Transaction>> settledRecoveries(SettledRecoveriesRef ref) {
  final dao = ref.watch(transactionsDaoProvider);
  return dao.getSettledRecoveries();
}
