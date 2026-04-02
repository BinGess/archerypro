import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'radar_metrics.dart';
import 'competition_profile.dart';

part 'statistics.g.dart';

/// Statistical data for performance analysis
@JsonSerializable()
class Statistics {
  /// Time period for these statistics (e.g., '7D', '1M', '3M', 'ALL')
  final String period;

  /// Total number of training sessions
  final int totalSessions;

  /// Total number of arrows shot
  final int totalArrows;

  /// Total score across all sessions
  final int totalScore;

  /// Maximum possible score
  final int maxPossibleScore;

  /// Average score per arrow
  final double avgArrowScore;

  /// Average score per end
  final double avgEndScore;

  /// Best session score
  final int bestScore;

  /// Best session max score
  final int bestMaxScore;

  /// Trend percentage (positive = improvement, negative = decline)
  final double trend;

  /// Average consistency across sessions
  final double avgConsistency;

  /// Heatmap data - all arrow positions
  @JsonKey(includeFromJson: false, includeToJson: false, defaultValue: [])
  final List<Offset> heatmapData;

  /// Score trend data points for chart
  /// Map of date to average score on that date
  @JsonKey(includeFromJson: false, includeToJson: false, defaultValue: {})
  final Map<DateTime, double> scoreTrendData;

  /// Monthly goal (number of arrows)
  final int? monthlyGoal;

  /// Current month arrow count
  final int currentMonthArrows;

  /// 10-ring rate (percentage of arrows hitting 10 or X)
  final double tenRingRate;

  /// X rate (percentage of arrows hitting X ring)
  final double xRate;

  /// High value hit rate (percentage of arrows scoring 9+)
  final double highValueRate;

  /// Miss rate (percentage of misses)
  final double missRate;

  /// Quadrant distribution for bias detection
  /// Map of quadrant name to count of arrows
  @JsonKey(defaultValue: {})
  final Map<String, int> quadrantDistribution;

  /// Bias distribution split by score band.
  /// Example:
  /// {
  ///   "high": {"top-left": 2, ...},
  ///   "mid":  {"top-left": 3, ...},
  ///   "low":  {"top-left": 4, ...}
  /// }
  @JsonKey(defaultValue: {})
  final Map<String, Map<String, int>> biasByScoreBand;

  /// Radar metrics for comprehensive performance visualization
  final RadarMetrics? radarMetrics;

  /// Dominant competition profile in current dataset
  @JsonKey(includeFromJson: false, includeToJson: false)
  final CompetitionProfile? competitionProfile;

  /// Competition profile key
  final String competitionProfileKey;

  /// Qualification projection score in profile arrow count
  final double projectedQualificationScore;

  /// Qualification tier label
  final String qualificationTier;

  /// Volatility of normalized end totals
  final double endVolatility;

  /// Rate of collapsed ends in normalized scoring
  final double collapseRate;

  /// Recovery index after collapsed ends
  final double recoveryIndex;

  /// Endurance hold rate (late vs early performance)
  final double enduranceHoldRate;

  /// Session-level clutch proxy aggregated in period
  final double clutchProxy;

  /// Average quality density (9+ hit ratio by end)
  final double qualityDensity;

  /// Arrow volume aggregated per day
  @JsonKey(includeFromJson: false, includeToJson: false, defaultValue: {})
  final Map<DateTime, int> dailyArrowVolumeData;

  const Statistics({
    required this.period,
    required this.totalSessions,
    required this.totalArrows,
    required this.totalScore,
    required this.maxPossibleScore,
    required this.avgArrowScore,
    required this.avgEndScore,
    required this.bestScore,
    required this.bestMaxScore,
    required this.trend,
    required this.avgConsistency,
    this.heatmapData = const [],
    this.scoreTrendData = const {},
    this.monthlyGoal,
    required this.currentMonthArrows,
    this.tenRingRate = 0.0,
    this.xRate = 0.0,
    this.highValueRate = 0.0,
    this.missRate = 0.0,
    this.quadrantDistribution = const {},
    this.biasByScoreBand = const {},
    this.radarMetrics,
    this.competitionProfile,
    this.competitionProfileKey = 'generic',
    this.projectedQualificationScore = 0.0,
    this.qualificationTier = 'White',
    this.endVolatility = 0.0,
    this.collapseRate = 0.0,
    this.recoveryIndex = 0.0,
    this.enduranceHoldRate = 0.0,
    this.clutchProxy = 0.0,
    this.qualityDensity = 0.0,
    this.dailyArrowVolumeData = const {},
  });

  /// Empty statistics
  factory Statistics.empty({String period = 'ALL'}) {
    return Statistics(
      period: period,
      totalSessions: 0,
      totalArrows: 0,
      totalScore: 0,
      maxPossibleScore: 0,
      avgArrowScore: 0.0,
      avgEndScore: 0.0,
      bestScore: 0,
      bestMaxScore: 0,
      trend: 0.0,
      avgConsistency: 0.0,
      heatmapData: const [],
      scoreTrendData: const {},
      currentMonthArrows: 0,
      tenRingRate: 0.0,
      xRate: 0.0,
      highValueRate: 0.0,
      missRate: 0.0,
      quadrantDistribution: const {},
      biasByScoreBand: const {},
      radarMetrics: null,
      competitionProfile: CompetitionProfile.generic,
      competitionProfileKey: CompetitionProfile.generic.key,
      projectedQualificationScore: 0.0,
      qualificationTier: 'White',
      endVolatility: 0.0,
      collapseRate: 0.0,
      recoveryIndex: 0.0,
      enduranceHoldRate: 0.0,
      clutchProxy: 0.0,
      qualityDensity: 0.0,
      dailyArrowVolumeData: const {},
    );
  }

