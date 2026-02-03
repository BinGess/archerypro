// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_metrics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RadarMetricsAdapter extends TypeAdapter<RadarMetrics> {
  @override
  final int typeId = 20;

  @override
  RadarMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RadarMetrics(
      accuracy: fields[0] as double,
      consistency: fields[1] as double,
      tenRingRate: fields[2] as double,
      grouping: fields[3] as double,
      endurance: fields[4] as double,
      centerPrecision: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, RadarMetrics obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.accuracy)
      ..writeByte(1)
      ..write(obj.consistency)
      ..writeByte(2)
      ..write(obj.tenRingRate)
      ..writeByte(3)
      ..write(obj.grouping)
      ..writeByte(4)
      ..write(obj.endurance)
      ..writeByte(5)
      ..write(obj.centerPrecision);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadarMetrics _$RadarMetricsFromJson(Map<String, dynamic> json) => RadarMetrics(
      accuracy: (json['accuracy'] as num).toDouble(),
      consistency: (json['consistency'] as num).toDouble(),
      tenRingRate: (json['tenRingRate'] as num).toDouble(),
      grouping: (json['grouping'] as num).toDouble(),
      endurance: (json['endurance'] as num).toDouble(),
      centerPrecision: (json['centerPrecision'] as num).toDouble(),
    );

Map<String, dynamic> _$RadarMetricsToJson(RadarMetrics instance) =>
    <String, dynamic>{
      'accuracy': instance.accuracy,
      'consistency': instance.consistency,
      'tenRingRate': instance.tenRingRate,
      'grouping': instance.grouping,
      'endurance': instance.endurance,
      'centerPrecision': instance.centerPrecision,
    };
