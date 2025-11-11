import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Initialize logging for the application
void initLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // In production, you might want to send logs to a service
    // For now, we'll use debugPrint for development
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}

/// Get a logger for a specific class or module
Logger getLogger(String className) {
  return Logger(className);
}

/// Application-wide logger utility
class AppLogger {
  static final _logger = Logger('QuickFix');

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
    _logger.info(message);
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
    _logger.warning(message);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
    _logger.severe(message, error, stackTrace);
  }

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
    _logger.fine(message);
  }
}
