import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScoreTrendChart extends StatelessWidget {
  final List<double> scores;
  final bool isCompact;
  final Color? color;

  const ScoreTrendChart({
    super.key,
    required this.scores,
    this.isCompact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
        ),
      );
    }

    final lineColor = color ?? AppColors.primary;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: !isCompact,
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !isCompact,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < scores.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      (value.toInt() + 1).toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (scores.length - 1).toDouble(),
        minY: 0,
        maxY: 10.5, // slightly above 10 for padding
        lineBarsData: [
          LineChartBarData(
            spots: scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.2),
                  lineColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: !isCompact,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
