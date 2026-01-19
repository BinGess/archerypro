// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'ai_insight.dart';

AIInsight _$AIInsightFromJson(Map<String, dynamic> json) => AIInsight(
      id: json['id'] as String,
      type: InsightType.values[json['type'] as int],
      title: json['title'] as String,
      description: json['description'] as String,
      icon: AIInsight._iconFromJson(json['icon'] as int),
      color: AIInsight._colorFromJson(json['color'] as int),
      hasAction: json['hasAction'] as bool? ?? false,
      actionLabel: json['actionLabel'] as String?,
      priority: json['priority'] as int? ?? 3,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AIInsightToJson(AIInsight instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type.index,
      'title': instance.title,
      'description': instance.description,
      'icon': AIInsight._iconToJson(instance.icon),
      'color': AIInsight._colorToJson(instance.color),
      'hasAction': instance.hasAction,
      'actionLabel': instance.actionLabel,
      'priority': instance.priority,
      'createdAt': instance.createdAt.toIso8601String(),
    };
