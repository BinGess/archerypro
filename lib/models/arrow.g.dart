// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arrow.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArrowAdapter extends TypeAdapter<Arrow> {
  @override
  final int typeId = 0;

  @override
  Arrow read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Arrow(
      id: fields[0] as String,
      score: fields[1] as int,
      position: fields[2] as Offset?,
      isX: fields[3] as bool,
      isMiss: fields[4] as bool,
      timestamp: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Arrow obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.isX)
      ..writeByte(4)
      ..write(obj.isMiss)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Arrow _$ArrowFromJson(Map<String, dynamic> json) => Arrow(
      id: json['id'] as String,
      score: (json['score'] as num).toInt(),
      position:
          Arrow._offsetFromJson(json['position'] as Map<String, dynamic>?),
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
