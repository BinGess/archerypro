import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Quadrant radar chart showing directional bias for arrows scoring below 9
/// Used for chronic bias diagnosis in comprehensive analysis
class QuadrantRadarChart extends StatelessWidget {
  /// Quadrant distribution map: {'top-left': count, 'top-right': count, ...}
  final Map<String, int> quadrantDistribution;

  /// Size of the chart
  final double size;

  /// Whether to show labels
  final bool showLabels;

  const QuadrantRadarChart({
    super.key,
    required this.quadrantDistribution,
    this.size = 250.0,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate total for percentage
    final total = quadrantDistribution.values.fold(0, (sum, count) => sum + count);

    if (total == 0) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            '无偏差数据',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ),
      );
    }

    // Normalize to 0-100 scale
    final normalizedData = _normalizeData(total);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle: const TextStyle(
                color: Colors.transparent,
                fontSize: 0,
              ),
              tickBorderData: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
              gridBorderData: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
              radarBorderData: BorderSide(
                color: Colors.grey.withOpacity(0.5),
                width: 2,
              ),
              titleTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              getTitle: (index, angle) {
                if (!showLabels) return const RadarChartTitle(text: '');
                return RadarChartTitle(
                  text: _getQuadrantLabel(index),
                  angle: 0, // Keep labels horizontal
                );
              },
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.primary.withOpacity(0.2),
                  borderColor: AppColors.primary,
                  borderWidth: 2.5,
                  entryRadius: 4,
                  dataEntries: normalizedData,
                ),
              ],
            ),
          ),
          if (showLabels)
            Positioned(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  '脱靶分布',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Normalize data to 0-100 scale
  List<RadarEntry> _normalizeData(int total) {
    // Order: top-left, top-right, bottom-right, bottom-left
    final topLeft = quadrantDistribution['top-left'] ?? 0;
    final topRight = quadrantDistribution['top-right'] ?? 0;
    final bottomLeft = quadrantDistribution['bottom-left'] ?? 0;
    final bottomRight = quadrantDistribution['bottom-right'] ?? 0;

    return [
      RadarEntry(value: (topLeft / total * 100)),
      RadarEntry(value: (topRight / total * 100)),
      RadarEntry(value: (bottomRight / total * 100)),
      RadarEntry(value: (bottomLeft / total * 100)),
    ];
  }

  /// Get label for quadrant
  String _getQuadrantLabel(int index) {
    switch (index) {
      case 0:
        return '左上';
      case 1:
        return '右上';
      case 2:
        return '右下';
      case 3:
        return '左下';
      default:
        return '';
    }
  }
}

/// Quadrant radar chart with detailed statistics
class QuadrantRadarChartDetailed extends StatelessWidget {
  final Map<String, int> quadrantDistribution;

  const QuadrantRadarChartDetailed({
    super.key,
    required this.quadrantDistribution,
  });

  @override
  Widget build(BuildContext context) {
    final total = quadrantDistribution.values.fold(0, (sum, count) => sum + count);

    return Column(
      children: [
        // Chart
        QuadrantRadarChart(
          quadrantDistribution: quadrantDistribution,
          size: 220,
        ),
        const SizedBox(height: 16),
        // Statistics
        if (total > 0) _buildStatistics(total),
      ],
    );
  }

  Widget _buildStatistics(int total) {
    // Find dominant quadrant
    final entries = quadrantDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dominant = entries.first;
    final dominancePercentage = (dominant.value / total * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_getQuadrantNameChinese(dominant.key)} 偏差占 $dominancePercentage%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getQuadrantNameChinese(String key) {
    switch (key) {
      case 'top-left':
        return '左上';
      case 'top-right':
        return '右上';
      case 'bottom-left':
        return '左下';
      case 'bottom-right':
        return '右下';
      default:
        return key;
    }
  }
}
