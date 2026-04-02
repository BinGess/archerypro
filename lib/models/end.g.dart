// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'end.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EndAdapter extends TypeAdapter<End> {
  @override
  final int typeId = 1;

  @override
  End read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return End(
      id: fields[0] as String,
      endNumber: fields[1] as int,
      arrows: (fields[2] as List?)?.cast<Arrow>(),
      maxArrows: fields[3] as int,
      createdAt: fields[4] as DateTime?,
      completedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, End obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.endNumber)
      ..writeByte(2)
      ..write(obj.arrows)
      ..writeByte(3)
      ..write(obj.maxArrows)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

End _$EndFromJson(Map<String, dynamic> json) => End(
      id: json['id'] as String,
      endNumber: (json['endNumber'] as num).toInt(),
      arrows: (json['arrows'] as List<dynamic>?)
          ?.map((e) => Arrow.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxArrows: (json['maxArrows'] as num?)?.toInt() ?? 6,
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
      'arrows': instance.arrows,
      'maxArrows': instance.maxArrows,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };
