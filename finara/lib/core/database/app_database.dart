/// Drift database definition for Finara.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import '../../features/accounts/data/accounts_dao.dart';
import '../../features/categories/data/categories_dao.dart';
import '../../features/transactions/data/transactions_dao.dart';
import '../../features/budgets/data/budgets_dao.dart';
import 'mymoney_import_data.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, Budgets, CreditCardBills],
  daos: [AccountsDao, CategoriesDao, TransactionsDao, BudgetsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

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
      if (from < 4) {
        await m.addColumn(accounts, accounts.isIgnored);
        await m.addColumn(creditCardBills, creditCardBills.billAmount);
      }
      if (from < 5) {
        await m.addColumn(transactions, transactions.settledAmount);
        await m.addColumn(transactions, transactions.isFullySettled);
        await m.addColumn(transactions, transactions.isDebt);
        await m.addColumn(transactions, transactions.settlementForTxnId);
      }
    },
  );

  /// Clears all data from all tables. Use with caution.
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(creditCardBills).go();
      await delete(budgets).go();
      await delete(categories).go();
      await delete(accounts).go();

      // Seed defaults
      await batch((batch) {
        batch.insertAll(accounts, [
          AccountsCompanion.insert(
            name: 'Cash',
            type: 'cash',
            icon: const Value('💵'),
            color: const Value(0xFF6C63FF),
          ),
          AccountsCompanion.insert(
            name: 'Card',
            type: 'bank',
            icon: const Value('💳'),
            color: const Value(0xFF26C6DA),
          ),
          AccountsCompanion.insert(
            name: 'Savings',
            type: 'bank',
            icon: const Value('🏦'),
            color: const Value(0xFF66BB6A),
          ),
        ]);
        batch.insertAll(categories, [
          // Income
          CategoriesCompanion.insert(name: 'Cashbacks', type: 'income', icon: const Value('💸'), color: const Value(0xFF4CAF50), sortOrder: const Value(0)),
          CategoriesCompanion.insert(name: 'Awards', type: 'income', icon: const Value('🏆'), color: const Value(0xFFFFD700), sortOrder: const Value(1)),
          CategoriesCompanion.insert(name: 'Balance Change', type: 'income', icon: const Value('🔄'), color: const Value(0xFF81C784), sortOrder: const Value(2)),
          CategoriesCompanion.insert(name: 'Coupons', type: 'income', icon: const Value('🎟️'), color: const Value(0xFFFFB74D), sortOrder: const Value(3)),
          CategoriesCompanion.insert(name: 'Grants', type: 'income', icon: const Value('📜'), color: const Value(0xFF64B5F6), sortOrder: const Value(4)),
          CategoriesCompanion.insert(name: 'Loan', type: 'income', icon: const Value('🏦'), color: const Value(0xFFE57373), sortOrder: const Value(5)),
          CategoriesCompanion.insert(name: 'Refunds', type: 'income', icon: const Value('↩️'), color: const Value(0xFF4DD0E1), sortOrder: const Value(6)),
          CategoriesCompanion.insert(name: 'Rental', type: 'income', icon: const Value('🏠'), color: const Value(0xFF7986CB), sortOrder: const Value(7)),
          CategoriesCompanion.insert(name: 'Salary', type: 'income', icon: const Value('💰'), color: const Value(0xFF81C784), sortOrder: const Value(8)),
          CategoriesCompanion.insert(name: 'Sale', type: 'income', icon: const Value('🏷️'), color: const Value(0xFFBA68C8), sortOrder: const Value(9)),
          // Expenses
          CategoriesCompanion.insert(name: 'Baby', type: 'expense', icon: const Value('👶'), color: const Value(0xFFF48FB1), sortOrder: const Value(10)),
          CategoriesCompanion.insert(name: 'Beauty', type: 'expense', icon: const Value('💅'), color: const Value(0xFFCE93D8), sortOrder: const Value(11)),
          CategoriesCompanion.insert(name: 'Bills', type: 'expense', icon: const Value('🧾'), color: const Value(0xFFEF9A9A), sortOrder: const Value(12)),
          CategoriesCompanion.insert(name: 'Car', type: 'expense', icon: const Value('🚗'), color: const Value(0xFF90CAF9), sortOrder: const Value(13)),
          CategoriesCompanion.insert(name: 'Home', type: 'expense', icon: const Value('🏠'), color: const Value(0xFFAED581), sortOrder: const Value(14)),
          CategoriesCompanion.insert(name: 'Clothing', type: 'expense', icon: const Value('👕'), color: const Value(0xFFFFCC80), sortOrder: const Value(15)),
          CategoriesCompanion.insert(name: 'Debt', type: 'expense', icon: const Value('💳'), color: const Value(0xFFE57373), sortOrder: const Value(16)),
          CategoriesCompanion.insert(name: 'Drinks', type: 'expense', icon: const Value('🍹'), color: const Value(0xFFFFAB91), sortOrder: const Value(17)),
          CategoriesCompanion.insert(name: 'Education', type: 'expense', icon: const Value('🎓'), color: const Value(0xFF64B5F6), sortOrder: const Value(18)),
          CategoriesCompanion.insert(name: 'Electronics', type: 'expense', icon: const Value('💻'), color: const Value(0xFF9E9E9E), sortOrder: const Value(19)),
          CategoriesCompanion.insert(name: 'Entertainment', type: 'expense', icon: const Value('🍿'), color: const Value(0xFFBA68C8), sortOrder: const Value(20)),
          CategoriesCompanion.insert(name: 'Food', type: 'expense', icon: const Value('🍔'), color: const Value(0xFFFFB74D), sortOrder: const Value(21)),
          CategoriesCompanion.insert(name: 'Grocery', type: 'expense', icon: const Value('🛒'), color: const Value(0xFF81C784), sortOrder: const Value(22)),
          CategoriesCompanion.insert(name: 'Health', type: 'expense', icon: const Value('🏥'), color: const Value(0xFFF06292), sortOrder: const Value(23)),
          CategoriesCompanion.insert(name: 'Insurance', type: 'expense', icon: const Value('🛡️'), color: const Value(0xFF4FC3F7), sortOrder: const Value(24)),
          CategoriesCompanion.insert(name: 'Travel', type: 'expense', icon: const Value('✈️'), color: const Value(0xFF4DD0E1), sortOrder: const Value(25)),
          CategoriesCompanion.insert(name: 'Trip', type: 'expense', icon: const Value('🧳'), color: const Value(0xFF81C784), sortOrder: const Value(26)),
          CategoriesCompanion.insert(name: 'Transportation', type: 'expense', icon: const Value('🚌'), color: const Value(0xFFFFD54F), sortOrder: const Value(27)),
          CategoriesCompanion.insert(name: 'Subscription', type: 'expense', icon: const Value('📅'), color: const Value(0xFF9575CD), sortOrder: const Value(28)),
          CategoriesCompanion.insert(name: 'Maintenance', type: 'expense', icon: const Value('🔧'), color: const Value(0xFFBCAAA4), sortOrder: const Value(29)),
          CategoriesCompanion.insert(name: 'Misc', type: 'expense', icon: const Value('📌'), color: const Value(0xFF90A4AE), sortOrder: const Value(30)),
          CategoriesCompanion.insert(name: 'Rent', type: 'expense', icon: const Value('🏠'), color: const Value(0xFFFF8A65), sortOrder: const Value(31)),
          CategoriesCompanion.insert(name: 'Project', type: 'expense', icon: const Value('🚧'), color: const Value(0xFF4DB6AC), sortOrder: const Value(32)),
          CategoriesCompanion.insert(name: 'Shopping', type: 'expense', icon: const Value('🛍️'), color: const Value(0xFFF48FB1), sortOrder: const Value(33)),
          CategoriesCompanion.insert(name: 'Official', type: 'expense', icon: const Value('💼'), color: const Value(0xFF7986CB), sortOrder: const Value(34)),
          CategoriesCompanion.insert(name: 'Social', type: 'expense', icon: const Value('🎉'), color: const Value(0xFFFFD54F), sortOrder: const Value(35)),
          CategoriesCompanion.insert(name: 'Sport', type: 'expense', icon: const Value('⚽'), color: const Value(0xFF81C784), sortOrder: const Value(36)),
          CategoriesCompanion.insert(name: 'Tax', type: 'expense', icon: const Value('🏛️'), color: const Value(0xFFE57373), sortOrder: const Value(37)),
          CategoriesCompanion.insert(name: 'Telephone', type: 'expense', icon: const Value('📱'), color: const Value(0xFF4FC3F7), sortOrder: const Value(38)),
        ]);
      });
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finara.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
