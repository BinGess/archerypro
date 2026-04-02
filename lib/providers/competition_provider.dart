import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/competition_settings.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';

int _effectiveCompetitionScore(int rawScore) {
  return rawScore == kXRingScore ? 10 : rawScore;
}

/// Competition phase enum
enum CompetitionPhase {
  wait,
  preparation,
  shooting,
  warning,
  timesUp,
  scoring,
  finished,
}

/// End result for competition mode
class CompetitionEndResult {
  final int endNumber;
  final List<int> arrowScores;
  final int totalScore;
  final Duration shootingTime;

  CompetitionEndResult({
    required this.endNumber,
    required this.arrowScores,
    this.shootingTime = Duration.zero,
  }) : totalScore =
            arrowScores.fold(0, (a, b) => a + _effectiveCompetitionScore(b));
}

/// Competition state
class CompetitionState {
  final CompetitionPhase phase;
  final int currentEnd;
  final int remainingSeconds;
  final bool isPaused;
  final List<CompetitionEndResult> endResults;
  final List<int> currentArrowScores;
  final CompetitionSettings settings;

  const CompetitionState({
    this.phase = CompetitionPhase.wait,
    this.currentEnd = 1,
    this.remainingSeconds = 0,
    this.isPaused = false,
    this.endResults = const [],
    this.currentArrowScores = const [],
    required this.settings,
  });

  int get totalScore => endResults.fold(0, (a, r) => a + r.totalScore);

  bool get isTimerActive =>
      phase == CompetitionPhase.preparation ||
      phase == CompetitionPhase.shooting ||
      phase == CompetitionPhase.warning;

  bool get canSubmitScores =>
      currentArrowScores.length == settings.arrowsPerEnd;

  int get totalShootingTime => settings.shootingTimeSeconds;

  CompetitionState copyWith({
    CompetitionPhase? phase,
    int? currentEnd,
    int? remainingSeconds,
    bool? isPaused,
    List<CompetitionEndResult>? endResults,
    List<int>? currentArrowScores,
    CompetitionSettings? settings,
  }) {
    return CompetitionState(
      phase: phase ?? this.phase,
      currentEnd: currentEnd ?? this.currentEnd,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isPaused: isPaused ?? this.isPaused,
      endResults: endResults ?? this.endResults,
      currentArrowScores: currentArrowScores ?? this.currentArrowScores,
      settings: settings ?? this.settings,
    );
  }
}

/// Competition state notifier
class CompetitionNotifier extends StateNotifier<CompetitionState> {
  final AudioService _audioService;
  Timer? _timer;
  DateTime? _targetEndTime;
  DateTime? _shootingStartTime;

  CompetitionNotifier(CompetitionSettings settings,
      {AudioService? audioService})
      : _audioService = audioService ?? AudioService(),
        super(CompetitionState(settings: settings));

  /// Start an end: wait -> preparation
  void startEnd() {
    state = state.copyWith(
      phase: CompetitionPhase.preparation,
      remainingSeconds: CompetitionSettings.preparationTimeSeconds,
    );
    WakelockPlus.enable();
    _startTimer();
    if (state.settings.soundEnabled) _audioService.playShortWhistles(2);
  }

