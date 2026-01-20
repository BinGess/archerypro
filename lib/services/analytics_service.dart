import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

import '../models/training_session.dart';
import '../models/statistics.dart';
import '../models/ai_insight.dart';
import '../models/radar_metrics.dart';
import '../utils/constants.dart';

/// Service for analytics and AI insights generation
class AnalyticsService {
  final _uuid = const Uuid();

  /// Calculate statistics for a given period
  Statistics calculateStatistics({
    required List<TrainingSession> sessions,
    required String period,
    int monthlyGoal = kDefaultMonthlyGoal,
  }) {
    if (sessions.isEmpty) {
      return Statistics.empty(period: period);
    }

    // Filter sessions based on period
    final filteredSessions = _filterSessionsByPeriod(sessions, period);

    if (filteredSessions.isEmpty) {
      return Statistics.empty(period: period);
    }

    // Calculate basic metrics
    final totalSessions = filteredSessions.length;
    final totalArrows = filteredSessions.fold(0, (sum, s) => sum + s.arrowCount);
    final totalScore = filteredSessions.fold(0, (sum, s) => sum + s.totalScore);
    final maxPossibleScore = filteredSessions.fold(0, (sum, s) => sum + s.maxScore);

    final avgArrowScore = totalArrows > 0 ? totalScore / totalArrows : 0.0;
    final avgEndScore = _calculateAverageEndScore(filteredSessions);

    // Find best session
    final bestSession = filteredSessions.reduce((best, current) {
      return current.scorePercentage > best.scorePercentage ? current : best;
    });

    // Calculate trend
    final trend = _calculateTrend(filteredSessions);

    // Calculate average consistency
    final avgConsistency = _calculateAverageConsistency(filteredSessions);

    // Get heatmap data
    final heatmapData = _getHeatmapData(filteredSessions);

    // Get score trend data for chart
    final scoreTrendData = _getScoreTrendData(filteredSessions);

    // Current month arrows
    final currentMonthArrows = _getCurrentMonthArrows(sessions);

    // Calculate 10-ring rate
    final tenRingRate = _calculate10RingRate(filteredSessions);

    // Calculate quadrant distribution
    final quadrantDistribution = _calculateQuadrantDistribution(filteredSessions);

    // Calculate radar metrics
    final radarMetrics = calculateRadarMetrics(filteredSessions);

    return Statistics(
      period: period,
      totalSessions: totalSessions,
      totalArrows: totalArrows,
      totalScore: totalScore,
      maxPossibleScore: maxPossibleScore,
      avgArrowScore: avgArrowScore,
      avgEndScore: avgEndScore,
      bestScore: bestSession.totalScore,
      bestMaxScore: bestSession.maxScore,
      trend: trend,
      avgConsistency: avgConsistency,
      heatmapData: heatmapData,
      scoreTrendData: scoreTrendData,
      monthlyGoal: monthlyGoal,
      currentMonthArrows: currentMonthArrows,
      tenRingRate: tenRingRate,
      quadrantDistribution: quadrantDistribution,
      radarMetrics: radarMetrics,
    );
  }

  /// Generate AI insights based on statistics and recent sessions
  List<AIInsight> generateInsights({
    required Statistics stats,
    required List<TrainingSession> recentSessions,
  }) {
    final insights = <AIInsight>[];

    if (recentSessions.length < kMinSessionsForInsights) {
      return insights;
    }

    // Check for consistency issues
    if (stats.avgConsistency < kMediumConsistencyThreshold) {
      insights.add(AIInsight.stability(
        id: _uuid.v4(),
        title: 'Stability Focus Needed',
        description: 'Your consistency is at ${stats.avgConsistency.toStringAsFixed(1)}%. Focus on back tension and maintain expansion through the clicker.',
        priority: 4,
      ));
    }

    // Check for declining performance
    if (stats.trend < -2.0) {
      insights.add(AIInsight.warning(
        id: _uuid.v4(),
        title: 'Performance Decline Detected',
        description: 'Your average score has decreased by ${stats.trend.abs().toStringAsFixed(1)}% recently. Consider taking a rest day or reviewing your form.',
        priority: 5,
      ));
    }

    // Check for improvement
    if (stats.trend > 3.0) {
      insights.add(AIInsight.achievement(
        id: _uuid.v4(),
        title: 'Great Progress!',
        description: 'You\'ve improved by ${stats.trend.toStringAsFixed(1)}% in this period. Keep up the excellent work!',
        priority: 2,
      ));
    }

    // Analyze shot grouping from heatmap
    final groupingInsight = _analyzeGrouping(stats.heatmapData);
    if (groupingInsight != null) {
      insights.add(groupingInsight);
    }

    // Suggest drills based on performance
    if (stats.avgArrowScore < kGoodScoreThreshold) {
      insights.add(AIInsight.drill(
        id: _uuid.v4(),
        title: 'Suggestion: Distance Practice',
        description: 'To improve accuracy, perform 30 arrows on blank bale focusing on bow arm stability and release.',
        priority: 4,
      ));
    }

    // Sort by priority (highest first)
    insights.sort((a, b) => b.priority.compareTo(a.priority));

    return insights.take(3).toList(); // Return top 3 insights
  }

