import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

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

  /// Watch all transactions with their details, ordered by date descending.
  Stream<List<TransactionWithDetails>> watchAllTransactionsWithDetails({
    int? limit,
    int? accountId,
  }) {
    final toAccount = alias(accounts, 'toAcc');
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
          toAccount, toAccount.id.equalsExp(transactions.toAccountId)),
      leftOuterJoin(
          categories, categories.id.equalsExp(transactions.categoryId)),
    ]);

    query.orderBy([OrderingTerm.desc(transactions.date)]);

    if (accountId != null) {
      query.where(transactions.accountId.equals(accountId) |
          transactions.toAccountId.equals(accountId));
    }
    if (limit != null) {
      query.limit(limit);
    }

    return query.watch().map((rows) => rows.map((row) {
          return TransactionWithDetails(
            transaction: row.readTable(transactions),
            accountName: row.readTable(accounts).name,
            toAccountName: row.readTableOrNull(toAccount)?.name,
            categoryName: row.readTableOrNull(categories)?.name,
            categoryIcon: row.readTableOrNull(categories)?.icon,
            categoryColor: row.readTableOrNull(categories)?.color,
          );
        }).toList());
  }

  /// Watch transactions for a specific month (for analytics).
  Stream<List<TransactionWithDetails>> watchTransactionsForMonth(
      int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final toAccount = alias(accounts, 'toAcc');
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
          toAccount, toAccount.id.equalsExp(transactions.toAccountId)),
      leftOuterJoin(
          categories, categories.id.equalsExp(transactions.categoryId)),
    ]);

    query.where(transactions.date.isBetweenValues(startDate, endDate));
    query.orderBy([OrderingTerm.desc(transactions.date)]);

    return query.watch().map((rows) => rows.map((row) {
          return TransactionWithDetails(
            transaction: row.readTable(transactions),
            accountName: row.readTable(accounts).name,
            toAccountName: row.readTableOrNull(toAccount)?.name,
            categoryName: row.readTableOrNull(categories)?.name,
            categoryIcon: row.readTableOrNull(categories)?.icon,
            categoryColor: row.readTableOrNull(categories)?.color,
          );
        }).toList());
  }

  /// Insert a new transaction.
  Future<int> insertTransaction(TransactionsCompanion transaction) {
    return into(transactions).insert(transaction);
  }

  /// Update an existing transaction.
  Future<bool> updateTransaction(int id, TransactionsCompanion transaction) {
    return (update(transactions)..where((t) => t.id.equals(id)))
        .write(transaction)
        .then((rows) => rows > 0);
  }

  /// Get a transaction by ID.
  Future<Transaction?> getTransactionById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new transaction and update account balances.
  Future<int> insertTransactionWithBalance(TransactionsCompanion txn) async {
    final id = await into(transactions).insert(txn);

    // Update account balance
    final amount = txn.amount.value;
    final type = txn.type.value;
    final accId = txn.accountId.value;

    final account = await (select(accounts)
          ..where((a) => a.id.equals(accId)))
        .getSingle();

    double newBalance = account.currentBalance;
    if (type == 'income') {
      newBalance += amount;
    } else if (type == 'expense') {
      newBalance -= amount;
    } else if (type == 'transfer') {
      newBalance -= amount;
      // Update destination account
      if (txn.toAccountId.present && txn.toAccountId.value != null) {
        final toAcc = await (select(accounts)
              ..where((a) => a.id.equals(txn.toAccountId.value!)))
            .getSingle();
        await (update(accounts)
              ..where((a) => a.id.equals(txn.toAccountId.value!)))
            .write(AccountsCompanion(
                currentBalance: Value(toAcc.currentBalance + amount)));
      }
    }

    await (update(accounts)..where((a) => a.id.equals(accId)))
        .write(AccountsCompanion(currentBalance: Value(newBalance)));

    return id;
  }

  /// Delete a transaction and reverse the balance change.
  Future<void> deleteTransaction(int txnId) async {
    final txn = await (select(transactions)
          ..where((t) => t.id.equals(txnId)))
        .getSingleOrNull();
    if (txn == null) return;

    final account = await (select(accounts)
          ..where((a) => a.id.equals(txn.accountId)))
        .getSingle();

    double newBalance = account.currentBalance;
    if (txn.type == 'income') {
      newBalance -= txn.amount;
    } else if (txn.type == 'expense') {
      newBalance += txn.amount;
    } else if (txn.type == 'transfer') {
      newBalance += txn.amount;
      if (txn.toAccountId != null) {
        final toAcc = await (select(accounts)
              ..where((a) => a.id.equals(txn.toAccountId!)))
            .getSingle();
        await (update(accounts)
              ..where((a) => a.id.equals(txn.toAccountId!)))
            .write(AccountsCompanion(
                currentBalance: Value(toAcc.currentBalance - txn.amount)));
      }
    }

    await (update(accounts)..where((a) => a.id.equals(txn.accountId)))
        .write(AccountsCompanion(currentBalance: Value(newBalance)));

    await (delete(transactions)..where((t) => t.id.equals(txnId))).go();
  }

  /// Search transactions by note text.
  Stream<List<TransactionWithDetails>> searchTransactions(String query) {
    final toAccount = alias(accounts, 'toAcc');
    final q = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
      leftOuterJoin(
          toAccount, toAccount.id.equalsExp(transactions.toAccountId)),
      leftOuterJoin(
          categories, categories.id.equalsExp(transactions.categoryId)),
    ]);

    q.where(transactions.note.like('%$query%') |
        categories.name.like('%$query%') |
        accounts.name.like('%$query%'));
    q.orderBy([OrderingTerm.desc(transactions.date)]);

    return q.watch().map((rows) => rows.map((row) {
          return TransactionWithDetails(
            transaction: row.readTable(transactions),
            accountName: row.readTable(accounts).name,
            toAccountName: row.readTableOrNull(toAccount)?.name,
            categoryName: row.readTableOrNull(categories)?.name,
            categoryIcon: row.readTableOrNull(categories)?.icon,
            categoryColor: row.readTableOrNull(categories)?.color,
          );
        }).toList());
  }

  /// Get income and expense totals for a month (excluding transfers/excluded).
  Stream<({double income, double expense})> watchMonthlyTotals(
      int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return (select(transactions)
          ..where((t) =>
              t.date.isBetweenValues(startDate, endDate) &
              t.isExcludedFromAnalytics.equals(false)))
        .watch()
        .map((txns) {
      double income = 0;
      double expense = 0;
      for (final t in txns) {
        if (t.type == 'income') {
          income += t.amount;
        } else if (t.type == 'expense') {
          expense += t.amount;
        }
      }
      return (income: income, expense: expense);
    });
  }

  /// Get spending by category for a month (expenses only, analytics-eligible).
  Stream<Map<int, double>> watchCategorySpending(int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return (select(transactions)
          ..where((t) =>
              t.date.isBetweenValues(startDate, endDate) &
              t.type.equals('expense') &
              t.isExcludedFromAnalytics.equals(false)))
        .watch()
        .map((txns) {
      final map = <int, double>{};
      for (final t in txns) {
        if (t.categoryId != null) {
          map[t.categoryId!] = (map[t.categoryId!] ?? 0) + t.amount;
        }
      }
      return map;
    });
  }

  /// Get monthly totals for the last N months (for bar chart).
  Future<List<({int year, int month, double income, double expense})>>
      getMonthlyTrend(int months) async {
    final now = DateTime.now();
    final results =
        <({int year, int month, double income, double expense})>[];

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

      final txns = await (select(transactions)
            ..where((t) =>
                t.date.isBetweenValues(date, endDate) &
                t.isExcludedFromAnalytics.equals(false)))
          .get();

      double income = 0;
      double expense = 0;
      for (final t in txns) {
        if (t.type == 'income') income += t.amount;
        if (t.type == 'expense') expense += t.amount;
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
}
