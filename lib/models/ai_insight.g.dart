// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_insight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIInsight _$AIInsightFromJson(Map<String, dynamic> json) => AIInsight(
      id: json['id'] as String,
      type: $enumDecode(_$InsightTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      icon: AIInsight._iconFromJson((json['icon'] as num).toInt()),
      color: AIInsight._colorFromJson((json['color'] as num).toInt()),
      hasAction: json['hasAction'] as bool? ?? false,
      actionLabel: json['actionLabel'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 3,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AIInsightToJson(AIInsight instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$InsightTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'icon': AIInsight._iconToJson(instance.icon),
      'color': AIInsight._colorToJson(instance.color),
      'hasAction': instance.hasAction,
      'actionLabel': instance.actionLabel,
      'priority': instance.priority,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$InsightTypeEnumMap = {
  InsightType.stability: 'stability',
  InsightType.technique: 'technique',
  InsightType.equipment: 'equipment',
  InsightType.drill: 'drill',
  InsightType.achievement: 'achievement',
  InsightType.warning: 'warning',
};
