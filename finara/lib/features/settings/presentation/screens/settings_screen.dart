import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import 'package:finara/features/settings/data/theme_provider.dart';
import 'package:finara/features/settings/data/privacy_provider.dart';
import 'package:finara/features/settings/data/currency_provider.dart';
import 'package:finara/features/settings/data/ui_preferences_provider.dart';
import 'package:finara/core/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // App Info
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'F',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Finara',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personal Finance OS',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v0.1.0 Alpha',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance
          _SectionTitle('Appearance & Config'),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final currency = ref.watch(currencyNotifierProvider);
                  return _SettingsTile(
                    icon: Icons.attach_money_outlined,
                    title: 'Currency',
                    trailing: DropdownButton<String>(
                      value: currency,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: '₹', child: Text('INR (₹)')),
                        DropdownMenuItem(value: '\$', child: Text('USD (\$)')),
                        DropdownMenuItem(value: '€', child: Text('EUR (€)')),
                        DropdownMenuItem(value: '£', child: Text('GBP (£)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(currencyNotifierProvider.notifier)
                              .setCurrency(val);
                        }
                      },
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                trailing: DropdownButton<int>(
                  value: themeMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('System Auto')),
                    DropdownMenuItem(value: 1, child: Text('Dark Mode')),
                    DropdownMenuItem(value: 2, child: Text('Light Mode')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themeModeNotifierProvider.notifier).setMode(val);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              Consumer(
                builder: (context, ref, child) {
                  final hideOnlyTotal = ref.watch(
                    hideOnlyTotalBalanceNotifierProvider,
                  );
                  return _SettingsTile(
                    icon: Icons.visibility_off_outlined,
                    title: 'Hide Only Total',
                    subtitle: 'Show income/expense when hidden',
                    trailing: Switch.adaptive(
                      value: hideOnlyTotal,
                      onChanged: (val) {
                        ref
                            .read(hideOnlyTotalBalanceNotifierProvider.notifier)
                            .setHideOnlyTotal(val);
                      },
                      activeColor: AppColors.accentViolet,
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              Consumer(
                builder: (context, ref, child) {
                  final sideBySideUI = ref.watch(
                    sideBySideTransactionUINotifierProvider,
                  );
                  return _SettingsTile(
                    icon: Icons.view_sidebar_outlined,
                    title: 'Compact Transaction UI',
                    subtitle: 'Show account & category side-by-side',
                    trailing: Switch.adaptive(
                      value: sideBySideUI,
                      onChanged: (val) {
                        ref
                            .read(
                              sideBySideTransactionUINotifierProvider.notifier,
                            )
                            .setSideBySide(val);
                      },
                      activeColor: AppColors.accentViolet,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data
          _SectionTitle('Data Management'),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Accounts',
                onTap: () => context.push('/accounts'),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Categories',
                onTap: () => context.push('/categories'),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.pie_chart_outline,
                title: 'Budgets',
                onTap: () => context.push('/budgets'),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete all data',
                iconColor: AppColors.expense,
                textColor: AppColors.expense,
                onTap: () => _showDeleteConfirmation(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About
          _SectionTitle('About'),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About Finara',
                subtitle: 'Version 0.1.0 Alpha',
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.code,
                title: 'Built with Flutter',
                subtitle: 'Powered by Dart & Drift',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure you want to delete all data?'),
          content: const Text(
            'Once done all the data will be permanently erased, it is advised that you should back up before proceeding.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.expense,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ref.read(databaseProvider).clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been deleted.')),
        );
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(color: AppColors.accentViolet),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor ?? AppColors.accentViolet),
      title: Text(
        title, 
        style: AppTypography.bodyMedium.copyWith(color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTypography.bodySmall)
          : null,
      trailing:
          trailing ??
          (onTap != null ? Icon(Icons.chevron_right, size: 20, color: textColor) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
