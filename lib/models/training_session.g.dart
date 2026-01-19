// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'training_session.dart';

TrainingSession _$TrainingSessionFromJson(Map<String, dynamic> json) => TrainingSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      sessionType: SessionType.values[json['sessionType'] as int? ?? 0],
      equipment: Equipment.fromJson(json['equipment'] as Map<String, dynamic>),
      distance: (json['distance'] as num).toDouble(),
      targetFaceSize: json['targetFaceSize'] as int,
      environment: EnvironmentType.values[json['environment'] as int? ?? 0],
      ends: (json['ends'] as List<dynamic>?)
          ?.map((e) => End.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$TrainingSessionToJson(TrainingSession instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'sessionType': instance.sessionType.index,
      'equipment': instance.equipment.toJson(),
      'distance': instance.distance,
      'targetFaceSize': instance.targetFaceSize,
      'environment': instance.environment.index,
      'ends': instance.ends.map((e) => e.toJson()).toList(),
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'notes': instance.notes,
    };
