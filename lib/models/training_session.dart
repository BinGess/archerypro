import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:math' as math;

import 'end.dart';
import 'equipment.dart';
import 'arrow.dart';

part 'training_session.g.dart';

/// Session type enum
@HiveType(typeId: 11)
enum SessionType {
  @HiveField(0)
  training,
  @HiveField(1)
  competition,
  @HiveField(2)
  practice,
}

/// Environment type enum
@HiveType(typeId: 12)
enum EnvironmentType {
  @HiveField(0)
  indoor,
  @HiveField(1)
  outdoor,
}

/// Represents a complete archery training session
@HiveType(typeId: 3)
@JsonSerializable()
class TrainingSession {
  /// Unique identifier
  @HiveField(0)
  final String id;

  /// Session date
  @HiveField(1)
  final DateTime date;

  /// Session type
  @HiveField(2)
  final SessionType sessionType;

  /// Equipment used
  @HiveField(3)
  final Equipment equipment;

  /// Shooting distance in meters
  @HiveField(4)
  final double distance;

  /// Target face size in centimeters
  @HiveField(5)
  final int targetFaceSize;

  /// Environment (indoor/outdoor)
  @HiveField(6)
  final EnvironmentType environment;

  /// List of ends in this session
  @HiveField(7)
  final List<End> ends;

  /// Session start time
  @HiveField(8)
  final DateTime startTime;

  /// Session end time
  @HiveField(9)
  final DateTime? endTime;

  /// Notes about the session
  @HiveField(10)
  final String? notes;

  TrainingSession({
    required this.id,
    required this.date,
    this.sessionType = SessionType.training,
    required this.equipment,
    required this.distance,
    required this.targetFaceSize,
    this.environment = EnvironmentType.indoor,
    List<End>? ends,
    DateTime? startTime,
    this.endTime,
    this.notes,
  })  : ends = ends ?? [],
        startTime = startTime ?? DateTime.now();

  /// Total score for the session
  int get totalScore {
    return ends.fold(0, (sum, end) => sum + end.totalScore);
  }

  /// Maximum possible score
  int get maxScore {
    return ends.fold(0, (sum, end) => sum + end.maxScore);
  }

  /// Total number of arrows shot
  int get arrowCount {
    return ends.fold(0, (sum, end) => sum + end.arrowCount);
  }

  /// Get all arrows from all ends
  List<Arrow> get allArrows {
    return ends.expand((end) => end.arrows).toList();
  }

  /// Average score per arrow
  double get averageArrowScore {
    if (arrowCount == 0) return 0.0;
    return totalScore / arrowCount;
  }

  /// Average score per end
  double get averageEndScore {
    if (ends.isEmpty) return 0.0;
    return ends.fold(0.0, (sum, end) => sum + end.averageScore) / ends.length;
  }

