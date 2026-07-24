import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/providers.dart';
import 'transactions_dao.dart';

part 'transactions_provider.g.dart';

@Riverpod(keepAlive: true)
TransactionsDao transactionsDao(TransactionsDaoRef ref) {
  return ref.watch(databaseProvider).transactionsDao;
}
