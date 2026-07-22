/// Backup & Restore screen — CSV export/import.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/transactions_dao.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/providers/providers.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Export section
          _SectionCard(
            isDark: isDark,
            icon: Icons.upload_outlined,
            title: 'Export Data',
            subtitle: 'Save all records as a CSV file',
            buttonLabel: 'Export CSV',
            buttonIcon: Icons.save_alt,
            onPressed: () => _exportCsv(context, ref),
          ),
          const SizedBox(height: 16),

          // Import section
          _SectionCard(
            isDark: isDark,
            icon: Icons.download_outlined,
            title: 'Import Data',
            subtitle:
                'Restore from a CSV file (MyMoney format supported)',
            buttonLabel: 'Import CSV',
            buttonIcon: Icons.file_open,
            onPressed: () => _importCsv(context, ref),
          ),
          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentViolet.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.accentViolet.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.accentViolet, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'CSV exports include: Time, Type, Amount, Category, Account, and Notes. Compatible with MyMoney backup format.',
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final dao = ref.read(transactionsDaoProvider);
      final categoriesDao = ref.read(categoriesDaoProvider);
      final accountsDao = ref.read(accountsDaoProvider);

      final transactions =
          await dao.watchAllTransactionsWithDetails().first;
      final dateFormat = DateFormat('MMM dd, yyyy h:mm a');

      final buffer = StringBuffer();
      buffer.writeln('"TIME","TYPE","AMOUNT","CATEGORY","ACCOUNT","NOTES"');

      for (final txn in transactions) {
        final t = txn.transaction;
        final time = dateFormat.format(t.date);
        final type = switch (t.type) {
          'income' => '(+) Income',
          'expense' => '(-) Expense',
          'transfer' => '(*) Transfer',
          _ => t.type,
        };
        final amount = t.amount.toStringAsFixed(2);
        final category = t.type == 'transfer'
            ? '  -  '
            : (txn.categoryName ?? 'Uncategorized');
        final account = t.type == 'transfer'
            ? '${txn.accountName}->${txn.toAccountName ?? '?'}'
            : txn.accountName;
        final notes = _escapeCsv(t.note);

        buffer.writeln(
            '"$time","$type","$amount","$category","$account","$notes"');
      }

      final dir = await getApplicationDocumentsDirectory();
      final now = DateFormat('dd_MM_yy_Hmm').format(DateTime.now());
      final file = File('${dir.path}/finara_export_$now.csv');
      await file.writeAsString(buffer.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${transactions.length} records to ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    // TODO: Implement file picker and CSV import
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV import coming soon — file picker integration needed'),
        ),
      );
    }
  }

  String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  const _SectionCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentViolet, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.headlineSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
