// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'equipment.dart';

Equipment _$EquipmentFromJson(Map<String, dynamic> json) => Equipment(
      bowType: BowType.values[json['bowType'] as int],
      bowName: json['bowName'] as String?,
      arrowType: json['arrowType'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EquipmentToJson(Equipment instance) => <String, dynamic>{
      'bowType': instance.bowType.index,
      'bowName': instance.bowName,
      'arrowType': instance.arrowType,
      'notes': instance.notes,
    };
