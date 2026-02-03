import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/radar_metrics.dart';
import '../theme/app_colors.dart';

/// Stability radar chart showing 6-dimension performance metrics
/// Optionally compares current period with previous period
class StabilityRadarChart extends StatelessWidget {
  /// Current period radar metrics
  final RadarMetrics currentMetrics;

  /// Previous period radar metrics for comparison (optional)
  final RadarMetrics? previousMetrics;

  /// Size of the chart
  final double size;

  /// Whether to show labels
  final bool showLabels;

  /// Whether to show legend
  final bool showLegend;

  const StabilityRadarChart({
    super.key,
    required this.currentMetrics,
    this.previousMetrics,
    this.size = 280.0,
    this.showLabels = true,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final dataSets = <RadarDataSet>[];

    // Current period data (primary)
    dataSets.add(
      RadarDataSet(
        fillColor: AppColors.primary.withOpacity(0.2),
        borderColor: AppColors.primary,
        borderWidth: 2.5,
        entryRadius: 4,
        dataEntries: currentMetrics
            .toList()
            .map((value) => RadarEntry(value: value))
            .toList(),
      ),
    );

    // Previous period data (for comparison)
    if (previousMetrics != null) {
      dataSets.add(
        RadarDataSet(
          fillColor: Colors.grey.withOpacity(0.1),
          borderColor: Colors.grey,
          borderWidth: 2,
          entryRadius: 3,
          dataEntries: previousMetrics!
              .toList()
              .map((value) => RadarEntry(value: value))
              .toList(),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 5,
              ticksTextStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
              tickBorderData: BorderSide(
                color: Colors.grey.withOpacity(0.2),
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              getTitle: (index, angle) {
                if (!showLabels) return const RadarChartTitle(text: '');
                final labels = RadarMetrics.labels;
                if (index >= 0 && index < labels.length) {
                  return RadarChartTitle(
                    text: labels[index],
                    angle: 0, // Keep labels horizontal for readability
                  );
                }
                return const RadarChartTitle(text: '');
              },
              dataSets: dataSets,
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
        const SizedBox(height: 12),
        _buildScoreSummary(),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('当前周期', AppColors.primary),
        if (previousMetrics != null) ...[
          const SizedBox(width: 24),
          _buildLegendItem('上一周期', Colors.grey),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSummary() {
    final currentScore = currentMetrics.overallScore;
    final strongest = currentMetrics.strongestDimension;
    final weakest = currentMetrics.weakestDimension;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '综合得分',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                currentScore.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDimensionTag(
                  '优势: $strongest',
                  Colors.green.shade100,
                  Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDimensionTag(
                  '短板: $weakest',
                  Colors.orange.shade100,
                  Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Compact version for use in summary cards
class StabilityRadarChartCompact extends StatelessWidget {
  final RadarMetrics currentMetrics;
  final RadarMetrics? previousMetrics;

  const StabilityRadarChartCompact({
    super.key,
    required this.currentMetrics,
    this.previousMetrics,
  });

  @override
  Widget build(BuildContext context) {
    return StabilityRadarChart(
      currentMetrics: currentMetrics,
      previousMetrics: previousMetrics,
      size: 180,
      showLabels: false,
      showLegend: false,
    );
  }
}
