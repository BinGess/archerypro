import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

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
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<Offset> heatmapData;

  /// Score trend data points for chart
  /// Map of date to average score on that date
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Map<DateTime, double> scoreTrendData;

  /// Monthly goal (number of arrows)
  final int? monthlyGoal;

  /// Current month arrow count
  final int currentMonthArrows;

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
    required this.heatmapData,
    required this.scoreTrendData,
    this.monthlyGoal,
    required this.currentMonthArrows,
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
    );
  }

  // JSON serialization
  factory Statistics.fromJson(Map<String, dynamic> json) => _$StatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$StatisticsToJson(this);

  @override
  String toString() => 'Statistics(period: $period, sessions: $totalSessions, avg: ${avgArrowScore.toStringAsFixed(1)})';
}

/// Trend direction enum
enum TrendDirection {
  up,
  down,
  stable,
}
