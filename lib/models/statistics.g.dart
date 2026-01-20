// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Statistics _$StatisticsFromJson(Map<String, dynamic> json) => Statistics(
      period: json['period'] as String,
      totalSessions: (json['totalSessions'] as num).toInt(),
      totalArrows: (json['totalArrows'] as num).toInt(),
      totalScore: (json['totalScore'] as num).toInt(),
      maxPossibleScore: (json['maxPossibleScore'] as num).toInt(),
      avgArrowScore: (json['avgArrowScore'] as num).toDouble(),
      avgEndScore: (json['avgEndScore'] as num).toDouble(),
      bestScore: (json['bestScore'] as num).toInt(),
      bestMaxScore: (json['bestMaxScore'] as num).toInt(),
      trend: (json['trend'] as num).toDouble(),
      avgConsistency: (json['avgConsistency'] as num).toDouble(),
      monthlyGoal: (json['monthlyGoal'] as num?)?.toInt(),
      currentMonthArrows: (json['currentMonthArrows'] as num).toInt(),
    );

Map<String, dynamic> _$StatisticsToJson(Statistics instance) =>
    <String, dynamic>{
      'period': instance.period,
      'totalSessions': instance.totalSessions,
      'totalArrows': instance.totalArrows,
      'totalScore': instance.totalScore,
      'maxPossibleScore': instance.maxPossibleScore,
      'avgArrowScore': instance.avgArrowScore,
      'avgEndScore': instance.avgEndScore,
      'bestScore': instance.bestScore,
      'bestMaxScore': instance.bestMaxScore,
      'trend': instance.trend,
      'avgConsistency': instance.avgConsistency,
      'monthlyGoal': instance.monthlyGoal,
      'currentMonthArrows': instance.currentMonthArrows,
    };
