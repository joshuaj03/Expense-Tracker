import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/providers.dart';
import 'accounts_dao.dart';

part 'accounts_provider.g.dart';

@Riverpod(keepAlive: true)
AccountsDao accountsDao(AccountsDaoRef ref) {
  return ref.watch(databaseProvider).accountsDao;
}
