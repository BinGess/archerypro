import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/training_session.dart';
import '../utils/constants.dart';

/// Service for local data persistence using Hive
class StorageService {
  LazyBox<String>? _sessionsBox;
  Box<dynamic>? _settingsBox;
  bool _isInitialized = false;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // Open boxes with recovery strategy
      // Use LazyBox for sessions to avoid loading all data into memory at once
      try {
        _sessionsBox = await Hive.openLazyBox<String>(kSessionsBoxName);
      } catch (e) {
        print('Error opening sessions box: $e. Deleting and recreating...');
        await Hive.deleteBoxFromDisk(kSessionsBoxName);
        _sessionsBox = await Hive.openLazyBox<String>(kSessionsBoxName);
      }

      try {
        _settingsBox = await Hive.openBox(kSettingsBoxName);
      } catch (e) {
        print('Error opening settings box: $e. Deleting and recreating...');
        await Hive.deleteBoxFromDisk(kSettingsBoxName);
        _settingsBox = await Hive.openBox(kSettingsBoxName);
      }

      _isInitialized = true;
    } catch (e) {
      print('Fatal error initializing storage: $e');
      rethrow;
    }
  }

  /// Delete all data from disk (Recovery mode)
  Future<void> deleteDataFromDisk() async {
    await Hive.deleteBoxFromDisk(kSessionsBoxName);
    await Hive.deleteBoxFromDisk(kSettingsBoxName);
    _sessionsBox = null;
    _settingsBox = null;
    _isInitialized = false;
  }

  /// Ensure the service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
  }

  // ========== Session Storage ==========

  /// Save a training session
  Future<void> saveSession(TrainingSession session) async {
    _ensureInitialized();
    final jsonString = _sessionToJsonString(session);
    await _sessionsBox!.put(session.id, jsonString);
  }

  /// Get a specific session by ID
  Future<TrainingSession?> getSession(String id) async {
    _ensureInitialized();
    final jsonString = await _sessionsBox!.get(id);
    if (jsonString == null) return null;
    return _sessionFromJsonString(jsonString);
  }

  /// Get all sessions (limited to prevent OOM)
  /// [limit] defaults to 50 to ensure app stability
  Future<List<TrainingSession>> getAllSessions({int limit = 50}) async {
    _ensureInitialized();
    final sessions = <TrainingSession>[];

    // Get all keys
    final keys = _sessionsBox!.keys.toList();
    
    // Load only the last [limit] sessions (assuming insertion order)
    // This prevents loading thousands of sessions into memory
    final startIndex = (keys.length > limit) ? keys.length - limit : 0;
    final keysToLoad = keys.skip(startIndex);

    for (final key in keysToLoad) {
      try {
        final jsonString = await _sessionsBox!.get(key);
        if (jsonString != null) {
          final session = _sessionFromJsonString(jsonString);
          sessions.add(session);
        }
      } catch (e) {
        // Skip corrupted data
        print('Error loading session: $e');
      }
    }

    return sessions;
  }

  /// Get sessions for a specific date range
  /// Iterates through all data but only keeps matching sessions in memory
  Future<List<TrainingSession>> getSessionsInRange(DateTime start, DateTime end) async {
    _ensureInitialized();
    final sessions = <TrainingSession>[];
    
    // Iterate all keys to find matches
    // This is slower but ensures we find all historical data without loading everything into memory
    for (final key in _sessionsBox!.keys) {
      try {
        final jsonString = await _sessionsBox!.get(key);
        if (jsonString != null) {
          final session = _sessionFromJsonString(jsonString);
          // Check date range (inclusive)
          if (session.date.isAfter(start.subtract(const Duration(days: 1))) &&
              session.date.isBefore(end.add(const Duration(days: 1)))) {
            sessions.add(session);
          }
        }
      } catch (e) {
        print('Error loading session during range query: $e');
      }
    }
    
    return sessions;
  }

  /// Update an existing session
  Future<void> updateSession(TrainingSession session) async {
    await saveSession(session);
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    _ensureInitialized();
    await _sessionsBox!.delete(id);
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    _ensureInitialized();
    await _sessionsBox!.clear();
  }

  /// Get number of stored sessions
  Future<int> getSessionCount() async {
    _ensureInitialized();
    return _sessionsBox!.length;
  }

  // ========== Settings Storage ==========

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();
    await _settingsBox!.put(key, value);
  }

  /// Get a setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    _ensureInitialized();
    return _settingsBox!.get(key, defaultValue: defaultValue) as T?;
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    _ensureInitialized();
    await _settingsBox!.delete(key);
  }

  /// Get monthly goal
  int getMonthlyGoal() {
    return getSetting<int>(kMonthlyGoalKey, defaultValue: kDefaultMonthlyGoal) ?? kDefaultMonthlyGoal;
  }

  /// Set monthly goal
  Future<void> setMonthlyGoal(int goal) async {
    await saveSetting(kMonthlyGoalKey, goal);
  }

  // ========== Helper Methods ==========

  /// Convert session to JSON string for storage
  String _sessionToJsonString(TrainingSession session) {
    // Using a simple JSON encoding approach
    // In a real app, you might want to use proper JSON serialization
    final json = session.toJson();
    return _encodeJson(json);
  }

  /// Convert JSON string back to session
  TrainingSession _sessionFromJsonString(String jsonString) {
    final json = _decodeJson(jsonString);
    return TrainingSession.fromJson(json);
  }

  /// JSON encoding using dart:convert
  String _encodeJson(Map<String, dynamic> json) {
    try {
      return jsonEncode(json);
    } catch (e) {
      print('Error encoding JSON: $e');
      rethrow;
    }
  }

  /// JSON decoding using dart:convert
  Map<String, dynamic> _decodeJson(String str) {
    try {
      final decoded = jsonDecode(str);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('Invalid JSON format');
    } catch (e) {
      print('Error decoding JSON: $e');
      rethrow;
    }
  }

  /// Close all boxes (call when app is closing)
  Future<void> close() async {
    await _sessionsBox?.close();
    await _settingsBox?.close();
    _isInitialized = false;
  }

  /// Compact storage (optimize space)
  Future<void> compact() async {
    _ensureInitialized();
    await _sessionsBox!.compact();
    await _settingsBox!.compact();
  }
}
