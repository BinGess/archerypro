import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/radar_metrics.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final labels = _localizedMetricLabels(l10n);
    final dataSets = <RadarDataSet>[];

    // Current period data (primary)
    dataSets.add(
      RadarDataSet(
        fillColor: AppColors.primary.withValues(alpha: 0.2),
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
          fillColor: AppColors.textSlate400.withValues(alpha: 0.12),
          borderColor: AppColors.textSlate400,
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
                color: AppColors.textSlate500,
                fontSize: 11,
              ),
              tickBorderData: BorderSide(
                color: AppColors.borderLight.withValues(alpha: 0.7),
                width: 1,
              ),
              gridBorderData: BorderSide(
                color: AppColors.borderLight.withValues(alpha: 0.9),
                width: 1.5,
              ),
              radarBorderData: BorderSide(
                color: AppColors.textSlate400.withValues(alpha: 0.6),
                width: 2,
              ),
              titleTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSlate900,
              ),
              getTitle: (index, angle) {
                if (!showLabels) return const RadarChartTitle(text: '');
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
          _buildLegend(context, l10n),
        ],
        const SizedBox(height: 12),
        _buildScoreSummary(l10n, labels),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(l10n.currentPeriod, AppColors.primary),
        if (previousMetrics != null) ...[
          const SizedBox(width: 24),
          _buildLegendItem(l10n.previousPeriod, AppColors.textSlate500),
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
            color: AppColors.textSlate700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSummary(AppLocalizations l10n, List<String> labels) {
    final currentScore = currentMetrics.overallScore;
    final values = currentMetrics.toList();
    final maxIndex = values.indexOf(values.reduce((a, b) => a > b ? a : b));
    final minIndex = values.indexOf(values.reduce((a, b) => a < b ? a : b));
    final strongest = labels[maxIndex];
    final weakest = labels[minIndex];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.overallScore,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSlate700,
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
                  l10n.strengthLabel(strongest),
                  AppColors.successSubtle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDimensionTag(
                  l10n.weaknessLabel(weakest),
                  AppColors.warningSubtle,
                  AppColors.warning,
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

  List<String> _localizedMetricLabels(AppLocalizations l10n) {
    return [
      l10n.precision,
      l10n.consistency,
      l10n.tenRingRate,
      l10n.groupingDensity,
      l10n.endurance,
      l10n.centerPrecision,
    ];
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