  /// Session duration
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Formatted duration string (e.g., "1:15h")
  String get durationDisplay {
    final dur = duration;
    if (dur == null) return 'In Progress';
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours}:${minutes.toString().padLeft(2, '0')}h';
  }

  /// Score percentage (e.g., 98.3%)
  double get scorePercentage {
    if (maxScore == 0) return 0.0;
    return (totalScore / maxScore) * 100;
  }

  /// Consistency metric (based on standard deviation)
  /// Returns a percentage where higher is more consistent
  double get consistency {
    if (arrowCount < 2) return 100.0;

    final scores = allArrows.map((a) => a.pointValue.toDouble()).toList();
    final mean = averageArrowScore;

    // Calculate standard deviation
    final variance = scores.fold(0.0, (sum, score) => sum + math.pow(score - mean, 2)) / scores.length;
    final stdDev = math.sqrt(variance);

    // Convert to percentage (lower std dev = higher consistency)
    // Max std dev for archery is ~3.16 (0-10 range)
    final maxStdDev = 3.16;
    final consistencyRaw = (1 - (stdDev / maxStdDev)) * 100;

    return consistencyRaw.clamp(0.0, 100.0);
  }

  /// Get session type display name
  String get sessionTypeDisplay {
    switch (sessionType) {
      case SessionType.training:
        return 'Regular Training';
      case SessionType.competition:
        return 'Competition';
      case SessionType.practice:
        return 'Practice';
    }
  }

  /// Get environment display name
  String get environmentDisplay {
    switch (environment) {
      case EnvironmentType.indoor:
        return 'Indoor';
      case EnvironmentType.outdoor:
        return 'Outdoor';
    }
  }

  /// Whether the session is complete
  bool get isComplete => endTime != null;

  /// Get formatted score (e.g., "590/600")
  String get scoreDisplay => '$totalScore/$maxScore';

  /// Get heatmap positions for all arrows
  List<Offset> get heatmapPositions {
    return allArrows
        .where((arrow) => arrow.position != null)
        .map((arrow) => arrow.position!)
        .toList();
  }

  // ==================== Advanced Analysis Properties ====================

  /// Geometric center point of all arrows (centroid)
  /// Returns null if no position data available
  Offset? get geometricCenter {
    final positions = heatmapPositions;
    if (positions.isEmpty) return null;

    final centerX = positions.fold(0.0, (sum, p) => sum + p.dx) / positions.length;
    final centerY = positions.fold(0.0, (sum, p) => sum + p.dy) / positions.length;
    return Offset(centerX, centerY);
  }

  /// Grouping radius (scatter radius) - standard deviation of distances from centroid
  /// Lower value = tighter grouping
  double get groupingRadius {
    final positions = heatmapPositions;
    if (positions.length < 2) return 0.0;

    final center = geometricCenter ?? const Offset(0, 0);

    // Calculate distances from center
    final distances = positions.map((p) =>
      math.sqrt(math.pow(p.dx - center.dx, 2) + math.pow(p.dy - center.dy, 2))
    ).toList();

    // Calculate standard deviation
    final mean = distances.reduce((a, b) => a + b) / distances.length;
    final variance = distances.fold(0.0, (sum, d) => sum + math.pow(d - mean, 2)) / distances.length;
    return math.sqrt(variance);
  }

  /// Score distribution map (score -> count)
  /// Example: {10: 5, 9: 8, 8: 12, ...}
  Map<int, int> get scoreDistribution {
    final distribution = <int, int>{};
    for (var arrow in allArrows) {
      final score = arrow.pointValue;
      distribution[score] = (distribution[score] ?? 0) + 1;
    }
    return distribution;
  }

  /// Count of 10-ring hits (excluding X)
  int get tenRingCount {
    return allArrows.where((a) => a.pointValue == 10 && !a.isX).length;
  }

  /// Count of X-ring hits (inner 10)
  int get xRingCount {
    return allArrows.where((a) => a.isX).length;
  }

  /// Total 10-ring + X-ring count
  int get goldRingCount {
    return tenRingCount + xRingCount;
  }

  /// 10-ring rate (percentage of arrows in 10-ring + X)
  double get tenRingRate {
    if (arrowCount == 0) return 0.0;
    return (goldRingCount / arrowCount) * 100;
  }

  /// List of average scores for each end
  /// Used for end-by-end trend analysis
  List<double> get endAverageScores {
    return ends.map((end) => end.averageScore).toList();
  }

  /// Average score of first 30% of ends
  /// Used for warm-up detection
  double get firstThirdAverage {
    if (ends.isEmpty) return 0.0;
    final count = math.max(1, (ends.length * 0.3).ceil());
    final firstEnds = ends.take(count);
    if (firstEnds.isEmpty) return 0.0;
    return firstEnds.fold(0.0, (sum, end) => sum + end.averageScore) / count;
  }

  /// Average score of last 30% of ends
  /// Used for endurance/fatigue detection
  double get lastThirdAverage {
    if (ends.isEmpty) return 0.0;
    final count = math.max(1, (ends.length * 0.3).ceil());
    final lastEnds = ends.skip(ends.length - count);
    if (lastEnds.isEmpty) return 0.0;
    return lastEnds.fold(0.0, (sum, end) => sum + end.averageScore) / count;
  }

  /// Quadrant distribution for arrows scoring below 9
  /// Used for bias detection (systematic errors)
  /// Returns map: {'top-left': count, 'top-right': count, 'bottom-left': count, 'bottom-right': count}
  Map<String, int> get quadrantDistribution {
    final quadrants = {
      'top-left': 0,
      'top-right': 0,
      'bottom-left': 0,
      'bottom-right': 0,
    };

    // Only analyze arrows scoring 8 or below (exclude 9, 10, X)
    for (var arrow in allArrows) {
      if (arrow.pointValue >= 9 || arrow.position == null) continue;

      final pos = arrow.position!;
      // Offset coordinates: dx=horizontal, dy=vertical
      // Negative dx = left, positive dx = right
      // Negative dy = top, positive dy = bottom
      if (pos.dx < 0 && pos.dy < 0) {
        quadrants['top-left'] = quadrants['top-left']! + 1;
      } else if (pos.dx >= 0 && pos.dy < 0) {
        quadrants['top-right'] = quadrants['top-right']! + 1;
      } else if (pos.dx < 0 && pos.dy >= 0) {
        quadrants['bottom-left'] = quadrants['bottom-left']! + 1;
      } else {
        quadrants['bottom-right'] = quadrants['bottom-right']! + 1;
      }
    }

    return quadrants;
  }

  /// Distance of geometric center from target center (normalized 0-1)
  /// Used for equipment/sight adjustment detection
  double get centerDeviation {
    final center = geometricCenter;
    if (center == null) return 0.0;
    return math.sqrt(center.dx * center.dx + center.dy * center.dy);
  }

  // ======================================================================

  /// Add an end to the session
  TrainingSession addEnd(End end) {
    return copyWith(ends: [...ends, end]);
  }

  /// Update an end in the session
  TrainingSession updateEnd(End updatedEnd) {
    final updatedEnds = ends.map((end) {
      return end.id == updatedEnd.id ? updatedEnd : end;
    }).toList();
    return copyWith(ends: updatedEnds);
  }

  /// Mark session as complete
  TrainingSession complete() {
    return copyWith(endTime: DateTime.now());
  }

  /// Copy with method
  TrainingSession copyWith({
    String? id,
    DateTime? date,
    SessionType? sessionType,
    Equipment? equipment,
    double? distance,
    int? targetFaceSize,
    EnvironmentType? environment,
    List<End>? ends,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      date: date ?? this.date,
      sessionType: sessionType ?? this.sessionType,
      equipment: equipment ?? this.equipment,
      distance: distance ?? this.distance,
      targetFaceSize: targetFaceSize ?? this.targetFaceSize,
      environment: environment ?? this.environment,
      ends: ends ?? this.ends,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
    );
  }

  // JSON serialization
  factory TrainingSession.fromJson(Map<String, dynamic> json) => _$TrainingSessionFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingSessionToJson(this);

  @override
  String toString() => 'TrainingSession($scoreDisplay, ${ends.length} ends, ${equipment.bowTypeDisplay})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
