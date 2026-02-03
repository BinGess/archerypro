import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Score distribution bar chart showing count of arrows per ring
/// Highlights 10-ring and X-ring with gold color
class ScoreDistributionChart extends StatelessWidget {
  /// Map of score -> count
  /// Example: {10: 5, 9: 8, 8: 12, ...}
  final Map<int, int> scoreDistribution;

  /// Count of X-ring hits (displayed separately from 10-ring)
  final int xRingCount;

  /// Height of the chart
  final double height;

  /// Whether to show X-ring as separate bar
  final bool showXRingSeparate;

  const ScoreDistributionChart({
    super.key,
    required this.scoreDistribution,
    this.xRingCount = 0,
    this.height = 250.0,
    this.showXRingSeparate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (scoreDistribution.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ),
      );
    }

    // Prepare bar data
    final barGroups = _prepareBarGroups();
    final maxY = _calculateMaxY();

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            maxY: maxY,
            minY: 0,
            groupsSpace: 12,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final label = _getBarLabel(group.x.toInt());
                  final count = rod.toY.toInt();
                  return BarTooltipItem(
                    '$label\n$count箭',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == maxY) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '环数',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _getBarLabel(value.toInt()),
                        style: TextStyle(
                          fontSize: 11,
                          color: _isGoldRing(value.toInt())
                              ? AppColors.targetGold
                              : Colors.grey,
                          fontWeight: _isGoldRing(value.toInt())
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                bottom:
                    BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
            ),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  /// Prepare bar chart groups from score distribution
  List<BarChartGroupData> _prepareBarGroups() {
    final groups = <BarChartGroupData>[];

    // Get all unique scores and sort descending (10, 9, 8, ...)
    final scores = scoreDistribution.keys.toList()..sort((a, b) => b.compareTo(a));

    // Add X-ring as separate bar if enabled
    if (showXRingSeparate && xRingCount > 0) {
      groups.add(
        BarChartGroupData(
          x: 11, // Use 11 as index for X-ring
          barRods: [
            BarChartRodData(
              toY: xRingCount.toDouble(),
              color: AppColors.targetGold,
              width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _calculateMaxY(),
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }

    // Add bars for each score
    for (final score in scores) {
      final count = scoreDistribution[score] ?? 0;
      if (count == 0) continue;

      groups.add(
        BarChartGroupData(
          x: score,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: _getBarColor(score),
              width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _calculateMaxY(),
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  /// Get bar color based on score (gold for 10-ring)
  Color _getBarColor(int score) {
    if (score == 10) {
      return AppColors.targetGold;
    } else if (score >= 9) {
      return AppColors.primary;
    } else if (score >= 7) {
      return AppColors.accent;
    } else {
      return Colors.grey;
    }
  }

  /// Check if score is gold ring (10 or X)
  bool _isGoldRing(int index) {
    return index == 10 || index == 11; // 11 is X-ring
  }

  /// Get label for bar
  String _getBarLabel(int index) {
    if (index == 11) return 'X';
    return index.toString();
  }

  /// Calculate max Y value for chart
  double _calculateMaxY() {
    final maxCount = scoreDistribution.values.isEmpty
        ? 10
        : scoreDistribution.values.reduce((a, b) => a > b ? a : b);
    final maxWithX = showXRingSeparate && xRingCount > maxCount ? xRingCount : maxCount;

    // Round up to nearest 5
    return ((maxWithX / 5).ceil() * 5).toDouble();
  }
}

/// Compact version for use in summary cards
class ScoreDistributionChartCompact extends StatelessWidget {
  final Map<int, int> scoreDistribution;
  final int xRingCount;

  const ScoreDistributionChartCompact({
    super.key,
    required this.scoreDistribution,
    this.xRingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ScoreDistributionChart(
      scoreDistribution: scoreDistribution,
      xRingCount: xRingCount,
      height: 120,
      showXRingSeparate: false,
    );
  }
}