  /// Timer tick handler
  void _onTimerTick() {
    if (state.phase == CompetitionPhase.preparation) {
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        _onPreparationComplete();
        return;
      }
      state = state.copyWith(remainingSeconds: remaining);
    } else {
      // Drift-compensated for shooting/warning
      if (_targetEndTime != null) {
        final now = DateTime.now();
        var remaining = _targetEndTime!.difference(now).inSeconds;
        if (remaining < 0) remaining = 0;
        state = state.copyWith(remainingSeconds: remaining);
      }

      // Check for warning transition
      if (state.phase == CompetitionPhase.shooting &&
          state.remainingSeconds <=
              CompetitionSettings.warningThresholdSeconds) {
        state = state.copyWith(phase: CompetitionPhase.warning);
        HapticFeedback.heavyImpact();
      }

      // Check for time's up
      if (state.remainingSeconds <= 0) {
        _onTimesUp();
        return;
      }
    }
  }

  /// Preparation complete -> shooting
  void _onPreparationComplete() {
    _shootingStartTime = DateTime.now();
    _targetEndTime = DateTime.now().add(
      Duration(seconds: state.settings.shootingTimeSeconds),
    );
    state = state.copyWith(
      phase: CompetitionPhase.shooting,
      remainingSeconds: state.settings.shootingTimeSeconds,
    );
    if (state.settings.soundEnabled) _audioService.playLongWhistle();
  }

  /// Time's up handler
  void _onTimesUp() {
    _cancelTimer();
    state = state.copyWith(
      phase: CompetitionPhase.timesUp,
      remainingSeconds: 0,
    );
    if (state.settings.soundEnabled) _audioService.playStopWhistles();
    HapticFeedback.heavyImpact();

    // Auto-transition to scoring after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (state.phase == CompetitionPhase.timesUp) {
        _transitionToScoring();
      }
    });
  }

  /// Transition to scoring phase
  void _transitionToScoring() {
    state = state.copyWith(
      phase: CompetitionPhase.scoring,
      currentArrowScores: [],
    );
    WakelockPlus.disable();
  }

  /// Skip handler:
  /// - preparation -> shooting (only skip preparation countdown)
  /// - shooting/warning/timesUp -> scoring
  void skipToScoring() {
    if (state.phase == CompetitionPhase.preparation) {
      _onPreparationComplete();
      return;
    }

    if (state.phase == CompetitionPhase.shooting ||
        state.phase == CompetitionPhase.warning ||
        state.phase == CompetitionPhase.timesUp) {
      _cancelTimer();
      if (state.settings.soundEnabled) _audioService.playStopWhistles();
      _transitionToScoring();
    }
  }

  // === Scoring ===

  void addArrowScore(int score) {
    if (state.currentArrowScores.length < state.settings.arrowsPerEnd) {
      state = state.copyWith(
        currentArrowScores: [...state.currentArrowScores, score],
      );
    }
  }

  void removeLastArrowScore() {
    if (state.currentArrowScores.isNotEmpty) {
      final scores = [...state.currentArrowScores]..removeLast();
      state = state.copyWith(currentArrowScores: scores);
    }
  }

  void submitScores({bool force = false}) {
    if (!force && !state.canSubmitScores) return;

    final shootingTime = _shootingStartTime != null
        ? DateTime.now().difference(_shootingStartTime!)
        : Duration.zero;

    final result = CompetitionEndResult(
      endNumber: state.currentEnd,
      arrowScores: List.from(state.currentArrowScores),
      shootingTime: shootingTime,
    );

    final newResults = [...state.endResults, result];

    if (state.currentEnd >= state.settings.totalEnds) {
      state = state.copyWith(
        phase: CompetitionPhase.finished,
        endResults: newResults,
        currentArrowScores: [],
      );
    } else {
      state = state.copyWith(
        phase: CompetitionPhase.wait,
        currentEnd: state.currentEnd + 1,
        endResults: newResults,
        currentArrowScores: [],
      );
    }
  }

  // === Pause/Resume ===

  void pause() {
    if (!state.isTimerActive) return;
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.isPaused) return;
    // Recalculate target end time for drift compensation
    if (state.phase == CompetitionPhase.shooting ||
        state.phase == CompetitionPhase.warning) {
      _targetEndTime = DateTime.now().add(
        Duration(seconds: state.remainingSeconds),
      );
    }
    state = state.copyWith(isPaused: false);
    _startTimer();
  }

  void resetCurrentEnd() {
    _cancelTimer();
    state = state.copyWith(
      phase: CompetitionPhase.wait,
      isPaused: false,
      currentArrowScores: [],
    );
    WakelockPlus.disable();
  }

  // === Timer Management ===

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTimerTick();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    WakelockPlus.disable();
    _audioService.dispose();
    super.dispose();
  }
}

/// Riverpod provider for competition state
final competitionProvider = StateNotifierProvider.autoDispose
    .family<CompetitionNotifier, CompetitionState, CompetitionSettings>(
  (ref, settings) => CompetitionNotifier(settings),
);
