import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'radar_metrics.g.dart';

/// Six-dimensional radar metrics for comprehensive performance analysis
/// All values are normalized to 0-100 scale for radar chart visualization
@HiveType(typeId: 20)
@JsonSerializable()
class RadarMetrics {
  /// Accuracy - Average score normalized to percentage
  /// 100% = perfect 10-ring average
  @HiveField(0)
  final double accuracy;

  /// Consistency - Performance stability (from standard deviation)
  /// Higher = more consistent performance
  @HiveField(1)
  final double consistency;

  /// 10-ring rate - Percentage of arrows in gold zone (10 + X)
  @HiveField(2)
  final double tenRingRate;

  /// Grouping - How tight the arrow cluster is
  /// 100% = perfect grouping (zero scatter)
  @HiveField(3)
  final double grouping;

  /// Endurance - Ability to maintain performance throughout session
  /// 100% = no performance drop in later ends
  @HiveField(4)
  final double endurance;

  /// Center precision - How close the geometric center is to bullseye
  /// 100% = perfect center alignment
  @HiveField(5)
  final double centerPrecision;

  RadarMetrics({
    required this.accuracy,
    required this.consistency,
    required this.tenRingRate,
    required this.grouping,
    required this.endurance,
    required this.centerPrecision,
  });

  /// Convert to list for radar chart rendering
  /// Order: [accuracy, consistency, tenRingRate, grouping, endurance, centerPrecision]
  List<double> toList() => [
        accuracy,
        consistency,
        tenRingRate,
        grouping,
        endurance,
        centerPrecision,
      ];

  /// Get dimension labels for radar chart
  static List<String> get labels => [
        '精准度',
        '稳定性',
        '10环率',
        '分组密度',
        '耐力',
        '中心精度',
      ];

  /// Get dimension labels (English) for debugging
  static List<String> get labelsEn => [
        'Accuracy',
        'Consistency',
        '10-Ring',
        'Grouping',
        'Endurance',
        'Center',
      ];

  /// Overall performance score (average of all dimensions)
  double get overallScore {
    return (accuracy + consistency + tenRingRate + grouping + endurance + centerPrecision) / 6;
  }

  /// Identify the strongest dimension
  String get strongestDimension {
    final values = toList();
    final maxIndex = values.indexOf(values.reduce((a, b) => a > b ? a : b));
    return labels[maxIndex];
  }

  /// Identify the weakest dimension
  String get weakestDimension {
    final values = toList();
    final minIndex = values.indexOf(values.reduce((a, b) => a < b ? a : b));
    return labels[minIndex];
  }

  /// Check if performance is balanced (all dimensions within 20% range)
  bool get isBalanced {
    final values = toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    return (max - min) <= 20.0;
  }

  /// Factory constructor to create from training session data
  /// All calculations are done here to normalize metrics to 0-100 scale
  factory RadarMetrics.fromSessionData({
    required double avgArrowScore,
    required double consistency,
    required double tenRingRate,
    required double groupingRadius,
    required double firstThirdAvg,
    required double lastThirdAvg,
    required double centerDeviation,
  }) {
    // Accuracy: normalize average arrow score to percentage
    // 10 = 100%, 0 = 0%
    final accuracy = (avgArrowScore / 10.0 * 100).clamp(0.0, 100.0);

    // Consistency: already 0-100 from TrainingSession

    // 10-ring rate: already 0-100 percentage

    // Grouping: invert and normalize grouping radius
    // Radius ~0 = 100%, Radius ~0.5 (very scattered) = 0%
    final grouping = ((1 - (groupingRadius / 0.5)) * 100).clamp(0.0, 100.0);

    // Endurance: compare last third to first third
    // If lastThird >= firstThird, endurance = 100%
    // If lastThird = 0.8 * firstThird (20% drop), endurance = 80%
    double endurance;
    if (firstThirdAvg == 0) {
      endurance = 100.0;
    } else {
      endurance = ((lastThirdAvg / firstThirdAvg) * 100).clamp(0.0, 100.0);
    }

    // Center precision: invert center deviation
    // Deviation = 0 (perfect center) = 100%
    // Deviation = 0.3 (significantly off) = 0%
    final centerPrecision = ((1 - (centerDeviation / 0.3)) * 100).clamp(0.0, 100.0);

    return RadarMetrics(
      accuracy: accuracy,
      consistency: consistency,
      tenRingRate: tenRingRate,
      grouping: grouping,
      endurance: endurance,
      centerPrecision: centerPrecision,
    );
  }

  /// Create a zero/default metrics object
  factory RadarMetrics.zero() {
    return RadarMetrics(
      accuracy: 0,
      consistency: 0,
      tenRingRate: 0,
      grouping: 0,
      endurance: 0,
      centerPrecision: 0,
    );
  }

  // JSON serialization
  factory RadarMetrics.fromJson(Map<String, dynamic> json) => _$RadarMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$RadarMetricsToJson(this);

  @override
  String toString() =>
      'RadarMetrics(overall: ${overallScore.toStringAsFixed(1)}%, strongest: $strongestDimension)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarMetrics &&
          runtimeType == other.runtimeType &&
          accuracy == other.accuracy &&
          consistency == other.consistency &&
          tenRingRate == other.tenRingRate &&
          grouping == other.grouping &&
          endurance == other.endurance &&
          centerPrecision == other.centerPrecision;

  @override
  int get hashCode =>
      accuracy.hashCode ^
      consistency.hashCode ^
      tenRingRate.hashCode ^
      grouping.hashCode ^
      endurance.hashCode ^
      centerPrecision.hashCode;
}
