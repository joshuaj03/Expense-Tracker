import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/logger.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts, Transactions, CreditCardBills])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  final _log = AppLogger.instance;

  /// Watch all non-archived accounts ordered by sort order.
  Stream<List<Account>> watchAllAccounts() {
    _log.db('WATCH all accounts');
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
  Future<int> insertAccount(AccountsCompanion account) async {
    try {
      final id = await into(accounts).insert(account);
      _log.db(
        'INSERT account id=$id name="${account.name.value}" '
        'type=${account.type.value} balance=${account.initialBalance.value}',
      );
      return id;
    } catch (e, st) {
      _log.error('INSERT account FAILED name="${account.name.value}"', e, st);
      rethrow;
    }
  }

  /// Update an existing account.
  Future<bool> updateAccount(AccountsCompanion account) async {
    try {
      final rows = await (update(
        accounts,
      )..where((a) => a.id.equals(account.id.value))).write(account);
      final success = rows > 0;
      _log.db(
        'UPDATE account id=${account.id.value} '
        'name="${account.name.value}" success=$success',
      );
      return success;
    } catch (e, st) {
      _log.error('UPDATE account id=${account.id.value} FAILED', e, st);
      rethrow;
    }
  }

  /// Update just the balance of an account.
  Future<void> updateBalance(int accountId, double newBalance) async {
    try {
      await (update(accounts)..where((a) => a.id.equals(accountId))).write(
        AccountsCompanion(currentBalance: Value(newBalance)),
      );
      _log.db('BALANCE UPDATE account id=$accountId → $newBalance');
    } catch (e, st) {
      _log.error('BALANCE UPDATE account id=$accountId FAILED', e, st);
      rethrow;
    }
  }

  /// Archive an account (soft delete).
  Future<void> archiveAccount(int accountId) async {
    try {
      await (update(accounts)..where((a) => a.id.equals(accountId))).write(
        const AccountsCompanion(archived: Value(true)),
      );
      _log.db('ARCHIVE account id=$accountId');
    } catch (e, st) {
      _log.error('ARCHIVE account id=$accountId FAILED', e, st);
      rethrow;
    }
  }

  /// Delete an account permanently (used internally or for soft delete fallback).
  Future<void> deleteAccount(int accountId) async {
    try {
      await (delete(accounts)..where((a) => a.id.equals(accountId))).go();
      _log.db('DELETE account id=$accountId');
    } catch (e, st) {
      _log.error('DELETE account id=$accountId FAILED', e, st);
      rethrow;
    }
  }

  /// Hard delete an account: Deletes all associated transactions first, then the account.
  Future<void> hardDeleteAccount(int accountId) async {
    return transaction(() async {
      try {
        _log.db('HARD DELETE account id=$accountId initialized');
        // Delete all transactions where this account is either the source or destination
        await (delete(transactions)..where(
              (t) =>
                  t.accountId.equals(accountId) |
                  t.toAccountId.equals(accountId),
            ))
            .go();

        // Delete all credit card bills associated
        await (delete(
          creditCardBills,
        )..where((b) => b.accountId.equals(accountId))).go();

        // Delete the account
        await (delete(accounts)..where((a) => a.id.equals(accountId))).go();
        _log.db('HARD DELETE account id=$accountId completed successfully');
      } catch (e, st) {
        _log.error('HARD DELETE account id=$accountId FAILED', e, st);
        rethrow;
      }
    });
  }

  /// Toggle ignore status of an account.
  Future<void> toggleIgnoreAccount(int accountId, bool isIgnored) async {
    try {
      await (update(accounts)..where((a) => a.id.equals(accountId))).write(
        AccountsCompanion(isIgnored: Value(isIgnored)),
      );
      _log.db('TOGGLE IGNORE account id=$accountId -> isIgnored=$isIgnored');
    } catch (e, st) {
      _log.error('TOGGLE IGNORE account id=$accountId FAILED', e, st);
      rethrow;
    }
  }

  /// Get total balance across all active, non-ignored accounts.
  Stream<double> watchTotalBalance() {
    final query = selectOnly(accounts)
      ..where(
        accounts.archived.equals(false) & accounts.isIgnored.equals(false),
      )
      ..addColumns([accounts.currentBalance.sum()]);
    return query.watchSingle().map(
      (row) => row.read(accounts.currentBalance.sum()) ?? 0.0,
    );
  }

  /// Mark a credit card bill as paid for a given month/year
  Future<void> markBillAsPaid(int accountId, int month, int year) async {
    try {
      // Check if exists
      final existing =
          await (select(creditCardBills)..where(
                (b) =>
                    b.accountId.equals(accountId) &
                    b.billingMonth.equals(month) &
                    b.billingYear.equals(year),
              ))
              .getSingleOrNull();

      if (existing != null) {
        await (update(creditCardBills)..where((b) => b.id.equals(existing.id)))
            .write(const CreditCardBillsCompanion(isPaid: Value(true)));
      } else {
        await into(creditCardBills).insert(
          CreditCardBillsCompanion(
            accountId: Value(accountId),
            billingMonth: Value(month),
            billingYear: Value(year),
            isPaid: const Value(true),
          ),
        );
      }
      _log.db('MARK BILL PAID account=$accountId month=$month/$year');
    } catch (e, st) {
      _log.error('MARK BILL PAID FAILED account=$accountId', e, st);
      rethrow;
    }
  }

  /// Generates a bill for a given month/year if it doesn't exist
  Future<void> generateBillIfNotExists(
    int accountId,
    int month,
    int year,
  ) async {
    try {
      final existing =
          await (select(creditCardBills)..where(
                (b) =>
                    b.accountId.equals(accountId) &
                    b.billingMonth.equals(month) &
                    b.billingYear.equals(year),
              ))
              .getSingleOrNull();

      if (existing == null) {
        // Calculate bill amount
        final account = await getAccountById(accountId);
        double billAmount = 0.0;

        if (account != null && account.billGenerationDay != null) {
          final billDay = account.billGenerationDay!;
          // Start date: previous month's bill generation day (exclusive)
          final prevMonth = month == 1 ? 12 : month - 1;
          final prevYear = month == 1 ? year - 1 : year;
          // E.g., if billDay is 15, then previous month 15th 23:59:59 to current month 15th 23:59:59
          final startDate = DateTime(prevYear, prevMonth, billDay, 23, 59, 59);
          final endDate = DateTime(year, month, billDay, 23, 59, 59);

          // Get expenses for this period
          final expenses =
              await (select(transactions)..where(
                    (t) =>
                        t.accountId.equals(accountId) &
                        t.type.equals('expense') &
                        t.date.isBetweenValues(startDate, endDate),
                  ))
                  .get();

          for (final t in expenses) {
            billAmount += t.amount;
          }
        }

        await into(creditCardBills).insert(
          CreditCardBillsCompanion(
            accountId: Value(accountId),
            billingMonth: Value(month),
            billingYear: Value(year),
            isPaid: const Value(false),
            billAmount: Value(billAmount),
          ),
        );
        _log.db(
          'GENERATED UNPAID BILL account=$accountId month=$month/$year amount=$billAmount',
        );
      }
    } catch (e, st) {
      _log.error('GENERATE BILL FAILED account=$accountId', e, st);
      rethrow;
    }
  }

  /// Watch unpaid bills (needs manual cross-referencing with current date in UI)
  Stream<List<CreditCardBill>> watchBillsForAccount(int accountId) {
    return (select(
      creditCardBills,
    )..where((b) => b.accountId.equals(accountId))).watch();
  }
}
