// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingSessionAdapter extends TypeAdapter<TrainingSession> {
  @override
  final int typeId = 3;

  @override
  TrainingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingSession(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      sessionType: fields[2] as SessionType,
      equipment: fields[3] as Equipment,
      distance: fields[4] as double,
      targetFaceSize: fields[5] as int,
      environment: fields[6] as EnvironmentType,
      ends: (fields[7] as List?)?.cast<End>(),
      startTime: fields[8] as DateTime?,
      endTime: fields[9] as DateTime?,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.sessionType)
      ..writeByte(3)
      ..write(obj.equipment)
      ..writeByte(4)
      ..write(obj.distance)
      ..writeByte(5)
      ..write(obj.targetFaceSize)
      ..writeByte(6)
      ..write(obj.environment)
      ..writeByte(7)
      ..write(obj.ends)
      ..writeByte(8)
      ..write(obj.startTime)
      ..writeByte(9)
      ..write(obj.endTime)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionTypeAdapter extends TypeAdapter<SessionType> {
  @override
  final int typeId = 11;

  @override
  SessionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionType.training;
      case 1:
        return SessionType.competition;
      case 2:
        return SessionType.practice;
      default:
        return SessionType.training;
    }
  }

  @override
  void write(BinaryWriter writer, SessionType obj) {
    switch (obj) {
      case SessionType.training:
        writer.writeByte(0);
        break;
      case SessionType.competition:
        writer.writeByte(1);
        break;
      case SessionType.practice:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EnvironmentTypeAdapter extends TypeAdapter<EnvironmentType> {
  @override
  final int typeId = 12;

  @override
  EnvironmentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EnvironmentType.indoor;
      case 1:
        return EnvironmentType.outdoor;
      default:
        return EnvironmentType.indoor;
    }
  }

  @override
  void write(BinaryWriter writer, EnvironmentType obj) {
    switch (obj) {
      case EnvironmentType.indoor:
        writer.writeByte(0);
        break;
      case EnvironmentType.outdoor:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingSession _$TrainingSessionFromJson(Map<String, dynamic> json) =>
    TrainingSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      sessionType:
          $enumDecodeNullable(_$SessionTypeEnumMap, json['sessionType']) ??
              SessionType.training,
      equipment: Equipment.fromJson(json['equipment'] as Map<String, dynamic>),
      distance: (json['distance'] as num).toDouble(),
      targetFaceSize: (json['targetFaceSize'] as num).toInt(),
      environment:
          $enumDecodeNullable(_$EnvironmentTypeEnumMap, json['environment']) ??
              EnvironmentType.indoor,
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

Map<String, dynamic> _$TrainingSessionToJson(TrainingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'sessionType': _$SessionTypeEnumMap[instance.sessionType]!,
      'equipment': instance.equipment,
      'distance': instance.distance,
      'targetFaceSize': instance.targetFaceSize,
      'environment': _$EnvironmentTypeEnumMap[instance.environment]!,
      'ends': instance.ends,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'notes': instance.notes,
    };

const _$SessionTypeEnumMap = {
  SessionType.training: 'training',
  SessionType.competition: 'competition',
  SessionType.practice: 'practice',
};

const _$EnvironmentTypeEnumMap = {
  EnvironmentType.indoor: 'indoor',
  EnvironmentType.outdoor: 'outdoor',
};
