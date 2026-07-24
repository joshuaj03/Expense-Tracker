import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../accounts/data/accounts_dao.dart';
import '../../accounts/data/accounts_provider.dart';
import '../../budgets/data/budgets_provider.dart';
import '../../categories/data/categories_dao.dart';
import '../../categories/data/categories_provider.dart';
import '../../transactions/data/transactions_provider.dart';

/// Parses decrypted .mbak JSON and inserts into the Finara database.
class MbakImporter {
  final WidgetRef ref;

  MbakImporter(this.ref);

  Future<int> importData(String jsonString) async {
    final log = AppLogger.instance;
    log.backup('MbakImporter: Parsing JSON data');

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      log.error('MbakImporter: Failed to parse JSON', e);
      throw const FormatException('Invalid JSON data in backup file.');
    }

    final accounts = data['accounts'] as List<dynamic>? ?? [];
    final categories = data['categories'] as List<dynamic>? ?? [];
    final records = data['records'] as List<dynamic>? ?? [];
    final budgets = data['budgets'] as List<dynamic>? ?? [];

    log.backup(
      'MbakImporter: Found ${accounts.length} accounts, ${categories.length} categories, ${records.length} records, ${budgets.length} budgets',
    );

    final accountsDao = ref.read(accountsDaoProvider);
    final categoriesDao = ref.read(categoriesDaoProvider);
    final transactionsDao = ref.read(transactionsDaoProvider);
    final budgetsDao = ref.read(budgetsDaoProvider);

    // Dictionaries to map MyMoney IDs to Finara Auto-Increment IDs
    final Map<int, int> oldToNewAccountIds = {};
    final Map<int, int> oldToNewCategoryIds = {};

    int importedRecordsCount = 0;

    try {
      // 1. Import Accounts
      for (final acct in accounts) {
        final oldId = acct['id'] as int;
        final name = acct['name']?.toString() ?? 'Unknown Account';
        final initial = (acct['initial'] as num?)?.toDouble() ?? 0.0;
        final current = (acct['amount'] as num?)?.toDouble() ?? 0.0;

        // Use basic icon and type guessing if possible
        String icon = '💰';
        String type = 'bank';
        if (name.toLowerCase().contains('cash')) {
          icon = '💵';
          type = 'cash';
        }
        if (name.toLowerCase().contains('card')) {
          icon = '💳';
          type = 'credit';
        }
        if (name.toLowerCase().contains('bank')) {
          icon = '🏦';
        }

        final newId = await _getOrCreateAccount(
          accountsDao,
          name,
          type,
          icon,
          initial,
          current,
        );
        oldToNewAccountIds[oldId] = newId;
      }

      // 2. Import Categories
      for (final cat in categories) {
        final oldId = cat['id'] as int;
        final name = cat['name']?.toString() ?? 'Unknown Category';
        final typeNum = cat['type'] as int? ?? 0;
        final catType = typeNum == 1 ? 'income' : 'expense';

        final newId = await _getOrCreateCategory(categoriesDao, name, catType);
        oldToNewCategoryIds[oldId] = newId;
      }

      // 3. Import Records (Transactions)
      for (final rec in records) {
        final typeNum = rec['type'] as int? ?? 0;
        final isIncome = typeNum == 1;
        final isTransfer = typeNum == 2;

        String txnType = 'expense';
        if (isIncome) txnType = 'income';
        if (isTransfer) txnType = 'transfer';

        final amount = (rec['amount'] as num?)?.toDouble() ?? 0.0;
        final ms = rec['time'] as int? ?? 0;
        final date = DateTime.fromMillisecondsSinceEpoch(ms);
        final note = rec['note']?.toString() ?? '';

        final oldAccountId =
            (rec['account'] as int?) ?? (rec['account_from'] as int? ?? 0);
        final newAccountId = oldToNewAccountIds[oldAccountId];

        if (newAccountId == null) {
          log.warning(
            'MbakImporter: Skipping transaction due to missing account ID mapping for old ID: $oldAccountId',
          );
          continue;
        }

        int? newToAccountId;
        if (isTransfer) {
          final oldToAccountId = rec['account_to'] as int? ?? 0;
          newToAccountId = oldToNewAccountIds[oldToAccountId];
        }

        int? newCategoryId;
        if (!isTransfer) {
          final oldCategoryId = rec['category'] as int? ?? 0;
          newCategoryId = oldToNewCategoryIds[oldCategoryId];
        }

        await transactionsDao.insertTransaction(
          TransactionsCompanion.insert(
            type: txnType,
            amount: amount,
            date: date,
            accountId: newAccountId,
            toAccountId: Value(newToAccountId),
            categoryId: Value(newCategoryId),
            note: Value(note),
          ),
        );

        importedRecordsCount++;
      }

      // 4. Import Budgets
      final now = DateTime.now();
      for (final bud in budgets) {
        final amount = (bud['amount'] as num?)?.toDouble() ?? 0.0;
        final oldCategoryId = bud['category'] as int? ?? 0;
        final newCategoryId = oldToNewCategoryIds[oldCategoryId];

        if (newCategoryId != null) {
          // Verify budget doesn't already exist for this category
          final existing = await budgetsDao.getBudget(
            newCategoryId,
            now.year,
            now.month,
          );

          if (existing == null) {
            await budgetsDao.upsertBudget(
              BudgetsCompanion.insert(
                categoryId: newCategoryId,
                limitAmount: amount,
                month: Value(now.month),
                year: Value(now.year),
              ),
            );
          }
        }
      }

      log.backup(
        'MbakImporter: Import complete. Inserted $importedRecordsCount transactions.',
      );
      return importedRecordsCount;
    } catch (e, st) {
      log.error('MbakImporter: Error inserting records into database', e, st);
      throw Exception('Failed to insert records into database: $e');
    }
  }

  Future<int> _getOrCreateAccount(
    AccountsDao dao,
    String name,
    String type,
    String icon,
    double initial,
    double current,
  ) async {
    final accounts = await dao.getAllAccounts();
    final existing = accounts
        .where((a) => a.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (existing != null) return existing.id;

    return await dao.insertAccount(
      AccountsCompanion.insert(
        name: name,
        type: type,
        icon: Value(icon),
        color: const Value(0xFF6C63FF),
        initialBalance: Value(initial),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> _getOrCreateCategory(
    CategoriesDao dao,
    String name,
    String type,
  ) async {
    final categories = await dao.getAllCategories();
    final existing = categories
        .where(
          (c) => c.name.toLowerCase() == name.toLowerCase() && c.type == type,
        )
        .firstOrNull;
    if (existing != null) return existing.id;

    return await dao.insertCategory(
      CategoriesCompanion.insert(
        name: name,
        icon: const Value('📌'),
        color: const Value(0xFF6C63FF),
        type: type,
      ),
    );
  }
}
