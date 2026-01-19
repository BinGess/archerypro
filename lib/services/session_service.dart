import 'package:uuid/uuid.dart';
import '../models/training_session.dart';
import '../models/equipment.dart';
import '../models/end.dart';
import 'storage_service.dart';

/// Service for managing training sessions
class SessionService {
  final StorageService _storageService;
  final _uuid = const Uuid();

  SessionService(this._storageService);

  /// Create a new training session
  TrainingSession createSession({
    required Equipment equipment,
    required double distance,
    required int targetFaceSize,
    SessionType sessionType = SessionType.training,
    EnvironmentType environment = EnvironmentType.indoor,
    String? notes,
  }) {
    return TrainingSession(
      id: _uuid.v4(),
      date: DateTime.now(),
      sessionType: sessionType,
      equipment: equipment,
      distance: distance,
      targetFaceSize: targetFaceSize,
      environment: environment,
      notes: notes,
    );
  }

  /// Save a session to storage
  Future<void> saveSession(TrainingSession session) async {
    await _storageService.saveSession(session);
  }

  /// Get a specific session by ID
  Future<TrainingSession?> getSession(String id) async {
    return await _storageService.getSession(id);
  }

  /// Get all sessions
  Future<List<TrainingSession>> getAllSessions() async {
    return await _storageService.getAllSessions();
  }

  /// Get sessions sorted by date (newest first)
  Future<List<TrainingSession>> getSessionsSortedByDate() async {
    final sessions = await getAllSessions();
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  /// Get sessions for a specific date range
  Future<List<TrainingSession>> getSessionsInRange(DateTime start, DateTime end) async {
    final allSessions = await getAllSessions();
    return allSessions.where((session) {
      return session.date.isAfter(start.subtract(const Duration(days: 1))) &&
          session.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get sessions for current month
  Future<List<TrainingSession>> getCurrentMonthSessions() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return await getSessionsInRange(startOfMonth, endOfMonth);
  }

  /// Get sessions for last N days
  Future<List<TrainingSession>> getRecentSessions(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    return await getSessionsInRange(startDate, now);
  }

  /// Update an existing session
  Future<void> updateSession(TrainingSession session) async {
    await _storageService.updateSession(session);
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    await _storageService.deleteSession(id);
  }

  /// Add an end to a session
  TrainingSession addEndToSession(TrainingSession session, End end) {
    return session.addEnd(end);
  }

  /// Update an end in a session
  TrainingSession updateEndInSession(TrainingSession session, End updatedEnd) {
    return session.updateEnd(updatedEnd);
  }

  /// Complete a session
  TrainingSession completeSession(TrainingSession session) {
    return session.complete();
  }

  /// Get best session (highest score percentage)
  Future<TrainingSession?> getBestSession() async {
    final sessions = await getAllSessions();
    if (sessions.isEmpty) return null;

    return sessions.reduce((best, current) {
      return current.scorePercentage > best.scorePercentage ? current : best;
    });
  }

  /// Get total arrow count across all sessions
  Future<int> getTotalArrowCount() async {
    final sessions = await getAllSessions();
    return sessions.fold(0, (sum, session) => sum + session.arrowCount);
  }

  /// Get total arrow count for current month
  Future<int> getCurrentMonthArrowCount() async {
    final sessions = await getCurrentMonthSessions();
    return sessions.fold(0, (sum, session) => sum + session.arrowCount);
  }

  /// Clear all sessions (use with caution!)
  Future<void> clearAllSessions() async {
    await _storageService.clearAllSessions();
  }
}
