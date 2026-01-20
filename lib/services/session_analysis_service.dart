import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/training_session.dart';

/// AI-driven analysis service for individual training sessions
/// Provides actionable insights based on 5 detection dimensions
class SessionAnalysisService {
  /// Generate primary insight for a training session
  /// Returns the most important advice based on priority:
  /// 1. Equipment/Sight issues (highest priority)
  /// 2. Endurance/Fatigue issues
  /// 3. Slow start/Warm-up issues
  /// 4. Stability/Consistency issues
  /// 5. Excellent performance (encouragement)
  SessionInsight generateSessionInsight(
    TrainingSession session,
    List<TrainingSession> historicalSessions,
  ) {
    // Ensure session has sufficient data
    if (session.arrowCount < 6 || session.ends.length < 2) {
      return SessionInsight.insufficient();
    }

    // Priority 1: Equipment/Sight adjustment detection
    final equipmentInsight = _detectEquipmentIssue(session);
    if (equipmentInsight != null) return equipmentInsight;

    // Priority 2: Endurance/Fatigue detection
    final enduranceInsight = _detectEnduranceIssue(session);
    if (enduranceInsight != null) return enduranceInsight;

    // Priority 3: Slow start/Warm-up detection
    final warmUpInsight = _detectSlowStart(session);
    if (warmUpInsight != null) return warmUpInsight;

    // Priority 4: Stability/Consistency detection
    final stabilityInsight = _detectStabilityIssue(session);
    if (stabilityInsight != null) return stabilityInsight;

    // Priority 5: Excellent performance recognition
    final excellenceInsight = _detectExcellentPerformance(
      session,
      historicalSessions,
    );
    if (excellenceInsight != null) return excellenceInsight;

    // Default: General positive feedback
    return SessionInsight.general();
  }

  /// Detector 1: Equipment/Sight adjustment needed
  /// Triggers when geometric center is significantly offset from bullseye
  SessionInsight? _detectEquipmentIssue(TrainingSession session) {
    final centerDeviation = session.centerDeviation;

    // Threshold: 0.2 normalized units (20% of target radius)
    if (centerDeviation > 0.2) {
      // Determine direction for specific advice
      final center = session.geometricCenter;
      if (center == null) return null;

      String direction = '';
      if (center.dx.abs() > center.dy.abs()) {
        direction = center.dx > 0 ? '右侧' : '左侧';
      } else {
        direction = center.dy > 0 ? '下方' : '上方';
      }

      return SessionInsight(
        type: InsightType.equipment,
        title: '器材/瞄具调整建议',
        message: '箭支整体偏向$direction，建议微调瞄具或检查器材设置。',
        icon: Icons.tune,
        color: Colors.orange,
        severity: InsightSeverity.high,
      );
    }

    return null;
  }

  /// Detector 2: Endurance/Fatigue issue
  /// Triggers when performance drops significantly in later ends
  SessionInsight? _detectEnduranceIssue(TrainingSession session) {
    if (session.ends.length < 3) return null;

    final firstThirdAvg = session.firstThirdAverage;
    final lastThirdAvg = session.lastThirdAverage;

    if (firstThirdAvg == 0) return null;

    // Calculate performance drop percentage
    final dropPercentage = ((firstThirdAvg - lastThirdAvg) / firstThirdAvg) * 100;

    // Threshold: 15% performance drop
    if (dropPercentage > 15.0) {
      return SessionInsight(
        type: InsightType.endurance,
        title: '体能/耐力提醒',
        message: '后段组别表现下降${dropPercentage.toStringAsFixed(1)}%，'
            '建议增加组间休息时间或进行体能训练。',
        icon: Icons.battery_alert,
        color: Colors.red,
        severity: InsightSeverity.high,
      );
    }

    return null;
  }

