// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'end.dart';

End _$EndFromJson(Map<String, dynamic> json) => End(
      id: json['id'] as String,
      endNumber: json['endNumber'] as int,
      arrows: (json['arrows'] as List<dynamic>?)
          ?.map((e) => Arrow.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxArrows: json['maxArrows'] as int? ?? 6,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$EndToJson(End instance) => <String, dynamic>{
      'id': instance.id,
      'endNumber': instance.endNumber,
      'arrows': instance.arrows.map((e) => e.toJson()).toList(),
      'maxArrows': instance.maxArrows,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };
