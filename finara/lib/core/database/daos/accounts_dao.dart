import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts, Transactions, CreditCardBills])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  /// Watch all non-archived accounts ordered by sort order.
  Stream<List<Account>> watchAllAccounts() {
    return (select(accounts)
          ..where((a) => a.archived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .watch();
  }

  /// Get all non-archived accounts.
  Future<List<Account>> getAllAccounts() {
    return (select(accounts)
          ..where((a) => a.archived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .get();
  }

  /// Get a single account by ID.
  Future<Account?> getAccountById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new account and return its ID.
  Future<int> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  /// Update an existing account.
  Future<bool> updateAccount(AccountsCompanion account) {
    return (update(accounts)..where((a) => a.id.equals(account.id.value)))
        .write(account)
        .then((rows) => rows > 0);
  }

  /// Update just the balance of an account.
  Future<void> updateBalance(int accountId, double newBalance) {
    return (update(accounts)..where((a) => a.id.equals(accountId)))
        .write(AccountsCompanion(currentBalance: Value(newBalance)));
  }

  /// Archive an account (soft delete).
  Future<void> archiveAccount(int accountId) {
    return (update(accounts)..where((a) => a.id.equals(accountId)))
        .write(const AccountsCompanion(archived: Value(true)));
  }

  /// Delete an account permanently.
  Future<void> deleteAccount(int accountId) {
    return (delete(accounts)..where((a) => a.id.equals(accountId))).go();
  }

  /// Get total balance across all active accounts.
  Stream<double> watchTotalBalance() {
    final query = selectOnly(accounts)
      ..where(accounts.archived.equals(false))
      ..addColumns([accounts.currentBalance.sum()]);
    return query.watchSingle().map(
        (row) => row.read(accounts.currentBalance.sum()) ?? 0.0);
  }

  /// Mark a credit card bill as paid for a given month/year
  Future<void> markBillAsPaid(int accountId, int month, int year) async {
    // Check if exists
    final existing = await (select(creditCardBills)
          ..where((b) =>
              b.accountId.equals(accountId) &
              b.billingMonth.equals(month) &
              b.billingYear.equals(year)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(creditCardBills)..where((b) => b.id.equals(existing.id)))
          .write(const CreditCardBillsCompanion(isPaid: Value(true)));
    } else {
      await into(creditCardBills).insert(CreditCardBillsCompanion(
        accountId: Value(accountId),
        billingMonth: Value(month),
        billingYear: Value(year),
        isPaid: const Value(true),
      ));
    }
  }

  /// Watch unpaid bills (needs manual cross-referencing with current date in UI)
  Stream<List<CreditCardBill>> watchBillsForAccount(int accountId) {
    return (select(creditCardBills)
          ..where((b) => b.accountId.equals(accountId)))
        .watch();
  }
}
