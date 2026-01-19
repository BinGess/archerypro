import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_session.dart';
import '../services/session_service.dart';
import 'scoring_provider.dart';

// Session list provider
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref.watch(sessionServiceProvider));
});

// Selected session provider
final selectedSessionProvider = StateProvider<TrainingSession?>((ref) => null);

/// State for session management
class SessionState {
  final List<TrainingSession> sessions;
  final bool isLoading;
  final String? error;

  const SessionState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  /// Get sessions count
  int get sessionCount => sessions.length;

  /// Get total arrows across all sessions
  int get totalArrows {
    return sessions.fold(0, (sum, session) => sum + session.arrowCount);
  }

  /// Get best session
  TrainingSession? get bestSession {
    if (sessions.isEmpty) return null;
    return sessions.reduce((best, current) {
      return current.scorePercentage > best.scorePercentage ? current : best;
    });
  }

  /// Get recent sessions (last 10)
  List<TrainingSession> get recentSessions {
    final sorted = List<TrainingSession>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  SessionState copyWith({
    List<TrainingSession>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for session management
class SessionNotifier extends StateNotifier<SessionState> {
  final SessionService _sessionService;

  SessionNotifier(this._sessionService) : super(const SessionState()) {
    loadSessions();
  }

  /// Load all sessions from storage
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final sessions = await _sessionService.getSessionsSortedByDate();
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh sessions
  Future<void> refresh() async {
    await loadSessions();
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    try {
      await _sessionService.deleteSession(id);
      await loadSessions(); // Reload after deletion
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
