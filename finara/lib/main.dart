import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design_system/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/services/shared_prefs_provider.dart';
import 'core/services/notification_service.dart';
import 'features/settings/data/theme_provider.dart';

import 'core/providers/providers.dart';
import 'core/database/mymoney_import_data.dart';
import 'core/utils/logger.dart';
import 'features/accounts/services/credit_card_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    ProviderScope(
      observers: [RiverpodTalkerObserver()],
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FinaraApp(),
    ),
  );
}

class FinaraApp extends ConsumerStatefulWidget {
  const FinaraApp({super.key});

  @override
  ConsumerState<FinaraApp> createState() => _FinaraAppState();
}

class _FinaraAppState extends ConsumerState<FinaraApp> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_LifecycleObserver());
    AppLogger.instance.lifecycle('App started (initState)');
    _seedData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_LifecycleObserver());
    super.dispose();
  }

  Future<void> _seedData() async {
    if (_seeded) return;

    // Initialize notifications
    await ref.read(notificationServiceProvider).init();

    // Generate any missing credit card bills
    await ref.read(creditCardServiceProvider).generateMissingBills();

    // Import MyMoney data instead of just default categories
    final db = ref.read(databaseProvider);
    await importMyMoneyData(db);

    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp.router(
      title: 'Finara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (themeMode) {
        1 => ThemeMode.dark,
        2 => ThemeMode.light,
        _ => ThemeMode.system,
      },
      routerConfig: appRouter,
    );
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final _log = AppLogger.instance;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.lifecycle('App lifecycle changed: ${state.name}');
  }
}
