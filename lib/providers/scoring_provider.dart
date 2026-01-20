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
  final int maxEnds; // 最大组数
  final int arrowsPerEnd; // 每组箭数
  final int focusedEndIndex;
  final int focusedArrowIndex;

  const ScoringState({
    this.currentSession,
    this.currentEnd,
    this.isTargetView = false,
    this.isSaving = false,
    this.error,
    this.maxEnds = 10,
    this.arrowsPerEnd = 6,
    this.focusedEndIndex = 0,
    this.focusedArrowIndex = 0,
  });

  /// Get current end number
  int get currentEndNumber => focusedEndIndex + 1;

  /// Get total score
  int get totalScore => currentSession?.totalScore ?? 0;

  /// Get current end arrow count
  int get currentEndArrows => currentEnd?.arrows.length ?? 0;

  /// Whether session is active
  bool get hasActiveSession => currentSession != null;

  /// Get completed ends count
  int get completedEndsCount => currentSession?.ends.length ?? 0;

  /// Whether all ends are completed
  bool get isSessionComplete => completedEndsCount >= maxEnds;

  /// Whether current end is complete
  bool get isCurrentEndComplete => (currentEnd?.arrows.length ?? 0) >= arrowsPerEnd;

  ScoringState copyWith({
    TrainingSession? currentSession,
    End? currentEnd,
    bool? isTargetView,
    bool? isSaving,
    String? error,
    int? maxEnds,
    int? arrowsPerEnd,
    int? focusedEndIndex,
    int? focusedArrowIndex,
  }) {
    return ScoringState(
      currentSession: currentSession ?? this.currentSession,
      currentEnd: currentEnd ?? this.currentEnd,
      isTargetView: isTargetView ?? this.isTargetView,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      maxEnds: maxEnds ?? this.maxEnds,
      arrowsPerEnd: arrowsPerEnd ?? this.arrowsPerEnd,
      focusedEndIndex: focusedEndIndex ?? this.focusedEndIndex,
      focusedArrowIndex: focusedArrowIndex ?? this.focusedArrowIndex,
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
    int maxEnds = 10,
    int arrowsPerEnd = 6,
    bool isTargetMode = false,
  }) {
    final session = _sessionService.createSession(
      equipment: equipment,
      distance: distance,
      targetFaceSize: targetFaceSize,
      sessionType: sessionType,
      environment: environment,
    );

    final firstEnd = _scoringService.createEnd(1, maxArrows: arrowsPerEnd);

    state = state.copyWith(
      currentSession: session,
      currentEnd: firstEnd,
      error: null,
      maxEnds: maxEnds,
      arrowsPerEnd: arrowsPerEnd,
      isTargetView: isTargetMode,
    );
  }

  /// Set focus to a specific arrow
  void setFocus(int endIdx, int arrowIdx) {
    // Ensure indices are within bounds
    if (endIdx < 0 || arrowIdx < 0 || arrowIdx >= state.arrowsPerEnd) return;
    
    // Auto-create ends if focusing on a future end (e.g. via auto-advance)
    // But typically setFocus is user-initiated.
    // If user clicks a future end placeholder, we should probably allow it only if previous ends are done?
    // For now, let's just update the state.
    state = state.copyWith(
      focusedEndIndex: endIdx,
      focusedArrowIndex: arrowIdx,
    );
  }

  /// Add an arrow score with focus-based logic
  Future<bool> addArrow(int score, {Offset? position}) async {
    if (state.currentSession == null) {
      state = state.copyWith(error: 'No active session');
      return false;
    }

    try {
      // 1. Determine target End
      // If focusedEndIndex exceeds current ends length, we need to create a new end
      List<End> currentEnds = [...state.currentSession!.ends];
      End? targetEnd;
      
      if (state.focusedEndIndex < currentEnds.length) {
        targetEnd = currentEnds[state.focusedEndIndex];
      } else if (state.focusedEndIndex == currentEnds.length) {
        // Create new end
        targetEnd = _scoringService.createEnd(state.focusedEndIndex + 1, maxArrows: state.arrowsPerEnd);
        currentEnds.add(targetEnd);
      } else {
        // Gap in ends (shouldn't happen with sequential logic), but handle gracefully
        return false;
      }

      // 2. Create or Update Arrow
      List<Arrow> arrows = [...targetEnd.arrows];
      final newArrow = _scoringService.createArrow(score, position: position);

      if (state.focusedArrowIndex < arrows.length) {
        // Update existing arrow
        arrows[state.focusedArrowIndex] = newArrow;
      } else if (state.focusedArrowIndex == arrows.length) {
        // Add new arrow
        arrows.add(newArrow);
      } else {
        // Gap in arrows, fill with 0s? Or prevent input.
        // For simplicity, we only allow input if previous arrows exist or we are at the next slot.
        // But the user might want to edit "Arrow 3" before "Arrow 2". 
        // Let's assume we fill gaps with Miss (0) if needed, OR just append.
        // Given the requirement "insert into green box", the UI will guide sequential input usually.
        // Let's just append if index is too high to be safe.
        arrows.add(newArrow);
      }

      // 3. Update End
      final updatedEnd = targetEnd.copyWith(arrows: arrows);
      if (state.focusedEndIndex < currentEnds.length) {
        currentEnds[state.focusedEndIndex] = updatedEnd; // Replace if existed before this function call (logic above modified currentEnds list)
        // Actually, logic above added to list if new.
        // Let's rely on index.
        currentEnds[state.focusedEndIndex] = updatedEnd;
      }

      // 4. Update Session
      final updatedSession = state.currentSession!.copyWith(ends: currentEnds);
      
      // 5. Calculate Next Focus
      int nextEndIdx = state.focusedEndIndex;
      int nextArrowIdx = state.focusedArrowIndex + 1;

      if (nextArrowIdx >= state.arrowsPerEnd) {
        // End completed, move to next end
        nextEndIdx++;
        nextArrowIdx = 0;
      }

      // 6. Update State
      state = state.copyWith(
        currentSession: updatedSession,
        currentEnd: updatedEnd, // Keep currentEnd pointing to the one just modified
        focusedEndIndex: nextEndIdx,
        focusedArrowIndex: nextArrowIdx,
        error: null,
      );

      // 7. Auto-create next end if needed (for UI display)
      // If we moved focus to a new end index that doesn't exist, we can optionally create it now
      // or let the UI render a placeholder.
      // The requirement says "insert second group input box below".
      // If we are at the last arrow of last end, and not yet at maxEnds, we should probably prepare next.
      // But let's leave it to lazy creation in the next addArrow call or manual tap.
      // Actually, for better UX, if we auto-advanced focus, the green box should appear on the next empty slot.
      // If that slot is in a non-existent end, we might want to make sure UI handles it.
      
      return false; // Never auto-complete/save
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Complete current end
  Future<void> _completeCurrentEnd() async {
    if (state.currentEnd == null || state.currentSession == null) return;

    final completedEnd = state.currentEnd!.copyWith(completedAt: DateTime.now());
    final updatedEnds = [...state.currentSession!.ends];
    final existingIndex = updatedEnds.indexWhere((e) => e.id == completedEnd.id);
    if (existingIndex >= 0) {
      updatedEnds[existingIndex] = completedEnd;
    } else {
      updatedEnds.add(completedEnd);
    }

    final updatedSession = state.currentSession!.copyWith(ends: updatedEnds);
    state = state.copyWith(currentSession: updatedSession);
  }

  /// Start next end
  void _startNextEnd() {
    final nextEndNumber = state.completedEndsCount + 1;
    // Removed strict check against maxEnds to allow "one more end" functionality
    final nextEnd = _scoringService.createEnd(nextEndNumber, maxArrows: state.arrowsPerEnd);
    state = state.copyWith(currentEnd: nextEnd);
  }

  /// Manually add an extra end
  void addOneMoreEnd() {
    if (state.currentSession == null) return;
    
    // Increase max ends by 1
    final newMaxEnds = state.maxEnds + 1;
    state = state.copyWith(maxEnds: newMaxEnds);
    
    // Start the new end
    _startNextEnd();
  }

  /// Edit a specific end
  void editEnd(End end) {
    state = state.copyWith(currentEnd: end);
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

      // Do NOT reset state here to prevent UI from flashing to empty state before navigation
      state = state.copyWith(isSaving: false, currentSession: completedSession);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  /// Reset session state
  void resetSession() {
    state = const ScoringState();
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
