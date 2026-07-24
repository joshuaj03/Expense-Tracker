#!/usr/bin/env python3
"""
Convert decrypted MyMoney backup JSON into a Dart seed file that Finara can execute
to populate its Drift database with all historical data.

MyMoney type mapping:
  - type 1 = Income
  - type 2 = Expense
  - type 3 = Transfer (has transferFrom/transferTo instead of account/category)

Category type mapping:
  - type 1 = Income
  - type 2 = Expense
"""
import json
import datetime
import os

INPUT = 'sample_backup/MyMoneyBackup_24_07_26_130.mbak.decrypted.json'
OUTPUT = 'finara/lib/core/database/mymoney_import_data.dart'

# MyMoney icon ID -> emoji mapping (best-effort for known categories)
CATEGORY_EMOJI = {
    'Awards': '🏆', 'Baby': '👶', 'Balance change': '🔄', 'Beauty': '💅',
    'Bills': '💡', 'Car': '🚗', 'Chennai Home': '🏠', 'Clothing': '👗',
    'Coupons': '🎟️', 'Debt': '💸', 'Drinks': '🍺', 'Education': '📚',
    'Electronics': '📱', 'Entertainment': '🎬', 'Food': '🍽️', 'Grants': '💰',
    'Grocery': '🛒', 'Health': '🏥', 'Home': '🏠', 'Insurance': '🛡️',
    'Loan': '🏦', 'Long Travel': '✈️', 'Lottery': '🎰', 'Maintanence': '🔧',
    'Misc': '📌', 'Official': '💼', 'Project': '📊', 'Refunds': '↩️',
    'Rent': '🏠', 'Rental': '🏠', 'Salary': '💰', 'Sale': '🏷️',
    'Shopping': '🛍️', 'Social': '👥', 'Sport': '⚽', 'Subscriptions': '📺',
    'Tax': '🧾', 'Telephone': '📞', 'Transportation': '🚌', 'Trip': '🧳',
}

ACCOUNT_EMOJI = {
    'Amazon Pay ICICI Credit Card': '💳',
    'Cash': '💵',
    'Debt': '💸',
    'Emergency Fund': '🏦',
    'FedBank Card': '💳',
    "Nimmy's Treat": '🎁',
    'Savings - APay Wallet': '👛',
    'Stocks': '📈',
    'UPI - BOB': '📱',
}

ACCOUNT_TYPE = {
    'Amazon Pay ICICI Credit Card': 'creditCard',
    'Cash': 'cash',
    'Debt': 'bank',
    'Emergency Fund': 'bank',
    'FedBank Card': 'bank',
    "Nimmy's Treat": 'wallet',
    'Savings - APay Wallet': 'wallet',
    'Stocks': 'investment',
    'UPI - BOB': 'upi',
}

# Category color palette
CATEGORY_COLORS = [
    0xFFFF6B6B, 0xFFFF8E53, 0xFF4ECDC4, 0xFFE040FB, 0xFFAB47BC,
    0xFFFFB74D, 0xFF66BB6A, 0xFF42A5F5, 0xFF78909C, 0xFFEC407A,
    0xFFBA68C8, 0xFF26C6DA, 0xFF7E57C2, 0xFFEF5350, 0xFF5C6BC0,
    0xFF8D6E63, 0xFFFF7043, 0xFF26A69A, 0xFFD4E157, 0xFF29B6F6,
    0xFFFFA726, 0xFF66BB6A, 0xFF42A5F5, 0xFF78909C, 0xFFEC407A,
    0xFFBA68C8, 0xFF26C6DA, 0xFF7E57C2, 0xFFEF5350, 0xFF5C6BC0,
    0xFF8D6E63, 0xFFFF7043, 0xFF26A69A, 0xFFD4E157, 0xFF29B6F6,
    0xFFFFA726, 0xFF66BB6A, 0xFF42A5F5, 0xFF78909C, 0xFFEC407A,
    0xFFBA68C8, 0xFF26C6DA,
]


def escape_dart_string(s: str) -> str:
    """Escape a string for use in a Dart single-quoted string literal."""
    return s.replace('\\', '\\\\').replace('$', '\\$').replace("'", "\\'").replace('\n', '\\n').replace('\r', '')


def ms_to_dart_datetime(ms: int) -> str:
    """Convert millisecond timestamp to Dart DateTime constructor."""
    dt = datetime.datetime.fromtimestamp(ms / 1000)
    return f'DateTime({dt.year}, {dt.month}, {dt.day}, {dt.hour}, {dt.minute}, {dt.second})'


