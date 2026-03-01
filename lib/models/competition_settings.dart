/// Competition mode settings
class CompetitionSettings {
  final int arrowsPerEnd;
  final int timePerArrowSeconds;
  final bool soundEnabled;
  final int totalEnds;
  final bool useTargetScoring;

  /// WA standard: 10 seconds preparation
  static const int preparationTimeSeconds = 10;

  /// WA standard: warning at last 30 seconds
  static const int warningThresholdSeconds = 30;

  /// Total shooting time for one end
  int get shootingTimeSeconds => arrowsPerEnd * timePerArrowSeconds;

  const CompetitionSettings({
    this.arrowsPerEnd = 6,
    this.timePerArrowSeconds = 40,
    this.soundEnabled = true,
    this.totalEnds = 10,
    this.useTargetScoring = false,
  });

  CompetitionSettings copyWith({
    int? arrowsPerEnd,
    int? timePerArrowSeconds,
    bool? soundEnabled,
    int? totalEnds,
    bool? useTargetScoring,
  }) {
    return CompetitionSettings(
      arrowsPerEnd: arrowsPerEnd ?? this.arrowsPerEnd,
      timePerArrowSeconds: timePerArrowSeconds ?? this.timePerArrowSeconds,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      totalEnds: totalEnds ?? this.totalEnds,
      useTargetScoring: useTargetScoring ?? this.useTargetScoring,
    );
  }
}
