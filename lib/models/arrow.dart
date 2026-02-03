import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'arrow.g.dart';

/// Represents a single arrow shot in archery
@HiveType(typeId: 0)
@JsonSerializable()
class Arrow {
  /// Unique identifier for this arrow
  @HiveField(0)
  final String id;

  /// Score value (1-10, or special values)
  /// 0 = Miss, 11 = X (inner 10)
  @HiveField(1)
  final int score;

  /// Position on target face (for heatmap visualization)
  /// Normalized coordinates: (0,0) = center, range: -1.0 to 1.0
  @HiveField(2)
  @JsonKey(fromJson: _offsetFromJson, toJson: _offsetToJson)
  final Offset? position;

  /// Whether this is an X ring hit (inner 10)
  @HiveField(3)
  final bool isX;

  /// Whether this is a miss (off target)
  @HiveField(4)
  final bool isMiss;

  /// Timestamp when the arrow was shot
  @HiveField(5)
  final DateTime timestamp;

  Arrow({
    required this.id,
    required this.score,
    this.position,
    this.isX = false,
    this.isMiss = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory constructor for creating an Arrow from score input
  factory Arrow.fromScore({
    required String id,
    required int score,
    Offset? position,
  }) {
    return Arrow(
      id: id,
      score: score,
      position: position,
      isX: score == 11, // X is represented as 11
      isMiss: score == 0,
    );
  }

  /// Get display score (X shows as 'X', 0 shows as 'M' for miss)
  String get displayScore {
    if (isMiss) return 'M';
    if (isX) return 'X';
    return score.toString();
  }

  /// Get the actual point value (X counts as 10 points)
  int get pointValue {
    // Treat 11 as 10 points (standard archery rule for X ring)
    if (score == 11 || isX) return 10;
    return score;
  }

  /// Copy with method for immutability
  Arrow copyWith({
    String? id,
    int? score,
    Offset? position,
    bool? isX,
    bool? isMiss,
    DateTime? timestamp,
  }) {
    return Arrow(
      id: id ?? this.id,
      score: score ?? this.score,
      position: position ?? this.position,
      isX: isX ?? this.isX,
      isMiss: isMiss ?? this.isMiss,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // JSON serialization
  factory Arrow.fromJson(Map<String, dynamic> json) => _$ArrowFromJson(json);
  Map<String, dynamic> toJson() => _$ArrowToJson(this);

  // Helper methods for Offset serialization
  static Offset? _offsetFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  static Map<String, dynamic>? _offsetToJson(Offset? offset) {
    if (offset == null) return null;
    return {
      'dx': offset.dx,
      'dy': offset.dy,
    };
  }

  @override
  String toString() => 'Arrow(id: $id, score: $displayScore, position: $position)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Arrow &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
