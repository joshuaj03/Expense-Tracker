import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/logger.dart';

part 'transactions_dao.g.dart';

/// A joined transaction result with category and account names.
class TransactionWithDetails {
  final Transaction transaction;
  final String accountName;
  final String? toAccountName;
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;

  TransactionWithDetails({
    required this.transaction,
    required this.accountName,
    this.toAccountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });
}

@DriftAccessor(tables: [Transactions, Accounts, Categories])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  final _log = AppLogger.instance;

  /// Watch all transactions with their details, ordered by date descending.
  Stream<List<TransactionWithDetails>> watchAllTransactionsWithDetails({
    int? limit,
    int? accountId,
  }) {
    _log.db('WATCH all transactions (limit=$limit, accountId=$accountId)');
    final toAccount = alias(accounts, 'toAcc');
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
        toAccount,
        toAccount.id.equalsExp(transactions.toAccountId),
      ),
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
    ]);

    query.orderBy([OrderingTerm.desc(transactions.date)]);

    if (accountId != null) {
      query.where(
        transactions.accountId.equals(accountId) |
            transactions.toAccountId.equals(accountId),
      );
    }
    if (limit != null) {
      query.limit(limit);
    }

    return query.watch().map(
      (rows) => rows.map((row) {
        return TransactionWithDetails(
          transaction: row.readTable(transactions),
          accountName: row.readTable(accounts).name,
          toAccountName: row.readTableOrNull(toAccount)?.name,
          categoryName: row.readTableOrNull(categories)?.name,
          categoryIcon: row.readTableOrNull(categories)?.icon,
          categoryColor: row.readTableOrNull(categories)?.color,
        );
      }).toList(),
    );
  }

  /// Watch transactions for a specific date range.
  Stream<List<TransactionWithDetails>> watchTransactionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    _log.db('WATCH transactions for range $startDate to $endDate');
    final toAccount = alias(accounts, 'toAcc');
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
        toAccount,
        toAccount.id.equalsExp(transactions.toAccountId),
      ),
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
    ]);

    query.where(transactions.date.isBetweenValues(startDate, endDate));
    query.orderBy([OrderingTerm.desc(transactions.date)]);

    return query.watch().map(
      (rows) => rows.map((row) {
        return TransactionWithDetails(
          transaction: row.readTable(transactions),
          accountName: row.readTable(accounts).name,
          toAccountName: row.readTableOrNull(toAccount)?.name,
          categoryName: row.readTableOrNull(categories)?.name,
          categoryIcon: row.readTableOrNull(categories)?.icon,
          categoryColor: row.readTableOrNull(categories)?.color,
        );
      }).toList(),
    );
  }

  /// Watch transactions for a specific account and date range.
  Stream<List<TransactionWithDetails>> watchTransactionsForAccountAndDateRange(
    int accountId,
    DateTime startDate,
    DateTime endDate,
  ) {
    _log.db(
      'WATCH transactions for acc=$accountId range $startDate to $endDate',
    );
    final toAccount = alias(accounts, 'toAcc');
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
        toAccount,
        toAccount.id.equalsExp(transactions.toAccountId),
      ),
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
    ]);

    query.where(
      transactions.date.isBetweenValues(startDate, endDate) &
          (transactions.accountId.equals(accountId) |
              transactions.toAccountId.equals(accountId)),
    );
    query.orderBy([OrderingTerm.desc(transactions.date)]);

    return query.watch().map(
      (rows) => rows.map((row) {
        return TransactionWithDetails(
          transaction: row.readTable(transactions),
          accountName: row.readTable(accounts).name,
          toAccountName: row.readTableOrNull(toAccount)?.name,
          categoryName: row.readTableOrNull(categories)?.name,
          categoryIcon: row.readTableOrNull(categories)?.icon,
          categoryColor: row.readTableOrNull(categories)?.color,
        );
      }).toList(),
    );
  }

  /// Insert a new transaction.
  Future<int> insertTransaction(TransactionsCompanion transaction) async {
    try {
      final id = await into(transactions).insert(transaction);
      _log.db(
        'INSERT transaction id=$id type=${transaction.type.value} '
        'amount=${transaction.amount.value} '
        'accountId=${transaction.accountId.value} '
        'categoryId=${transaction.categoryId.value}',
      );
      return id;
    } catch (e, st) {
      _log.error('INSERT transaction FAILED', e, st);
      rethrow;
    }
  }

  /// Update an existing transaction.
  Future<bool> updateTransaction(
    int id,
    TransactionsCompanion transaction,
  ) async {
    try {
      final rows = await (update(
        transactions,
      )..where((t) => t.id.equals(id))).write(transaction);
      final success = rows > 0;
      _log.db(
        'UPDATE transaction id=$id success=$success '
        'type=${transaction.type.present ? transaction.type.value : 'unchanged'} '
        'amount=${transaction.amount.present ? transaction.amount.value : 'unchanged'}',
      );
      return success;
    } catch (e, st) {
      _log.error('UPDATE transaction id=$id FAILED', e, st);
      rethrow;
    }
  }

  /// Get a transaction by ID.
  Future<Transaction?> getTransactionById(int id) {
    _log.db('GET transaction by id=$id');
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new transaction and update account balances.
  Future<int> insertTransactionWithBalance(TransactionsCompanion txn) async {
    try {
      final id = await into(transactions).insert(txn);

      final amount = txn.amount.value;
      final type = txn.type.value;
      final accId = txn.accountId.value;

      final account = await (select(
        accounts,
      )..where((a) => a.id.equals(accId))).getSingle();

      double newBalance = account.currentBalance;
      if (type == 'income') {
        newBalance += amount;
      } else if (type == 'expense') {
        newBalance -= amount;
      } else if (type == 'settle') {
        if (txn.isDebt.value) { // Expense (paying back)
          newBalance -= amount;
        } else { // Income (recovering)
          newBalance += amount;
        }
      } else if (type == 'transfer' || type == 'creditCardPayment') {
        newBalance -= amount;
        // Update destination account
        if (txn.toAccountId.present && txn.toAccountId.value != null) {
          final toAcc = await (select(
            accounts,
          )..where((a) => a.id.equals(txn.toAccountId.value!))).getSingle();
          await (update(
            accounts,
          )..where((a) => a.id.equals(txn.toAccountId.value!))).write(
            AccountsCompanion(
              currentBalance: Value(toAcc.currentBalance + amount),
            ),
          );
          _log.db(
            'BALANCE UPDATE toAccount id=${txn.toAccountId.value} '
            '${toAcc.currentBalance} → ${toAcc.currentBalance + amount}',
          );
        }
      }

      await (update(accounts)..where((a) => a.id.equals(accId))).write(
        AccountsCompanion(currentBalance: Value(newBalance)),
      );

      _log.db(
        'INSERT+BALANCE transaction id=$id type=$type amount=$amount '
        'account="${account.name}" balance ${account.currentBalance} → $newBalance',
      );
      return id;
    } catch (e, st) {
      _log.error('INSERT+BALANCE transaction FAILED', e, st);
      rethrow;
    }
  }

  /// Delete a transaction and reverse the balance change.
  Future<void> deleteTransaction(int txnId) async {
    try {
      final txn = await (select(
        transactions,
      )..where((t) => t.id.equals(txnId))).getSingleOrNull();
      if (txn == null) {
        _log.warning('DELETE transaction id=$txnId — not found, skipping');
        return;
      }

      final account = await (select(
        accounts,
      )..where((a) => a.id.equals(txn.accountId))).getSingle();

      // If this was a settlement, reverse the settled amount on the parent
      if (txn.type == 'settle' && txn.settlementForTxnId != null) {
        final parentTxn = await getTransactionById(txn.settlementForTxnId!);
        if (parentTxn != null) {
          final newSettledAmount = parentTxn.settledAmount - txn.amount;
          await (update(transactions)..where((t) => t.id.equals(parentTxn.id))).write(
            TransactionsCompanion(
              settledAmount: Value(newSettledAmount),
              isFullySettled: const Value(false),
            ),
          );
        }
      }

      double newBalance = account.currentBalance;
      if (txn.type == 'income') {
        newBalance -= txn.amount;
      } else if (txn.type == 'expense') {
        newBalance += txn.amount;
      } else if (txn.type == 'settle') {
        if (txn.isDebt) { // Reversed expense
          newBalance += txn.amount;
        } else { // Reversed income
          newBalance -= txn.amount;
        }
      } else if (txn.type == 'transfer' || txn.type == 'creditCardPayment') {
        newBalance += txn.amount;
        if (txn.toAccountId != null) {
          final toAcc = await (select(
            accounts,
          )..where((a) => a.id.equals(txn.toAccountId!))).getSingle();
          await (update(
            accounts,
          )..where((a) => a.id.equals(txn.toAccountId!))).write(
            AccountsCompanion(
              currentBalance: Value(toAcc.currentBalance - txn.amount),
            ),
          );
          _log.db(
            'DELETE BALANCE REVERSE toAccount id=${txn.toAccountId} '
            '${toAcc.currentBalance} → ${toAcc.currentBalance - txn.amount}',
          );
        }
      }

      await (update(accounts)..where((a) => a.id.equals(txn.accountId))).write(
        AccountsCompanion(currentBalance: Value(newBalance)),
      );

      await (delete(transactions)..where((t) => t.id.equals(txnId))).go();

      _log.db(
        'DELETE transaction id=$txnId type=${txn.type} '
        'amount=${txn.amount} account="${account.name}" '
        'balance ${account.currentBalance} → $newBalance',
      );
    } catch (e, st) {
      _log.error('DELETE transaction id=$txnId FAILED', e, st);
      rethrow;
    }
  }

  /// Search transactions by note text.
  Stream<List<TransactionWithDetails>> searchTransactions(String query) {
    _log.db('SEARCH transactions query="$query"');
    final toAccount = alias(accounts, 'toAcc');
    final q = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
        toAccount,
        toAccount.id.equalsExp(transactions.toAccountId),
      ),
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
    ]);

    q.where(
      transactions.note.like('%$query%') |
          categories.name.like('%$query%') |
          accounts.name.like('%$query%'),
    );
    q.orderBy([OrderingTerm.desc(transactions.date)]);

    return q.watch().map(
      (rows) => rows.map((row) {
        return TransactionWithDetails(
          transaction: row.readTable(transactions),
          accountName: row.readTable(accounts).name,
          toAccountName: row.readTableOrNull(toAccount)?.name,
          categoryName: row.readTableOrNull(categories)?.name,
          categoryIcon: row.readTableOrNull(categories)?.icon,
          categoryColor: row.readTableOrNull(categories)?.color,
        );
      }).toList(),
    );
  }

  /// Get income and expense totals for a month (excluding transfers/excluded).
  Stream<({double income, double expense})> watchMonthlyTotals(
    int year,
    int month,
  ) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return watchTotalsForDateRange(startDate, endDate);
  }

  Stream<({double income, double expense})> watchTotalsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ]);
    query.where(
      transactions.date.isBetweenValues(startDate, endDate) &
          transactions.isExcludedFromAnalytics.equals(false) &
          accounts.isIgnored.equals(false),
    );

    return query.watch().map((rows) {
      double income = 0;
      double expense = 0;
      for (final row in rows) {
        final t = row.readTable(transactions);
        final amt = t.userShareAmount ?? t.amount;
        if (t.type == 'income') {
          income += amt;
        } else if (t.type == 'expense') {
          expense += amt;
        }
      }
      return (income: income, expense: expense);
    });
  }

  /// Get spending by category for a month (expenses only, analytics-eligible).
  Stream<Map<int, double>> watchCategorySpending(int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ]);
    query.where(
      transactions.date.isBetweenValues(startDate, endDate) &
          transactions.type.equals('expense') &
          transactions.isExcludedFromAnalytics.equals(false) &
          accounts.isIgnored.equals(false),
    );

    return query.watch().map((rows) {
      final map = <int, double>{};
      for (final row in rows) {
        final t = row.readTable(transactions);
        final amt = t.userShareAmount ?? t.amount;
        if (t.categoryId != null) {
          map[t.categoryId!] = (map[t.categoryId!] ?? 0) + amt;
        }
      }
      return map;
    });
  }

  /// Get monthly totals for the last N months (for bar chart).
  Future<List<({int year, int month, double income, double expense})>>
  getMonthlyTrend(int months) async {
    final now = DateTime.now();
    final results = <({int year, int month, double income, double expense})>[];

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

      final query = select(transactions).join([
        innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      ]);
      query.where(
        transactions.date.isBetweenValues(date, endDate) &
            transactions.isExcludedFromAnalytics.equals(false) &
            accounts.isIgnored.equals(false),
      );
      final rows = await query.get();

      double income = 0;
      double expense = 0;
      for (final row in rows) {
        final t = row.readTable(transactions);
        final amt = t.userShareAmount ?? t.amount;
        if (t.type == 'income') income += amt;
        if (t.type == 'expense') expense += amt;
      }

      results.add((
        year: date.year,
        month: date.month,
        income: income,
        expense: expense,
      ));
    }

    return results;
  }

  Future<List<Transaction>> getPendingRecoveries() async {
    final query = select(transactions)
      ..where((t) =>
          t.isFullySettled.equals(false) &
          (t.isSplit.equals(true) | t.isDebt.equals(true)))
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    return query.get();
  }

  Future<List<Transaction>> getSettledRecoveries() async {
    final query = select(transactions)
      ..where((t) =>
          t.isFullySettled.equals(true) &
          (t.isSplit.equals(true) | t.isDebt.equals(true)))
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    return query.get();
  }
}
