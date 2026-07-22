/// go_router navigation configuration for Finara v0.2.
/// 5-tab bottom nav: Home, Records, Accounts, Budgets, Analytics
/// Settings moved to side drawer.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/accounts/presentation/screens/accounts_screen.dart';
import '../../features/accounts/presentation/screens/add_account_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/backup/presentation/screens/backup_screen.dart';
import '../../features/developer_log/presentation/screens/developer_log_screen.dart';
import '../design_system/app_colors.dart';
import 'app_drawer.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    // Bottom navigation shell â€” 5 tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TransactionsScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/accounts',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AccountsScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/budgets',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BudgetsScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AnalyticsScreen(),
              ),
            ),
          ],
        ),
      ],
    ),

    // Full-screen routes (outside bottom nav)
    GoRoute(
      path: '/add-transaction',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final editId = state.uri.queryParameters['editId'];
        return CustomTransitionPage(
          child: AddTransactionScreen(
            editTransactionId: editId != null ? int.tryParse(editId) : null,
          ),
          transitionsBuilder: (context, animation, _, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/add-account',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddAccountScreen(),
    ),
    GoRoute(
      path: '/edit-account/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddAccountScreen(editAccountId: id);
      },
    ),
    GoRoute(
      path: '/categories',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/backup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BackupScreen(),
    ),
    GoRoute(
      path: '/dev-log',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DeveloperLogScreen(),
    ),
  ],
);

/// App shell with 5-tab bottom navigation and side drawer.
class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor:
              Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          indicatorColor: AppColors.accentViolet.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon:
                  Icon(Icons.dashboard, color: AppColors.accentViolet),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon:
                  Icon(Icons.receipt_long, color: AppColors.accentViolet),
              label: 'Records',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet,
                  color: AppColors.accentViolet),
              label: 'Accounts',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon:
                  Icon(Icons.pie_chart, color: AppColors.accentViolet),
              label: 'Budgets',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon:
                  Icon(Icons.insights, color: AppColors.accentViolet),
              label: 'Analytics',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