def main():
    with open(INPUT, 'r', encoding='utf-8') as f:
        data = json.load(f)

    accounts = data['accounts']
    categories = data['categories']
    records = data['records']
    budgets = data['budgets']

    # Build ID -> index maps (Finara uses auto-increment, so we remap IDs)
    # We'll use the MyMoney ID as a key and assign sequential Finara IDs
    account_id_map = {}  # myMoney ID -> finara sequential index (1-based)
    category_id_map = {}  # myMoney ID -> finara sequential index (1-based)

    # Sort accounts by name for consistency
    accounts.sort(key=lambda a: a['name'])
    for i, acct in enumerate(accounts):
        account_id_map[acct['id']] = i + 1  # 1-based

    # Sort categories: income first, then expense, alphabetical within
    categories.sort(key=lambda c: (c['type'], c['name']))
    for i, cat in enumerate(categories):
        category_id_map[cat['id']] = i + 1  # 1-based

    # Sort records by time ascending
    records.sort(key=lambda r: r['time'])

    lines = []
    lines.append("/// AUTO-GENERATED: MyMoney backup import data.")
    lines.append("/// Source: MyMoneyBackup_24_07_26_130.mbak")
    lines.append(f"/// Generated: {datetime.datetime.now().isoformat()}")
    lines.append(f"/// Accounts: {len(accounts)}, Categories: {len(categories)}, Records: {len(records)}, Budgets: {len(budgets)}")
    lines.append("library;")
    lines.append("")
    lines.append("import 'package:drift/drift.dart';")
    lines.append("import 'app_database.dart';")
    lines.append("import '../../core/utils/logger.dart';")
    lines.append("")

    # --- ACCOUNTS ---
    lines.append("/// All MyMoney accounts as Drift companions.")
    lines.append("List<AccountsCompanion> get myMoneyAccounts => [")
    for i, acct in enumerate(accounts):
        name = escape_dart_string(acct['name'])
        icon = ACCOUNT_EMOJI.get(acct['name'], '💰')
        acct_type = ACCOUNT_TYPE.get(acct['name'], 'bank')
        initial = acct.get('initial', 0.0)
        current = acct.get('amount', 0.0)
        lines.append(f"  AccountsCompanion.insert(")
        lines.append(f"    name: '{name}',")
        lines.append(f"    type: '{acct_type}',")
        lines.append(f"    icon: const Value('{icon}'),")
        lines.append(f"    color: const Value(0xFF6C63FF),")
        lines.append(f"    initialBalance: const Value({initial}),")
        lines.append(f"    currentBalance: Value({current}),")
        lines.append(f"    createdAt: Value(DateTime(2024, 8, 1)),")
        lines.append(f"  ),")
    lines.append("];")
    lines.append("")

    # --- CATEGORIES ---
    lines.append("/// All MyMoney categories as Drift companions.")
    lines.append("List<CategoriesCompanion> get myMoneyCategories => [")
    for i, cat in enumerate(categories):
        name = escape_dart_string(cat['name'])
        cat_type = 'income' if cat['type'] == 1 else 'expense'
        icon = CATEGORY_EMOJI.get(cat['name'], '📌')
        color = CATEGORY_COLORS[i % len(CATEGORY_COLORS)]
        lines.append(f"  CategoriesCompanion.insert(")
        lines.append(f"    name: '{name}',")
        lines.append(f"    type: '{cat_type}',")
        lines.append(f"    icon: const Value('{icon}'),")
        lines.append(f"    color: const Value({hex(color)}),")
        lines.append(f"    sortOrder: const Value({i}),")
        lines.append(f"  ),")
    lines.append("];")
    lines.append("")

    # --- Helper: MyMoney ID -> Finara sequential ID maps ---
    lines.append("/// MyMoney account ID -> Finara sequential ID (1-based).")
    lines.append("const Map<int, int> _accountIdMap = {")
    for mm_id, finara_id in account_id_map.items():
        lines.append(f"  {mm_id}: {finara_id},")
    lines.append("};")
    lines.append("")
    lines.append("/// MyMoney category ID -> Finara sequential ID (1-based).")
    lines.append("const Map<int, int> _categoryIdMap = {")
    for mm_id, finara_id in category_id_map.items():
        lines.append(f"  {mm_id}: {finara_id},")
    lines.append("};")
    lines.append("")

    # --- RECORDS ---
    lines.append("/// All MyMoney transaction records as Drift companions.")
    lines.append("/// Type mapping: 1=income, 2=expense, 3=transfer.")
    lines.append("List<TransactionsCompanion> get myMoneyRecords => [")
    for rec in records:
        rec_type = rec['type']
        amount = rec['amount']
        note = escape_dart_string(rec.get('note', ''))
        time_str = ms_to_dart_datetime(rec['time'])

        if rec_type == 3:
            # Transfer
            from_acct = rec.get('transferFrom', {})
            to_acct = rec.get('transferTo', {})
            from_id = account_id_map.get(from_acct.get('id'), 1)
            to_id = account_id_map.get(to_acct.get('id'), 1)
            lines.append(f"  TransactionsCompanion.insert(")
            lines.append(f"    type: 'transfer',")
            lines.append(f"    amount: {amount},")
            lines.append(f"    date: {time_str},")
            lines.append(f"    accountId: {from_id},")
            lines.append(f"    toAccountId: Value({to_id}),")
            lines.append(f"    note: const Value('{note}'),")
            lines.append(f"    isExcludedFromAnalytics: const Value(true),")
            lines.append(f"  ),")
        else:
            # Income or Expense
            dart_type = 'income' if rec_type == 1 else 'expense'
            acct = rec.get('account', {})
            cat = rec.get('category', {})
            acct_id = account_id_map.get(acct.get('id'), 1)
            cat_id = category_id_map.get(cat.get('id'))
            lines.append(f"  TransactionsCompanion.insert(")
            lines.append(f"    type: '{dart_type}',")
            lines.append(f"    amount: {amount},")
            lines.append(f"    date: {time_str},")
            lines.append(f"    accountId: {acct_id},")
            if cat_id is not None:
                lines.append(f"    categoryId: const Value({cat_id}),")
            lines.append(f"    note: const Value('{note}'),")
            lines.append(f"  ),")
    lines.append("];")
    lines.append("")

    # --- BUDGETS ---
    lines.append("/// All MyMoney budget entries as Drift companions.")
    lines.append("List<BudgetsCompanion> get myMoneyBudgets => [")
    for b in budgets:
        cat = b.get('category', {})
        cat_id = category_id_map.get(cat.get('id'))
        if cat_id is None:
            continue
        limit_amount = b['limit']
        dt = datetime.datetime.fromtimestamp(b['time'] / 1000)
        month = dt.month
        year = dt.year
        lines.append(f"  BudgetsCompanion.insert(")
        lines.append(f"    categoryId: {cat_id},")
        lines.append(f"    limitAmount: {limit_amount},")
        lines.append(f"    month: Value({month}),")
        lines.append(f"    year: Value({year}),")
        lines.append(f"  ),")
    lines.append("];")
    lines.append("")

    # --- IMPORT FUNCTION ---
    lines.append("/// Import all MyMoney data into Finara's database.")
    lines.append("/// This replaces the default seed and populates real user data.")
    lines.append("Future<void> importMyMoneyData(AppDatabase db) async {")
    lines.append("  final log = AppLogger.instance;")
    lines.append("  log.backup('MyMoney import started');")
    lines.append("")
    lines.append("  // Check if already imported")
    lines.append("  final existingAccounts = await db.accountsDao.getAllAccounts();")
    lines.append(f"  if (existingAccounts.length >= {len(accounts)}) {{")
    lines.append("    log.backup('MyMoney data already imported (${existingAccounts.length} accounts exist), skipping');")
    lines.append("    return;")
    lines.append("  }")
    lines.append("")
    lines.append("  try {")
    lines.append("    // 1. Clear existing seed data")
    lines.append("    log.backup('Clearing existing seed data...');")
    lines.append("    await db.delete(db.transactions).go();")
    lines.append("    await db.delete(db.budgets).go();")
    lines.append("    await db.delete(db.categories).go();")
    lines.append("    await db.delete(db.accounts).go();")
    lines.append("")
    lines.append("    // 2. Insert accounts")
    lines.append("    for (final acct in myMoneyAccounts) {")
    lines.append("      await db.into(db.accounts).insert(acct);")
    lines.append("    }")
    lines.append("    log.backup('Imported ${myMoneyAccounts.length} accounts');")
    lines.append("")
    lines.append("    // 3. Insert categories")
    lines.append("    for (final cat in myMoneyCategories) {")
    lines.append("      await db.into(db.categories).insert(cat);")
    lines.append("    }")
    lines.append("    log.backup('Imported ${myMoneyCategories.length} categories');")
    lines.append("")
    lines.append("    // 4. Insert records")
    lines.append("    int count = 0;")
    lines.append("    for (final rec in myMoneyRecords) {")
    lines.append("      await db.into(db.transactions).insert(rec);")
    lines.append("      count++;")
    lines.append("    }")
    lines.append("    log.backup('Imported $count transaction records');")
    lines.append("")
    lines.append("    // 5. Insert budgets")
    lines.append("    for (final b in myMoneyBudgets) {")
    lines.append("      await db.into(db.budgets).insert(b);")
    lines.append("    }")
    lines.append("    log.backup('Imported ${myMoneyBudgets.length} budgets');")
    lines.append("")
    lines.append("    log.backup('MyMoney import completed successfully!');")
    lines.append("  } catch (e, st) {")
    lines.append("    log.error('MyMoney import failed', e, st);")
    lines.append("    rethrow;")
    lines.append("  }")
    lines.append("}")

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    print(f"Generated {OUTPUT}")
    print(f"  Accounts: {len(accounts)}")
    print(f"  Categories: {len(categories)}")
    print(f"  Records: {len(records)}")
    print(f"  Budgets: {len(budgets)}")


if __name__ == '__main__':
    main()
