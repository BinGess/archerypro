import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Service for logging errors and crashes to file
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  File? _logFile;
  bool _isInitialized = false;
  final List<String> _memoryLogs = [];
  static const int _maxMemoryLogs = 100;
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB

  /// Initialize the logger service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
      _logFile = File('${logDir.path}/app_log_$timestamp.txt');

      // Rotate log if too large
      if (await _logFile!.exists()) {
        final fileSize = await _logFile!.length();
        if (fileSize > _maxLogFileSize) {
          await _rotateLog();
        }
      }

      _isInitialized = true;
      log('Logger initialized successfully', level: LogLevel.info);
    } catch (e) {
      debugPrint('Failed to initialize logger: $e');
      // Continue without file logging
      _isInitialized = true;
    }
  }

  /// Rotate log file
  Future<void> _rotateLog() async {
    try {
      if (_logFile == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final archivePath = '${directory.path}/logs/app_log_$timestamp.txt';

      await _logFile!.rename(archivePath);

      // Recreate current log file
      final currentTimestamp = DateFormat('yyyyMMdd').format(DateTime.now());
      _logFile = File('${directory.path}/logs/app_log_$currentTimestamp.txt');
    } catch (e) {
      debugPrint('Failed to rotate log: $e');
    }
  }

  /// Log a message
  void log(String message, {
    LogLevel level = LogLevel.debug,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag] ' : '';

    final logMessage = '$timestamp $levelStr $tagStr$message';

    // Print to console
    switch (level) {
      case LogLevel.error:
      case LogLevel.fatal:
        debugPrint('❌ $logMessage');
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $logMessage');
        break;
      case LogLevel.info:
        debugPrint('ℹ️ $logMessage');
        break;
      case LogLevel.debug:
      default:
        debugPrint('🔍 $logMessage');
    }

    // Add error details if provided
    String fullLogMessage = logMessage;
    if (error != null) {
      fullLogMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      fullLogMessage += '\nStack trace:\n$stackTrace';
    }

    // Store in memory
    _memoryLogs.add(fullLogMessage);
    if (_memoryLogs.length > _maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }

    // Write to file synchronously to avoid losing logs
    _writeToFileSync(fullLogMessage);
  }

  /// Write log to file synchronously (fire and forget with error handling)
  void _writeToFileSync(String message) {
    if (!_isInitialized || _logFile == null) return;

    // Use unawaited to ensure logs are written even if not awaited
    _writeToFile(message).catchError((e) {
      debugPrint('⚠️ Failed to write log to file: $e');
    });
  }

  /// Write log to file
  Future<void> _writeToFile(String message) async {
    if (!_isInitialized || _logFile == null) return;

    try {
      await _logFile!.writeAsString(
        '$message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Failed to write log to file: $e');
    }
  }

  /// Force flush all pending logs to disk immediately (for critical logs before potential crash)
  Future<void> forceFlush() async {
    if (!_isInitialized || _logFile == null) return;

    try {
      // Ensure file is synced to disk
      final raf = await _logFile!.open(mode: FileMode.append);
      await raf.flush();
      await raf.close();
    } catch (e) {
      debugPrint('Failed to force flush logs: $e');
    }
  }

  /// Get all log files
  Future<List<File>> getLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        return [];
      }

      final files = await logDir.list().where((entity) => entity is File).toList();
      return files.cast<File>().toList()..sort((a, b) => b.path.compareTo(a.path));
    } catch (e) {
      debugPrint('Failed to get log files: $e');
      return [];
    }
  }

  /// Get current log file content
  Future<String> getCurrentLogContent() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 'No log file available';
    }

    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Failed to read log file: $e';
    }
  }

  /// Get memory logs
  List<String> getMemoryLogs() {
    return List.unmodifiable(_memoryLogs);
  }

  /// Clear all log files
  Future<void> clearLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
        await logDir.create();
      }

      _memoryLogs.clear();

      // Reinitialize
      _isInitialized = false;
      await initialize();

      log('Logs cleared', level: LogLevel.info);
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }
  }

  /// Log app lifecycle event
  void logLifecycle(String event) {
    log('App lifecycle: $event', level: LogLevel.info, tag: 'LIFECYCLE');
  }

  /// Log error with context
  void logError(String message, {
    required Object error,
    StackTrace? stackTrace,
    String? context,
  }) {
    final contextStr = context != null ? ' [$context]' : '';
    log(
      '$message$contextStr',
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log fatal error (app crash)
  void logFatal(String message, {
    required Object error,
    required StackTrace stackTrace,
  }) {
    log(
      'FATAL: $message',
      level: LogLevel.fatal,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}