  /// Filter sessions by period
  List<TrainingSession> _filterSessionsByPeriod(List<TrainingSession> sessions, String period) {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (period) {
      case kPeriod7Days:
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case kPeriod1Month:
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case kPeriodCurrentYear:
        // Start of current year
        cutoffDate = DateTime(now.year, 1, 1);
        break;
      case kPeriodAll:
      default:
        return sessions;
    }

    return sessions.where((s) => s.date.isAfter(cutoffDate)).toList();
  }

  /// Calculate average end score across sessions
  double _calculateAverageEndScore(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0.0;
    final totalEndScore = sessions.fold(0.0, (sum, s) => sum + s.averageEndScore);
    return totalEndScore / sessions.length;
  }

  /// Calculate performance trend
  double _calculateTrend(List<TrainingSession> sessions) {
    if (sessions.length < 2) return 0.0;

    // Sort by date
    final sorted = List<TrainingSession>.from(sessions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Split into two halves
    final midpoint = sorted.length ~/ 2;
    final firstHalf = sorted.sublist(0, midpoint);
    final secondHalf = sorted.sublist(midpoint);

    if (firstHalf.isEmpty || secondHalf.isEmpty) return 0.0;

    final firstAvg = firstHalf.fold(0.0, (sum, s) => sum + s.averageArrowScore) / firstHalf.length;
    final secondAvg = secondHalf.fold(0.0, (sum, s) => sum + s.averageArrowScore) / secondHalf.length;

    if (firstAvg == 0) return 0.0;

    return ((secondAvg - firstAvg) / firstAvg) * 100;
  }

  /// Calculate average consistency across sessions
  double _calculateAverageConsistency(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0.0;
    final totalConsistency = sessions.fold(0.0, (sum, s) => sum + s.consistency);
    return totalConsistency / sessions.length;
  }

  /// Get heatmap data from all arrows
  List<Offset> _getHeatmapData(List<TrainingSession> sessions) {
    final positions = <Offset>[];
    for (final session in sessions) {
      positions.addAll(session.heatmapPositions);
    }
    return positions;
  }

  /// Get score trend data for charts
  Map<DateTime, double> _getScoreTrendData(List<TrainingSession> sessions) {
    final trendData = <DateTime, double>{};

    for (final session in sessions) {
      final date = DateTime(session.date.year, session.date.month, session.date.day);
      trendData[date] = session.averageArrowScore;
    }

    return trendData;
  }

  /// Get current month arrow count
  int _getCurrentMonthArrows(List<TrainingSession> sessions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return sessions
        .where((s) => s.date.isAfter(startOfMonth.subtract(const Duration(days: 1))))
        .fold(0, (sum, s) => sum + s.arrowCount);
  }

  /// Analyze shot grouping and generate insight
  AIInsight? _analyzeGrouping(List<Offset> positions) {
    if (positions.length < kMinArrowsForHeatmap) return null;

    // Calculate center of mass
    final centerX = positions.fold(0.0, (sum, p) => sum + p.dx) / positions.length;
    final centerY = positions.fold(0.0, (sum, p) => sum + p.dy) / positions.length;

    // Determine tendency
    String tendency = '';
    if (centerX.abs() > 0.15 || centerY.abs() > 0.15) {
      if (centerX < -0.15 && centerY < -0.15) {
        tendency = '左下';
      } else if (centerX > 0.15 && centerY < -0.15) {
        tendency = '右下';
      } else if (centerX < -0.15 && centerY > 0.15) {
        tendency = '左上';
      } else if (centerX > 0.15 && centerY > 0.15) {
        tendency = '右上';
      } else if (centerY < -0.15) {
        tendency = '偏下';
      } else if (centerY > 0.15) {
        tendency = '偏上';
      } else if (centerX < -0.15) {
        tendency = '偏左';
      } else if (centerX > 0.15) {
        tendency = '偏右';
      }

      if (tendency.isNotEmpty) {
        return AIInsight.drill(
          id: _uuid.v4(),
          title: '分组倾向：$tendency',
          description: '你的箭组倾向于靶心$tendency方。请练习光靶，专注于对齐和撒放。',
          priority: 4,
        );
      }
    }

    return null;
  }

  // ==================== New Analysis Methods ====================

  /// Calculate 10-ring rate across all sessions
  double _calculate10RingRate(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0.0;

    final total10Rings = sessions.fold(0, (sum, s) => sum + s.goldRingCount);
    final totalArrows = sessions.fold(0, (sum, s) => sum + s.arrowCount);

    if (totalArrows == 0) return 0.0;
    return (total10Rings / totalArrows) * 100;
  }

  /// Calculate aggregated quadrant distribution across all sessions
  Map<String, int> _calculateQuadrantDistribution(List<TrainingSession> sessions) {
    final aggregated = {
      'top-left': 0,
      'top-right': 0,
      'bottom-left': 0,
      'bottom-right': 0,
    };

    for (final session in sessions) {
      final distribution = session.quadrantDistribution;
      aggregated['top-left'] = aggregated['top-left']! + (distribution['top-left'] ?? 0);
      aggregated['top-right'] = aggregated['top-right']! + (distribution['top-right'] ?? 0);
      aggregated['bottom-left'] = aggregated['bottom-left']! + (distribution['bottom-left'] ?? 0);
      aggregated['bottom-right'] = aggregated['bottom-right']! + (distribution['bottom-right'] ?? 0);
    }

    return aggregated;
  }

  /// Calculate radar metrics from session list
  /// Returns averaged radar metrics across all sessions
  RadarMetrics? calculateRadarMetrics(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return null;

    // Calculate aggregate values
    final avgArrowScore = sessions.fold(0.0, (sum, s) => sum + s.averageArrowScore) / sessions.length;
    final avgConsistency = sessions.fold(0.0, (sum, s) => sum + s.consistency) / sessions.length;
    final avg10RingRate = sessions.fold(0.0, (sum, s) => sum + s.tenRingRate) / sessions.length;
    final avgGroupingRadius = sessions.fold(0.0, (sum, s) => sum + s.groupingRadius) / sessions.length;
    final avgFirstThird = sessions.fold(0.0, (sum, s) => sum + s.firstThirdAverage) / sessions.length;
    final avgLastThird = sessions.fold(0.0, (sum, s) => sum + s.lastThirdAverage) / sessions.length;
    final avgCenterDeviation = sessions.fold(0.0, (sum, s) => sum + s.centerDeviation) / sessions.length;

    return RadarMetrics.fromSessionData(
      avgArrowScore: avgArrowScore,
      consistency: avgConsistency,
      tenRingRate: avg10RingRate,
      groupingRadius: avgGroupingRadius,
      firstThirdAvg: avgFirstThird,
      lastThirdAvg: avgLastThird,
      centerDeviation: avgCenterDeviation,
    );
  }

  /// Detect plateau in performance (stagnation)
  /// Returns true if average score has remained flat (±1%) for recent sessions
  bool detectPlateau(List<TrainingSession> recentSessions) {
    if (recentSessions.length < 5) return false;

    // Sort by date
    final sorted = List<TrainingSession>.from(recentSessions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Take last 5 sessions
    final last5 = sorted.length > 5 ? sorted.sublist(sorted.length - 5) : sorted;

    // Calculate variance in average scores
    final scores = last5.map((s) => s.averageArrowScore).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;

    if (mean == 0) return false;

    // Check if all scores are within ±1% of mean
    final allWithinRange = scores.every((score) {
      final deviation = ((score - mean).abs() / mean) * 100;
      return deviation < 1.0;
    });

    return allWithinRange;
  }

  /// Detect volume decline in training frequency
  /// Compares current period with previous period
  bool detectVolumeDecline(Statistics current, Statistics previous) {
    if (previous.totalArrows == 0) return false;

    final decline = ((previous.totalArrows - current.totalArrows) / previous.totalArrows) * 100;
    return decline > 30.0; // 30% decline threshold
  }

  /// Generate periodic AI insights for comprehensive analysis
  /// This is used in the analysis page for longer-term trends
  List<PeriodInsight> generatePeriodInsights({
    required Statistics currentStats,
    Statistics? previousStats,
    required List<TrainingSession> recentSessions,
  }) {
    final insights = <PeriodInsight>[];

    // Insight 1: Plateau detection
    if (detectPlateau(recentSessions)) {
      insights.add(PeriodInsight(
        type: PeriodInsightType.plateau,
        title: '平台期识别',
        message: '近期成绩进入平台期，建议尝试新的训练方法或技术调整以突破瓶颈。',
        icon: Icons.trending_flat,
        color: Colors.orange,
        actionable: true,
      ));
    }

    // Insight 2: Volume decline warning
    if (previousStats != null && detectVolumeDecline(currentStats, previousStats)) {
      final decline = ((previousStats.totalArrows - currentStats.totalArrows) / previousStats.totalArrows * 100)
          .toStringAsFixed(0);
      insights.add(PeriodInsight(
        type: PeriodInsightType.volumeWarning,
        title: '训练量下降预警',
        message: '本周期训练量较上周期下降${decline}%，建议增加训练频次或进行恢复性训练。',
        icon: Icons.warning_amber,
        color: Colors.red,
        actionable: true,
      ));
    }

    // Insight 3: Advanced progression suggestion
    if (currentStats.tenRingRate > 60.0 && currentStats.avgConsistency > 85.0) {
      insights.add(PeriodInsight(
        type: PeriodInsightType.advancement,
        title: '进阶建议',
        message: '10环率达到${currentStats.tenRingRate.toStringAsFixed(1)}%且稳定性优秀，'
            '建议尝试增加射击距离或提高难度。',
        icon: Icons.arrow_upward,
        color: Colors.green,
        actionable: true,
      ));
    }

    // Insight 4: Chronic bias detection
    final quadrants = currentStats.quadrantDistribution;
    final totalBelowNine = quadrants.values.fold(0, (sum, count) => sum + count);
    if (totalBelowNine > 20) {
      // Find dominant quadrant
      final maxQuadrant = quadrants.entries.reduce((a, b) => a.value > b.value ? a : b);
      final dominancePercentage = (maxQuadrant.value / totalBelowNine * 100);

      if (dominancePercentage > 40.0) {
        final quadrantName = _getQuadrantNameChinese(maxQuadrant.key);
        insights.add(PeriodInsight(
          type: PeriodInsightType.chronicBias,
          title: '顽固偏差诊断',
          message: '脱靶箭支${dominancePercentage.toStringAsFixed(0)}%偏向$quadrantName，'
              '建议针对性调整动作或器材。',
          icon: Icons.gps_fixed,
          color: Colors.purple,
          actionable: true,
        ));
      }
    }

    // Insight 5: Consistency achievement
    if (currentStats.avgConsistency > 90.0) {
      insights.add(PeriodInsight(
        type: PeriodInsightType.excellence,
        title: '稳定性优秀',
        message: '稳定性达到${currentStats.avgConsistency.toStringAsFixed(1)}%，动作一致性表现优异！',
        icon: Icons.emoji_events,
        color: Colors.amber,
        actionable: false,
      ));
    }

    return insights;
  }

  /// Get Chinese name for quadrant
  String _getQuadrantNameChinese(String quadrantKey) {
    switch (quadrantKey) {
      case 'top-left':
        return '左上';
      case 'top-right':
        return '右上';
      case 'bottom-left':
        return '左下';
      case 'bottom-right':
        return '右下';
      default:
        return quadrantKey;
    }
  }
}

/// Period insight model for comprehensive analysis
class PeriodInsight {
  final PeriodInsightType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final bool actionable;

  const PeriodInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.actionable,
  });
}

/// Period insight type enum
enum PeriodInsightType {
  plateau,       // Performance stagnation
  volumeWarning, // Training volume decline
  advancement,   // Ready for next level
  chronicBias,   // Persistent directional bias
  excellence,    // Outstanding achievement
}
