/// Drift database definition for Finara.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/accounts_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/transactions_dao.dart';
import 'daos/budgets_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, Budgets, CreditCardBills],
  daos: [AccountsDao, CategoriesDao, TransactionsDao, BudgetsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Accounts
            await m.addColumn(accounts, accounts.creditLimit);
            await m.addColumn(accounts, accounts.billGenerationDay);
            await m.addColumn(accounts, accounts.dueDay);
            await m.addColumn(accounts, accounts.loanOriginalPrincipal);
            await m.addColumn(accounts, accounts.loanInterestRate);
            
            // Transactions
            await m.addColumn(transactions, transactions.isSplit);
            await m.addColumn(transactions, transactions.splitPeople);
            await m.addColumn(transactions, transactions.userShareAmount);
            await m.addColumn(transactions, transactions.itemizedListJson);
            
            // Budgets
            await m.addColumn(budgets, budgets.effectiveFromMonth);
            await m.addColumn(budgets, budgets.effectiveFromYear);
            await m.addColumn(budgets, budgets.effectiveToMonth);
            await m.addColumn(budgets, budgets.effectiveToYear);
            
            // We changed month/year to be nullable, so we must alter the table
            await m.alterTable(TableMigration(budgets));
          }
          if (from < 3) {
            await m.createTable(creditCardBills);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finara.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
