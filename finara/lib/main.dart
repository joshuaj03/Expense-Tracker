import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design_system/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/providers.dart';
import 'core/database/seeds.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ProviderScope(child: FinaraApp()));
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
    _seedData();
  }

  Future<void> _seedData() async {
    if (_seeded) return;
    
    // Initialize notifications
    await ref.read(notificationServiceProvider).init();
    
    final dao = ref.read(categoriesDaoProvider);
    await seedDefaultCategories(
      () => dao.getAllCategories(),
      (cat) => dao.insertCategory(cat),
    );
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

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