  /// Overall percentage score
  double get scorePercentage {
    if (maxPossibleScore == 0) return 0.0;
    return (totalScore / maxPossibleScore) * 100;
  }

  /// Best session percentage
  double get bestScorePercentage {
    if (bestMaxScore == 0) return 0.0;
    return (bestScore / bestMaxScore) * 100;
  }

  /// Formatted best score (e.g., "590/600")
  String get bestScoreDisplay => '$bestScore/$bestMaxScore';

  /// Monthly goal progress percentage
  double get monthlyGoalProgress {
    if (monthlyGoal == null || monthlyGoal == 0) return 0.0;
    return (currentMonthArrows / monthlyGoal!) * 100;
  }

  /// Is monthly goal achieved
  bool get isMonthlyGoalAchieved {
    if (monthlyGoal == null) return false;
    return currentMonthArrows >= monthlyGoal!;
  }

  /// Trend direction
  TrendDirection get trendDirection {
    if (trend > 0.5) return TrendDirection.up;
    if (trend < -0.5) return TrendDirection.down;
    return TrendDirection.stable;
  }

  /// Formatted trend display (e.g., "+5.2%")
  String get trendDisplay {
    final sign = trend >= 0 ? '+' : '';
    return '$sign${trend.toStringAsFixed(1)}%';
  }

  /// Copy with method
  Statistics copyWith({
    String? period,
    int? totalSessions,
    int? totalArrows,
    int? totalScore,
    int? maxPossibleScore,
    double? avgArrowScore,
    double? avgEndScore,
    int? bestScore,
    int? bestMaxScore,
    double? trend,
    double? avgConsistency,
    List<Offset>? heatmapData,
    Map<DateTime, double>? scoreTrendData,
    int? monthlyGoal,
    int? currentMonthArrows,
    double? tenRingRate,
    double? xRate,
    double? highValueRate,
    double? missRate,
    Map<String, int>? quadrantDistribution,
    Map<String, Map<String, int>>? biasByScoreBand,
    RadarMetrics? radarMetrics,
    CompetitionProfile? competitionProfile,
    String? competitionProfileKey,
    double? projectedQualificationScore,
    String? qualificationTier,
    double? endVolatility,
    double? collapseRate,
    double? recoveryIndex,
    double? enduranceHoldRate,
    double? clutchProxy,
    double? qualityDensity,
    Map<DateTime, int>? dailyArrowVolumeData,
  }) {
    return Statistics(
      period: period ?? this.period,
      totalSessions: totalSessions ?? this.totalSessions,
      totalArrows: totalArrows ?? this.totalArrows,
      totalScore: totalScore ?? this.totalScore,
      maxPossibleScore: maxPossibleScore ?? this.maxPossibleScore,
      avgArrowScore: avgArrowScore ?? this.avgArrowScore,
      avgEndScore: avgEndScore ?? this.avgEndScore,
      bestScore: bestScore ?? this.bestScore,
      bestMaxScore: bestMaxScore ?? this.bestMaxScore,
      trend: trend ?? this.trend,
      avgConsistency: avgConsistency ?? this.avgConsistency,
      heatmapData: heatmapData ?? this.heatmapData,
      scoreTrendData: scoreTrendData ?? this.scoreTrendData,
      monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      currentMonthArrows: currentMonthArrows ?? this.currentMonthArrows,
      tenRingRate: tenRingRate ?? this.tenRingRate,
      xRate: xRate ?? this.xRate,
      highValueRate: highValueRate ?? this.highValueRate,
      missRate: missRate ?? this.missRate,
      quadrantDistribution: quadrantDistribution ?? this.quadrantDistribution,
      biasByScoreBand: biasByScoreBand ?? this.biasByScoreBand,
      radarMetrics: radarMetrics ?? this.radarMetrics,
      competitionProfile: competitionProfile ?? this.competitionProfile,
      competitionProfileKey:
          competitionProfileKey ?? this.competitionProfileKey,
      projectedQualificationScore:
          projectedQualificationScore ?? this.projectedQualificationScore,
      qualificationTier: qualificationTier ?? this.qualificationTier,
      endVolatility: endVolatility ?? this.endVolatility,
      collapseRate: collapseRate ?? this.collapseRate,
      recoveryIndex: recoveryIndex ?? this.recoveryIndex,
      enduranceHoldRate: enduranceHoldRate ?? this.enduranceHoldRate,
      clutchProxy: clutchProxy ?? this.clutchProxy,
      qualityDensity: qualityDensity ?? this.qualityDensity,
      dailyArrowVolumeData: dailyArrowVolumeData ?? this.dailyArrowVolumeData,
    );
  }

  // JSON serialization
  factory Statistics.fromJson(Map<String, dynamic> json) =>
      _$StatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$StatisticsToJson(this);

  @override
  String toString() =>
      'Statistics(period: $period, sessions: $totalSessions, avg: ${avgArrowScore.toStringAsFixed(1)})';
}

/// Trend direction enum
enum TrendDirection {
  up,
  down,
  stable,
}
