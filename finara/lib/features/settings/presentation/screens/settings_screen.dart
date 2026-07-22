import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
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
                    child: Text('F',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Finara',
                    style: AppTypography.displaySmall
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Personal Finance OS',
                    style: AppTypography.bodySmall
                        .copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('v0.1.0 Alpha',
                    style: AppTypography.labelSmall
                        .copyWith(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance
          _SectionTitle('Appearance'),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                trailing: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Auto')),
                    ButtonSegment(value: 1, label: Text('Dark')),
                    ButtonSegment(value: 2, label: Text('Light')),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (value) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setMode(value.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const Divider(height: 1),
              Consumer(
                builder: (context, ref, child) {
                  final hideOnlyTotal = ref.watch(hideOnlyTotalBalanceProvider);
                  return _SettingsTile(
                    icon: Icons.visibility_off_outlined,
                    title: 'Hide Only Total',
                    subtitle: 'Show income/expense when hidden',
                    trailing: Switch.adaptive(
                      value: hideOnlyTotal,
                      onChanged: (val) {
                        ref
                            .read(hideOnlyTotalBalanceProvider.notifier)
                            .setHideOnlyTotal(val);
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTypography.labelLarge
            .copyWith(color: AppColors.accentViolet));
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.accentViolet),
      title: Text(title, style: AppTypography.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTypography.bodySmall)
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, size: 20)
              : null),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
