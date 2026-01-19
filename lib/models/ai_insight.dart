import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ai_insight.g.dart';

/// Type of AI insight
enum InsightType {
  stability,      // Related to shooting stability
  technique,      // Technique improvement suggestions
  equipment,      // Equipment-related advice
  drill,          // Suggested practice drills
  achievement,    // Achievement recognition
  warning,        // Warning about declining performance
}

/// Represents an AI-generated coaching insight
@JsonSerializable()
class AIInsight {
  /// Unique identifier
  final String id;

  /// Type of insight
  final InsightType type;

  /// Title of the insight
  final String title;

  /// Detailed description
  final String description;

  /// Icon name (as string for serialization)
  @JsonKey(fromJson: _iconFromJson, toJson: _iconToJson)
  final IconData icon;

  /// Color (as int for serialization)
  @JsonKey(fromJson: _colorFromJson, toJson: _colorToJson)
  final Color color;

  /// Whether this insight has an actionable drill
  final bool hasAction;

  /// Action button label (if hasAction is true)
  final String? actionLabel;

  /// Priority level (1-5, where 5 is highest)
  final int priority;

  /// Creation timestamp
  final DateTime createdAt;

  const AIInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.hasAction = false,
    this.actionLabel,
    this.priority = 3,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const Duration();

  /// Create a stability-focused insight
  factory AIInsight.stability({
    required String id,
    required String title,
    required String description,
    int priority = 3,
  }) {
    return AIInsight(
      id: id,
      type: InsightType.stability,
      title: title,
      description: description,
      icon: Icons.track_changes,
      color: const Color(0xFF2E7A7F), // AppColors.primary
      priority: priority,
    );
  }

  /// Create a drill suggestion insight
  factory AIInsight.drill({
    required String id,
    required String title,
    required String description,
    String actionLabel = 'START DRILL',
    int priority = 4,
  }) {
    return AIInsight(
      id: id,
      type: InsightType.drill,
      title: title,
      description: description,
      icon: Icons.fitness_center,
      color: const Color(0xFFB26A4D), // AppColors.accentRust
      hasAction: true,
      actionLabel: actionLabel,
      priority: priority,
    );
  }

  /// Create a technique improvement insight
  factory AIInsight.technique({
    required String id,
    required String title,
    required String description,
    int priority = 3,
  }) {
    return AIInsight(
      id: id,
      type: InsightType.technique,
      title: title,
      description: description,
      icon: Icons.psychology,
      color: const Color(0xFF2E7A7F),
      priority: priority,
    );
  }

  /// Create an achievement insight
  factory AIInsight.achievement({
    required String id,
    required String title,
    required String description,
    int priority = 2,
  }) {
    return AIInsight(
      id: id,
      type: InsightType.achievement,
      title: title,
      description: description,
      icon: Icons.emoji_events,
      color: const Color(0xFFD4AF37), // AppColors.accentGold
      priority: priority,
    );
  }

  /// Create a warning insight
  factory AIInsight.warning({
    required String id,
    required String title,
    required String description,
    int priority = 5,
  }) {
    return AIInsight(
      id: id,
      type: InsightType.warning,
      title: title,
      description: description,
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFB26A4D),
      priority: priority,
    );
  }

  /// Copy with method
  AIInsight copyWith({
    String? id,
    InsightType? type,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    bool? hasAction,
    String? actionLabel,
    int? priority,
    DateTime? createdAt,
  }) {
    return AIInsight(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      hasAction: hasAction ?? this.hasAction,
      actionLabel: actionLabel ?? this.actionLabel,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // JSON serialization helpers
  static IconData _iconFromJson(int codePoint) => IconData(codePoint, fontFamily: 'MaterialIcons');
  static int _iconToJson(IconData icon) => icon.codePoint;

  static Color _colorFromJson(int value) => Color(value);
  static int _colorToJson(Color color) => color.value;

  // JSON serialization
  factory AIInsight.fromJson(Map<String, dynamic> json) => _$AIInsightFromJson(json);
  Map<String, dynamic> toJson() => _$AIInsightToJson(this);

  @override
  String toString() => 'AIInsight($type: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIInsight &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
