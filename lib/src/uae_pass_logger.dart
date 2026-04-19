import 'package:flutter/foundation.dart';

/// Log levels for the UAE PASS SDK.
enum UaePassLogLevel {
  /// No logs.
  none,

  /// Only error logs.
  error,

  /// Basic info and errors.
  info,

  /// Warnings about potential misuse.
  warning,

  /// Detailed verbose logging (default for debug builds).
  verbose,
}

/// Internal logger for the UAE PASS SDK.
class UaePassLogger {
  UaePassLogger._();

  static UaePassLogLevel _logLevel =
      kDebugMode ? UaePassLogLevel.verbose : UaePassLogLevel.none;

  /// Sets the log level for the SDK.
  static void setLogLevel(UaePassLogLevel level) {
    _logLevel = level;
  }

  /// Log a detailed verbose message.
  static void d(String message) {
    if (_logLevel.index >= UaePassLogLevel.verbose.index) {
      _print('DEBUG: $message');
    }
  }

  /// Log an informational message.
  static void i(String message) {
    if (_logLevel.index >= UaePassLogLevel.info.index) {
      _print('INFO: $message');
    }
  }

  /// Log a warning message.
  static void w(String message) {
    if (_logLevel.index >= UaePassLogLevel.warning.index) {
      _print('WARNING: $message');
    }
  }

  /// Log an error message.
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_logLevel.index >= UaePassLogLevel.error.index) {
      _print('ERROR: $message');
      if (error != null) _print('Reason: $error');
      if (stackTrace != null) _print('Stacktrace: $stackTrace');
    }
  }

  static void _print(String message) {
    debugPrint('AuthUaePass: $message');
  }
}
