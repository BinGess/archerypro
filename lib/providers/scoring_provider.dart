import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_session.dart';
import '../models/end.dart';
import '../models/arrow.dart';
import '../models/equipment.dart';
import '../services/scoring_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

// Service providers
final scoringServiceProvider = Provider((ref) => ScoringService());
final storageServiceProvider = Provider((ref) => StorageService());
final sessionServiceProvider = Provider((ref) => SessionService(ref.watch(storageServiceProvider)));

// Scoring state provider
final scoringProvider = StateNotifierProvider<ScoringNotifier, ScoringState>((ref) {
  return ScoringNotifier(
    ref.watch(scoringServiceProvider),
    ref.watch(sessionServiceProvider),
  );
});

/// State for scoring screen
class ScoringState {
  final TrainingSession? currentSession;
  final End? currentEnd;
  final bool isTargetView;
  final bool isSaving;
  final String? error;

  const ScoringState({
    this.currentSession,
    this.currentEnd,
    this.isTargetView = false,
    this.isSaving = false,
    this.error,
  });

  /// Get current end number
  int get currentEndNumber => currentEnd?.endNumber ?? 1;

  /// Get total score
  int get totalScore => currentSession?.totalScore ?? 0;

  /// Get current end arrow count
  int get currentEndArrows => currentEnd?.arrowCount ?? 0;

  /// Whether session is active
  bool get hasActiveSession => currentSession != null;

  /// Whether current end is complete
  bool get isCurrentEndComplete => currentEnd?.isComplete ?? false;

  ScoringState copyWith({
    TrainingSession? currentSession,
    End? currentEnd,
    bool? isTargetView,
    bool? isSaving,
    String? error,
  }) {
    return ScoringState(
      currentSession: currentSession ?? this.currentSession,
      currentEnd: currentEnd ?? this.currentEnd,
      isTargetView: isTargetView ?? this.isTargetView,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

/// Notifier for scoring state
class ScoringNotifier extends StateNotifier<ScoringState> {
  final ScoringService _scoringService;
  final SessionService _sessionService;

  ScoringNotifier(this._scoringService, this._sessionService) : super(const ScoringState());

  /// Start a new session
  void startNewSession({
    required Equipment equipment,
    required double distance,
    required int targetFaceSize,
    SessionType sessionType = SessionType.training,
    EnvironmentType environment = EnvironmentType.indoor,
  }) {
    final session = _sessionService.createSession(
      equipment: equipment,
      distance: distance,
      targetFaceSize: targetFaceSize,
      sessionType: sessionType,
      environment: environment,
    );

    final firstEnd = _scoringService.createEnd(1);

    state = state.copyWith(
      currentSession: session,
      currentEnd: firstEnd,
      error: null,
    );
  }

  /// Add an arrow score
  void addArrow(int score, {Offset? position}) {
    if (state.currentEnd == null) {
      state = state.copyWith(error: 'No active end');
      return;
    }

    try {
      // Create arrow
      final arrow = _scoringService.createArrow(score, position: position);

      // Add to current end
      final updatedEnd = _scoringService.addArrowToEnd(state.currentEnd!, arrow);

      // Update session if exists
      TrainingSession? updatedSession = state.currentSession;
      if (updatedSession != null) {
        // Remove old version of end if it exists
        final filteredEnds = updatedSession.ends.where((e) => e.id != updatedEnd.id).toList();
        updatedSession = updatedSession.copyWith(ends: [...filteredEnds, updatedEnd]);
      }

      state = state.copyWith(
        currentEnd: updatedEnd,
        currentSession: updatedSession,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove last arrow
  void removeLastArrow() {
    if (state.currentEnd == null || state.currentEnd!.arrows.isEmpty) {
      state = state.copyWith(error: 'No arrows to remove');
      return;
    }

    try {
      final updatedEnd = _scoringService.removeLastArrowFromEnd(state.currentEnd!);

      // Update session
      TrainingSession? updatedSession = state.currentSession;
      if (updatedSession != null) {
        final filteredEnds = updatedSession.ends.where((e) => e.id != updatedEnd.id).toList();
        updatedSession = updatedSession.copyWith(ends: [...filteredEnds, updatedEnd]);
      }

      state = state.copyWith(
        currentEnd: updatedEnd,
        currentSession: updatedSession,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Complete current end and start next one
  void completeEnd() {
    if (state.currentEnd == null) return;

    final completedEnd = _scoringService.completeEnd(state.currentEnd!);

    // Update session with completed end
    TrainingSession? updatedSession = state.currentSession;
    if (updatedSession != null) {
      final filteredEnds = updatedSession.ends.where((e) => e.id != completedEnd.id).toList();
      updatedSession = updatedSession.copyWith(ends: [...filteredEnds, completedEnd]);
    }

    // Create new end
    final nextEndNumber = state.currentEndNumber + 1;
    final newEnd = _scoringService.createEnd(nextEndNumber);

    state = state.copyWith(
      currentSession: updatedSession,
      currentEnd: newEnd,
      error: null,
    );
  }

  /// Toggle between target view and grid view
  void toggleView() {
    state = state.copyWith(isTargetView: !state.isTargetView);
  }

  /// Save current session
  Future<void> saveSession() async {
    if (state.currentSession == null) {
      state = state.copyWith(error: 'No session to save');
      return;
    }

    state = state.copyWith(isSaving: true);

    try {
      // Complete the end if it has arrows
      TrainingSession sessionToSave = state.currentSession!;

      if (state.currentEnd != null && state.currentEnd!.arrows.isNotEmpty) {
        final completedEnd = _scoringService.completeEnd(state.currentEnd!);
        final filteredEnds = sessionToSave.ends.where((e) => e.id != completedEnd.id).toList();
        sessionToSave = sessionToSave.copyWith(ends: [...filteredEnds, completedEnd]);
      }

      // Complete the session
      final completedSession = _sessionService.completeSession(sessionToSave);

      // Save to storage
      await _sessionService.saveSession(completedSession);

      // Reset state
      state = const ScoringState();
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  /// Cancel current session
  void cancelSession() {
    state = const ScoringState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
