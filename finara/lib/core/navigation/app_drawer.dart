/// App drawer â€” side navigation for Settings, Backup & Restore, About.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('F',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finara', style: AppTypography.displaySmall),
                      Text('Personal Finance OS',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Menu items
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            _DrawerItem(
              icon: Icons.backup_outlined,
              label: 'Backup & Restore',
              onTap: () {
                Navigator.pop(context);
                context.push('/backup');
              },
            ),
            _DrawerItem(
              icon: Icons.category_outlined,
              label: 'Categories',
              onTap: () {
                Navigator.pop(context);
                context.push('/categories');
              },
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.bug_report_outlined,
              label: 'Developer Log',
              onTap: () {
                Navigator.pop(context);
                context.push('/dev-log');
              },
            ),

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'v0.0.20 Alpha',
                style: AppTypography.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.accentViolet),
      title: Text(label, style: AppTypography.bodyMedium),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
