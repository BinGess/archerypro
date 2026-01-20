import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Growth trend mixed chart showing score trend (line) and training volume (bar)
/// Used in comprehensive analysis page for long-term performance tracking
class GrowthMixedChart extends StatelessWidget {
  /// Map of date to average score
  final Map<DateTime, double> scoreTrendData;

  /// Map of date to arrow count
  final Map<DateTime, int> volumeData;

  /// Height of the chart
  final double height;

  const GrowthMixedChart({
    super.key,
    required this.scoreTrendData,
    required this.volumeData,
    this.height = 300.0,
  });

  @override
  Widget build(BuildContext context) {
    if (scoreTrendData.isEmpty && volumeData.isEmpty) {
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

    // Merge and sort dates
    final allDates = <DateTime>{
      ...scoreTrendData.keys,
      ...volumeData.keys,
    }.toList()
      ..sort();

    if (allDates.isEmpty) {
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

    // Prepare data
    final barGroups = _prepareBarGroups(allDates);
    final lineSpots = _prepareLineSpots(allDates);
    final maxVolume = _calculateMaxVolume();

    // Define titles for LineChart (visible)
    final titlesData = FlTitlesData(
      leftTitles: AxisTitles(
        axisNameWidget: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '平均环数',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
        axisNameSize: 20,
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 2.0,
          getTitlesWidget: (value, meta) {
            if (value == 0 || value == 10) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      rightTitles: AxisTitles(
        axisNameWidget: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '箭数',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
        axisNameSize: 20,
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            if (value == 0 || value >= maxVolume) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        axisNameWidget: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            '日期',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
        axisNameSize: 20,
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1.0,
          reservedSize: 24,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < allDates.length) {
              // Show every Nth date based on data density
              final showInterval = allDates.length > 10 ? 3 : 1;
              if (index % showInterval == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Transform.rotate(
                    angle: 0,
                    child: Text(
                      DateFormat('MM/dd').format(allDates[index]),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Define titles for BarChart (invisible but occupying space)
    final hiddenTitlesData = FlTitlesData(
      leftTitles: AxisTitles(
        axisNameWidget: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(' ', style: TextStyle(fontSize: 10)),
        ),
        axisNameSize: 20,
        sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => const SizedBox.shrink()),
      ),
      rightTitles: AxisTitles(
        axisNameWidget: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(' ', style: TextStyle(fontSize: 10)),
        ),
        axisNameSize: 20,
        sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => const SizedBox.shrink()),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        axisNameWidget: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(' ', style: TextStyle(fontSize: 10)),
        ),
        axisNameSize: 20,
        sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1.0, getTitlesWidget: (v, m) => const SizedBox.shrink()),
      ),
    );

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, left: 16, top: 24, bottom: 8),
        child: Stack(
          children: [
            // Background Bar Chart (Volume)
            BarChart(
              BarChartData(
                maxY: 10,
                minY: 0,
                barGroups: barGroups,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: hiddenTitlesData,
                barTouchData: BarTouchData(enabled: false),
              ),
            ),
            // Foreground Line Chart (Score)
            LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2.0,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: titlesData,
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                    bottom:
                        BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                    right: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                ),
                minX: 0,
                maxX: (allDates.length - 1).toDouble(),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  // Score trend line
                  LineChartBarData(
                    spots: lineSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
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
                      show: false,
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(10),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < allDates.length) {
                          final date = allDates[index];
                          final score = scoreTrendData[date] ?? 0;
                          final volume = volumeData[date] ?? 0;
                          return LineTooltipItem(
                            '${DateFormat('yyyy/MM/dd').format(date)}\n'
                            '平均: ${score.toStringAsFixed(1)}\n'
                            '箭数: $volume',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    // Reference line at score 8.0
                    HorizontalLine(
                      y: 8.0,
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Prepare bar groups for volume data (background bars)
  List<BarChartGroupData> _prepareBarGroups(List<DateTime> allDates) {
    final maxVolume = _calculateMaxVolume();
    final groups = <BarChartGroupData>[];

    for (int i = 0; i < allDates.length; i++) {
      final date = allDates[i];
      final volume = volumeData[date] ?? 0;

      // Normalize volume to 0-10 scale (same as score Y-axis)
      final normalizedVolume = maxVolume > 0 ? (volume / maxVolume) * 10 : 0.0;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: normalizedVolume,
              color: AppColors.accent.withOpacity(0.2),
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  /// Prepare line spots for score trend
  List<FlSpot> _prepareLineSpots(List<DateTime> allDates) {
    final spots = <FlSpot>[];

    for (int i = 0; i < allDates.length; i++) {
      final date = allDates[i];
      final score = scoreTrendData[date];
      if (score != null) {
        spots.add(FlSpot(i.toDouble(), score));
      }
    }

    return spots;
  }

  /// Calculate max volume for normalization
  double _calculateMaxVolume() {
    if (volumeData.isEmpty) return 100.0;
    final maxVol = volumeData.values.reduce((a, b) => a > b ? a : b);
    return (maxVol * 1.2).ceilToDouble(); // Add 20% padding
  }
}

/// Compact version for summary cards
class GrowthMixedChartCompact extends StatelessWidget {
  final Map<DateTime, double> scoreTrendData;
  final Map<DateTime, int> volumeData;

  const GrowthMixedChartCompact({
    super.key,
    required this.scoreTrendData,
    required this.volumeData,
  });

  @override
  Widget build(BuildContext context) {
    return GrowthMixedChart(
      scoreTrendData: scoreTrendData,
      volumeData: volumeData,
      height: 150,
    );
  }
}
