// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'arrow.dart';

Arrow _$ArrowFromJson(Map<String, dynamic> json) => Arrow(
      id: json['id'] as String,
      score: json['score'] as int,
      position: json['position'] == null
          ? null
          : Arrow._offsetFromJson(json['position'] as Map<String, dynamic>),
      isX: json['isX'] as bool? ?? false,
      isMiss: json['isMiss'] as bool? ?? false,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ArrowToJson(Arrow instance) => <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'position': Arrow._offsetToJson(instance.position),
      'isX': instance.isX,
      'isMiss': instance.isMiss,
      'timestamp': instance.timestamp.toIso8601String(),
    };
