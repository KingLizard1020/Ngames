import 'package:flutter/foundation.dart';

/// Centralized logging utility for the application.
///
/// Logs are only shown in debug mode to avoid cluttering production.
class AppLogger {
  AppLogger._();

  /// Log level enumeration
  static const bool _enableLogging = kDebugMode;

  /// Log an informational message
  static void info(String message, [String? tag]) {
    if (_enableLogging) {
      final prefix = tag != null ? '[$tag]' : '[INFO]';
      debugPrint('$prefix $message');
    }
  }

  /// Log an error message
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    if (_enableLogging) {
      final prefix = tag != null ? '[$tag][ERROR]' : '[ERROR]';
      debugPrint('$prefix $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log a warning message
  static void warning(String message, [String? tag]) {
    if (_enableLogging) {
      final prefix = tag != null ? '[$tag][WARNING]' : '[WARNING]';
      debugPrint('$prefix $message');
    }
  }

  /// Log a debug message
  static void debug(String message, [String? tag]) {
    if (_enableLogging) {
      final prefix = tag != null ? '[$tag][DEBUG]' : '[DEBUG]';
      debugPrint('$prefix $message');
    }
  }
}
