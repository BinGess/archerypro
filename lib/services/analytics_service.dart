import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

import '../models/training_session.dart';
import '../models/statistics.dart';
import '../models/ai_insight.dart';
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
      case kPeriod3Months:
        cutoffDate = now.subtract(const Duration(days: 90));
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
        tendency = 'low-left';
      } else if (centerX > 0.15 && centerY < -0.15) {
        tendency = 'low-right';
      } else if (centerX < -0.15 && centerY > 0.15) {
        tendency = 'high-left';
      } else if (centerX > 0.15 && centerY > 0.15) {
        tendency = 'high-right';
      } else if (centerY < -0.15) {
        tendency = 'low';
      } else if (centerY > 0.15) {
        tendency = 'high';
      } else if (centerX < -0.15) {
        tendency = 'left';
      } else if (centerX > 0.15) {
        tendency = 'right';
      }

      if (tendency.isNotEmpty) {
        return AIInsight.drill(
          id: _uuid.v4(),
          title: 'Grouping Tendency: $tendency',
          description: 'Your shots are grouping $tendency of center. Practice blank bale drills focusing on alignment and release.',
          priority: 4,
        );
      }
    }

    return null;
  }
}
