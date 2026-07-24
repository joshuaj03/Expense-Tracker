/// Comprehensive logging system for Finara.
///
/// Uses Talker for in-app log viewing. Every operation — database mutations,
/// navigation events, UI interactions, backup/restore, and lifecycle events —
/// must be logged through this system so the user can monitor and debug
/// the app from the in-app Logs screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

// ──────────────────────────────────────────────
// Custom TalkerLog subclasses for structured log types
// ──────────────────────────────────────────────

/// Database operation log (INSERT, UPDATE, DELETE, QUERY).
class DbLog extends TalkerLog {
  DbLog(String message) : super(message);

  @override
  String get title => 'DB';

  @override
  AnsiPen get pen => AnsiPen()..cyan();
}

/// Navigation event log (screen transitions, tab switches).
class NavLog extends TalkerLog {
  NavLog(String message) : super(message);

  @override
  String get title => 'NAV';

  @override
  AnsiPen get pen => AnsiPen()..magenta();
}

/// User interaction log (taps, toggles, picker selections).
class UiLog extends TalkerLog {
  UiLog(String message) : super(message);

  @override
  String get title => 'UI';

  @override
  AnsiPen get pen => AnsiPen()..green();
}

/// Backup/restore operation log.
class BackupLog extends TalkerLog {
  BackupLog(String message) : super(message);

  @override
  String get title => 'BACKUP';

  @override
  AnsiPen get pen => AnsiPen()..yellow();
}

/// App lifecycle event log (start, pause, resume).
class LifecycleLog extends TalkerLog {
  LifecycleLog(String message) : super(message);

  @override
  String get title => 'LIFECYCLE';

  @override
  AnsiPen get pen => AnsiPen()..blue();
}

// ──────────────────────────────────────────────
// Global Talker instance
// ──────────────────────────────────────────────

final talker = TalkerFlutter.init(
  settings: TalkerSettings(maxHistoryItems: 5000),
);

final loggerProvider = Provider<Talker>((ref) {
  return talker;
});

// ──────────────────────────────────────────────
// Convenience API — use AppLogger everywhere
// ──────────────────────────────────────────────

/// Centralized logger with typed convenience methods.
///
/// Usage:
/// ```dart
/// final log = AppLogger.instance;
/// log.db('INSERT transaction id=5 amount=₹500 category=Food account=UPI-BOB');
/// log.nav('Navigated to /add-transaction');
/// log.ui('Category picker opened, type=expense');
/// log.backup('CSV export started');
/// log.lifecycle('App resumed');
/// log.error('Transaction insert failed', exception, stackTrace);
/// ```
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  /// Log a database operation.
  void db(String message) => talker.logCustom(DbLog(message));

  /// Log a navigation event.
  void nav(String message) => talker.logCustom(NavLog(message));

  /// Log a user interaction.
  void ui(String message) => talker.logCustom(UiLog(message));

  /// Log a backup/restore operation.
  void backup(String message) => talker.logCustom(BackupLog(message));

  /// Log an app lifecycle event.
  void lifecycle(String message) => talker.logCustom(LifecycleLog(message));

  /// Log an informational message.
  void info(String message) => talker.info(message);

  /// Log a warning.
  void warning(String message) => talker.warning(message);

  /// Log an error with optional exception and stack trace.
  void error(String message, [Object? exception, StackTrace? stackTrace]) =>
      talker.error(message, exception, stackTrace);
}

// ──────────────────────────────────────────────
// Riverpod observer — logs all provider lifecycle events
// ──────────────────────────────────────────────

class RiverpodTalkerObserver extends ProviderObserver {
  RiverpodTalkerObserver();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {}

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    talker.verbose(
      'Provider [${provider.name ?? provider.runtimeType}] updated: $newValue',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {}

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    talker.error(
      'Provider [${provider.name ?? provider.runtimeType}] failed',
      error,
      stackTrace,
    );
  }
}

// ──────────────────────────────────────────────
// GoRouter navigation observer
// ──────────────────────────────────────────────

class AppNavigatorObserver extends NavigatorObserver {
  final _log = AppLogger.instance;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.nav('PUSH → ${route.settings.name ?? route.settings.toString()}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.nav('POP ← ${route.settings.name ?? route.settings.toString()}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log.nav('REPLACE ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.nav('REMOVE ${route.settings.name ?? route.settings.toString()}');
  }
}
