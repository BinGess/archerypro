// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipmentAdapter extends TypeAdapter<Equipment> {
  @override
  final int typeId = 2;

  @override
  Equipment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Equipment(
      bowType: fields[0] as BowType,
      bowName: fields[1] as String?,
      arrowType: fields[2] as String?,
      notes: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Equipment obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.bowType)
      ..writeByte(1)
      ..write(obj.bowName)
      ..writeByte(2)
      ..write(obj.arrowType)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BowTypeAdapter extends TypeAdapter<BowType> {
  @override
  final int typeId = 10;

  @override
  BowType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BowType.compound;
      case 1:
        return BowType.recurve;
      case 2:
        return BowType.barebow;
      case 3:
        return BowType.longbow;
      default:
        return BowType.compound;
    }
  }

  @override
  void write(BinaryWriter writer, BowType obj) {
    switch (obj) {
      case BowType.compound:
        writer.writeByte(0);
        break;
      case BowType.recurve:
        writer.writeByte(1);
        break;
      case BowType.barebow:
        writer.writeByte(2);
        break;
      case BowType.longbow:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BowTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Equipment _$EquipmentFromJson(Map<String, dynamic> json) => Equipment(
      bowType: $enumDecode(_$BowTypeEnumMap, json['bowType']),
      bowName: json['bowName'] as String?,
      arrowType: json['arrowType'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EquipmentToJson(Equipment instance) => <String, dynamic>{
      'bowType': _$BowTypeEnumMap[instance.bowType]!,
      'bowName': instance.bowName,
      'arrowType': instance.arrowType,
      'notes': instance.notes,
    };

const _$BowTypeEnumMap = {
  BowType.compound: 'compound',
  BowType.recurve: 'recurve',
  BowType.barebow: 'barebow',
  BowType.longbow: 'longbow',
};
