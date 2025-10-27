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
