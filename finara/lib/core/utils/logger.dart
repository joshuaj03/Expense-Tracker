import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  }) : timestamp = DateTime.now();
}

final loggerProvider = ChangeNotifierProvider<AppLogger>((ref) {
  return AppLogger();
});

class AppLogger extends ChangeNotifier {
  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void info(String message) {
    _addLog(LogEntry(level: LogLevel.info, message: message));
    debugPrint('[INFO] $message');
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _addLog(LogEntry(
        level: LogLevel.warning,
        message: message,
        error: error,
        stackTrace: stackTrace));
    debugPrint('[WARN] $message');
    if (error != null) debugPrint(error.toString());
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _addLog(LogEntry(
        level: LogLevel.error,
        message: message,
        error: error,
        stackTrace: stackTrace));
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint(error.toString());
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  void _addLog(LogEntry entry) {
    _logs.insert(0, entry); // Insert at beginning for newest first
    if (_logs.length > 1000) {
      _logs.removeLast(); // Keep max 1000 logs
    }
    notifyListeners();
  }
}
