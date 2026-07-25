with open('finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('Future<DateTime?> _showMonthYearPicker')
if idx != -1:
    old_func = content[idx:]
    
    new_func = """Future<DateTime?> _showMonthYearPicker(
  BuildContext context,
  DateTime initialDate,
) async {
  DateTime selected = initialDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  Text('Select Month', style: AppTypography.titleMedium),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 250,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: initialDate,
                onDateTimeChanged: (DateTime newDate) {
                  selected = newDate;
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}"""

    content = content.replace(old_func, new_func)

    if 'package:flutter/cupertino.dart' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter/cupertino.dart';")

    with open('finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
