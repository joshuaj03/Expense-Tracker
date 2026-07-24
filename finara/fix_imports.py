import os

replacements = {
    "'../../../../core/database/daos/transactions_dao.dart'": "'package:finara/features/transactions/data/transactions_dao.dart'",
    "'../../../../core/database/daos/budgets_dao.dart'": "'package:finara/features/budgets/data/budgets_dao.dart'",
    "'../../../../core/database/daos/accounts_dao.dart'": "'package:finara/features/accounts/data/accounts_dao.dart'",
    "'../../../../core/database/daos/categories_dao.dart'": "'package:finara/features/categories/data/categories_dao.dart'",
    "itemBuilder: (context) => const [": "itemBuilder: (context) => [",
    "const PopupMenuItem": "const PopupMenuItem"
}

for root, _, files in os.walk('c:/Coding/Expense Tracker/finara/lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            original = content
            for old, new in replacements.items():
                content = content.replace(old, new)
            if content != original:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f'Updated {filepath}')
