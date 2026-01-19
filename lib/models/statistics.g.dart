// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'statistics.dart';

Statistics _$StatisticsFromJson(Map<String, dynamic> json) => Statistics(
      period: json['period'] as String,
      totalSessions: json['totalSessions'] as int,
      totalArrows: json['totalArrows'] as int,
      totalScore: json['totalScore'] as int,
      maxPossibleScore: json['maxPossibleScore'] as int,
      avgArrowScore: (json['avgArrowScore'] as num).toDouble(),
      avgEndScore: (json['avgEndScore'] as num).toDouble(),
      bestScore: json['bestScore'] as int,
      bestMaxScore: json['bestMaxScore'] as int,
      trend: (json['trend'] as num).toDouble(),
      avgConsistency: (json['avgConsistency'] as num).toDouble(),
      heatmapData: const [],
      scoreTrendData: const {},
      monthlyGoal: json['monthlyGoal'] as int?,
      currentMonthArrows: json['currentMonthArrows'] as int,
    );

Map<String, dynamic> _$StatisticsToJson(Statistics instance) => <String, dynamic>{
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
