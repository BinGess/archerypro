import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// End-by-end trend chart showing average score per end
/// Used in training session details page to detect performance patterns
class EndTrendChart extends StatelessWidget {
  /// Average scores for each end
  final List<double> endAverageScores;

  /// Overall session average (displayed as dashed horizontal line)
  final double sessionAverage;

  /// Height of the chart
  final double height;

  /// Whether to show grid
  final bool showGrid;

  const EndTrendChart({
    super.key,
    required this.endAverageScores,
    required this.sessionAverage,
    this.height = 250.0,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    if (endAverageScores.isEmpty) {
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

    // Calculate Y-axis range
    final maxScore = endAverageScores.reduce((a, b) => a > b ? a : b);
    final minScore = endAverageScores.reduce((a, b) => a < b ? a : b);

    final maxY = (maxScore + 1.0).ceilToDouble(); // Add 1.0 padding
    final minY = (minScore - 1.0).floorToDouble().clamp(0.0, 10.0);

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: showGrid,
              drawVerticalLine: false,
              horizontalInterval: 1.0,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: 1.0,
                  getTitlesWidget: (value, meta) {
                    if (value == minY || value == maxY) {
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
                    '组别',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1.0,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < endAverageScores.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                bottom:
                    BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
            ),
            minX: 0,
            maxX: (endAverageScores.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              // Main trend line
              LineChartBarData(
                spots: endAverageScores
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                // Session average line (dashed)
                HorizontalLine(
                  y: sessionAverage,
                  color: AppColors.accent.withOpacity(0.6),
                  strokeWidth: 2,
                  dashArray: [8, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                    labelResolver: (line) =>
                        '平均 ${sessionAverage.toStringAsFixed(1)}',
                  ),
                ),
              ],
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.black87,
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final endNumber = spot.x.toInt() + 1;
                    return LineTooltipItem(
                      '第${endNumber}组\n${spot.y.toStringAsFixed(2)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact version for use in summary cards
class EndTrendChartCompact extends StatelessWidget {
  final List<double> endAverageScores;
  final double sessionAverage;

  const EndTrendChartCompact({
    super.key,
    required this.endAverageScores,
    required this.sessionAverage,
  });

  @override
  Widget build(BuildContext context) {
    if (endAverageScores.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (endAverageScores.length - 1).toDouble(),
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: endAverageScores
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }
}
