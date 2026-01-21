import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

/// Equipment type enum
@HiveType(typeId: 10)
enum BowType {
  @HiveField(0)
  compound,
  @HiveField(1)
  recurve,
  @HiveField(2)
  barebow,
  @HiveField(3)
  longbow,
}

/// Represents archery equipment used in a training session
@HiveType(typeId: 2)
@JsonSerializable()
class Equipment {
  /// Type of bow used
  @HiveField(0)
  final BowType bowType;

  /// Name/model of the bow (optional)
  @HiveField(1)
  final String? bowName;

  /// Type/brand of arrows used (optional)
  @HiveField(2)
  final String? arrowType;

  /// Additional equipment notes (optional)
  @HiveField(3)
  final String? notes;

  const Equipment({
    required this.bowType,
    this.bowName,
    this.arrowType,
    this.notes,
  });

  /// Get display name for bow type
  String get bowTypeDisplay {
    switch (bowType) {
      case BowType.compound:
        return '复合弓';
      case BowType.recurve:
        return '反曲弓';
      case BowType.barebow:
        return '光弓';
      case BowType.longbow:
        return '长弓';
    }
  }

  /// Get short description
  String get shortDescription {
    final parts = <String>[];
    parts.add(bowTypeDisplay);
    if (bowName != null && bowName!.isNotEmpty) {
      parts.add(bowName!);
    }
    return parts.join(' - ');
  }

  /// Get full description
  String get fullDescription {
    final parts = <String>[bowTypeDisplay];
    if (bowName != null && bowName!.isNotEmpty) {
      parts.add('($bowName)');
    }
    if (arrowType != null && arrowType!.isNotEmpty) {
      parts.add('| Arrows: $arrowType');
    }
    return parts.join(' ');
  }

  /// Copy with method for immutability
  Equipment copyWith({
    BowType? bowType,
    String? bowName,
    String? arrowType,
    String? notes,
  }) {
    return Equipment(
      bowType: bowType ?? this.bowType,
      bowName: bowName ?? this.bowName,
      arrowType: arrowType ?? this.arrowType,
      notes: notes ?? this.notes,
    );
  }

  // JSON serialization
  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentToJson(this);

  @override
  String toString() => shortDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Equipment &&
          runtimeType == other.runtimeType &&
          bowType == other.bowType &&
          bowName == other.bowName &&
          arrowType == other.arrowType;

  @override
  int get hashCode => Object.hash(bowType, bowName, arrowType);
}