  /// Detector 3: Slow start/Warm-up issue
  /// Triggers when first 1-2 ends perform below session average
  SessionInsight? _detectSlowStart(TrainingSession session) {
    if (session.ends.length < 3) return null;

    final overallAvg = session.averageArrowScore;
    final endScores = session.endAverageScores;

    // Check if first 2 ends are both below average
    final firstEndsCount = math.min(2, endScores.length);
    final firstEndsBelow = endScores
        .take(firstEndsCount)
        .where((score) => score < overallAvg - 0.5) // 0.5 point tolerance
        .length;

    if (firstEndsBelow >= firstEndsCount) {
      return SessionInsight(
        type: InsightType.warmUp,
        title: '状态慢热提醒',
        message: '前几组表现低于整体水平，建议增加热身时间和空拉练习。',
        icon: Icons.wb_sunny_outlined,
        color: Colors.blue,
        severity: InsightSeverity.medium,
      );
    }

    return null;
  }

  /// Detector 4: Stability/Consistency issue
  /// Triggers when center is good but grouping is poor
  SessionInsight? _detectStabilityIssue(TrainingSession session) {
    final centerDeviation = session.centerDeviation;
    final groupingRadius = session.groupingRadius;

    // Good center (<15% deviation) but poor grouping (>25% scatter)
    if (centerDeviation < 0.15 && groupingRadius > 0.25) {
      return SessionInsight(
        type: InsightType.stability,
        title: '稳定性改进建议',
        message: '瞄准方向正确但箭支散布较大，建议专注于动作一致性训练。',
        icon: Icons.center_focus_weak,
        color: Colors.amber,
        severity: InsightSeverity.medium,
      );
    }

    return null;
  }

  /// Detector 5: Excellent performance recognition
  /// Triggers when performance exceeds historical average with high consistency
  SessionInsight? _detectExcellentPerformance(
    TrainingSession session,
    List<TrainingSession> historicalSessions,
  ) {
    // Need at least 5 historical sessions for meaningful comparison
    if (historicalSessions.length < 5) return null;

    // Calculate historical average
    final historicalAvg = historicalSessions
            .map((s) => s.averageArrowScore)
            .reduce((a, b) => a + b) /
        historicalSessions.length;

    final currentAvg = session.averageArrowScore;
    final currentConsistency = session.consistency;

    // Excellent performance criteria:
    // 1. Current avg > historical avg
    // 2. High consistency (>85%)
    if (currentAvg > historicalAvg && currentConsistency > 85.0) {
      final improvement = ((currentAvg - historicalAvg) / historicalAvg * 100);

      return SessionInsight(
        type: InsightType.excellence,
        title: '表现优异！',
        message: '本次训练超越历史平均${improvement.toStringAsFixed(1)}%，'
            '且稳定性达到${currentConsistency.toStringAsFixed(1)}%，继续保持！',
        icon: Icons.emoji_events,
        color: Colors.green,
        severity: InsightSeverity.positive,
      );
    }

    return null;
  }
}

/// Session insight model
class SessionInsight {
  final InsightType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final InsightSeverity severity;

  const SessionInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.severity,
  });

  /// Default insight for insufficient data
  factory SessionInsight.insufficient() {
    return const SessionInsight(
      type: InsightType.general,
      title: '数据不足',
      message: '继续射箭以获取更多分析建议（至少需要2组，每组3支箭）。',
      icon: Icons.info_outline,
      color: Colors.grey,
      severity: InsightSeverity.low,
    );
  }

  /// General positive feedback
  factory SessionInsight.general() {
    return const SessionInsight(
      type: InsightType.general,
      title: '训练完成',
      message: '保持专注，持续训练才能稳步提升。',
      icon: Icons.check_circle_outline,
      color: Colors.blue,
      severity: InsightSeverity.low,
    );
  }
}

/// Insight type enum
enum InsightType {
  equipment,   // Equipment/sight adjustment
  endurance,   // Endurance/fatigue issue
  warmUp,      // Slow start/warm-up
  stability,   // Stability/consistency
  excellence,  // Excellent performance
  general,     // General feedback
}

/// Insight severity level
enum InsightSeverity {
  high,      // Requires immediate attention
  medium,    // Should be addressed
  low,       // Informational
  positive,  // Positive feedback
}
