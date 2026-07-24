import os

files = [
    r"c:\Coding\Expense Tracker\finara\lib\features\settings\presentation\screens\settings_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\search\presentation\screens\search_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\dashboard\presentation\widgets\credit_card_reminders_card.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\transactions\presentation\screens\add_transaction_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\transactions\presentation\screens\transactions_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\categories\presentation\screens\categories_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\dashboard\presentation\screens\dashboard_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\budgets\presentation\screens\budgets_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\backup\presentation\screens\backup_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\accounts\presentation\screens\accounts_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\analytics\presentation\screens\analytics_screen.dart",
    r"c:\Coding\Expense Tracker\finara\lib\features\accounts\presentation\screens\add_account_screen.dart"
]

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    new_imports = set()
    
    if "themeMode" in content:
        new_imports.add("import 'package:finara/features/settings/data/theme_provider.dart';")
    if "hideOnlyTotalBalance" in content:
        new_imports.add("import 'package:finara/features/settings/data/privacy_provider.dart';")
    if "accountsDao" in content:
        new_imports.add("import 'package:finara/features/accounts/data/accounts_provider.dart';")
    if "budgetsDao" in content:
        new_imports.add("import 'package:finara/features/budgets/data/budgets_provider.dart';")
    if "categoriesDao" in content:
        new_imports.add("import 'package:finara/features/categories/data/categories_provider.dart';")
    if "transactionsDao" in content:
        new_imports.add("import 'package:finara/features/transactions/data/transactions_provider.dart';")
    if "notificationService" in content:
        new_imports.add("import 'package:finara/core/services/notification_service.dart';")

    content = content.replace("themeModeProvider", "themeModeNotifierProvider")
    content = content.replace("hideOnlyTotalBalanceProvider", "hideOnlyTotalBalanceNotifierProvider")
    
    lines = content.split('\n')
    out_lines = []
    added = False
    for line in lines:
        if "core/providers/providers.dart" in line:
            if not added:
                out_lines.extend(list(new_imports))
                added = True
        else:
            out_lines.append(line)
            
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(out_lines))

print("Done")
