import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'arrow.dart';

part 'end.g.dart';

/// Represents an "end" - a group of arrows shot together
/// Typically 3 or 6 arrows in competition
@HiveType(typeId: 1)
@JsonSerializable()
class End {
  /// Unique identifier for this end
  @HiveField(0)
  final String id;

  /// End number in the session (1, 2, 3, etc.)
  @HiveField(1)
  final int endNumber;

  /// List of arrows in this end
  @HiveField(2)
  final List<Arrow> arrows;

  /// Maximum number of arrows allowed in this end
  @HiveField(3)
  final int maxArrows;

  /// Timestamp when the end was created
  @HiveField(4)
  final DateTime createdAt;

  /// Timestamp when the end was completed
  @HiveField(5)
  final DateTime? completedAt;

  End({
    required this.id,
    required this.endNumber,
    List<Arrow>? arrows,
    this.maxArrows = 6,
    DateTime? createdAt,
    this.completedAt,
  })  : arrows = arrows ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Total score for this end
  int get totalScore {
    return arrows.fold(0, (sum, arrow) => sum + arrow.pointValue);
  }

  /// Maximum possible score for this end
  int get maxScore => maxArrows * 10;

  /// Whether this end is complete
  bool get isComplete => arrows.length >= maxArrows || completedAt != null;

  /// Whether this end can accept more arrows
  bool get canAddArrow => arrows.length < maxArrows && !isComplete;

  /// Number of arrows currently in this end
  int get arrowCount => arrows.length;

  /// Average score per arrow in this end
  double get averageScore {
    if (arrows.isEmpty) return 0.0;
    return totalScore / arrows.length;
  }

  /// Get arrow scores as a list of integers
  List<int> get scores => arrows.map((a) => a.score).toList();

  /// Get arrow scores as a formatted string (e.g., "10/9/10")
  String get scoresDisplay => arrows.map((a) => a.displayScore).join('/');

  /// Add an arrow to this end
  End addArrow(Arrow arrow) {
    if (!canAddArrow) {
      throw StateError('Cannot add more arrows to this end');
    }
    return copyWith(arrows: [...arrows, arrow]);
  }

  /// Remove the last arrow from this end
  End removeLastArrow() {
    if (arrows.isEmpty) {
      throw StateError('No arrows to remove');
    }
    return copyWith(arrows: arrows.sublist(0, arrows.length - 1));
  }

  /// Mark this end as complete
  End complete() {
    return copyWith(completedAt: DateTime.now());
  }

  /// Copy with method for immutability
  End copyWith({
    String? id,
    int? endNumber,
    List<Arrow>? arrows,
    int? maxArrows,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return End(
      id: id ?? this.id,
      endNumber: endNumber ?? this.endNumber,
      arrows: arrows ?? this.arrows,
      maxArrows: maxArrows ?? this.maxArrows,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // JSON serialization
  factory End.fromJson(Map<String, dynamic> json) => _$EndFromJson(json);
  Map<String, dynamic> toJson() => _$EndToJson(this);

  @override
  String toString() => 'End(#$endNumber, ${arrows.length}/$maxArrows arrows, score: $totalScore/$maxScore)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is End &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
