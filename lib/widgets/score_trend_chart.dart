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
    // Filter valid scores
    final validScores = scores.where((s) => s.isFinite).toList();

    if (validScores.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
        ),
      );
    }

    final lineColor = color ?? AppColors.primary;

    // Calculate dynamic Y-axis range
    double maxScore = validScores.reduce((curr, next) => curr > next ? curr : next);
    double minScore = validScores.reduce((curr, next) => curr < next ? curr : next);
    
    // Handle edge case where max == min (single point or flat line)
    if (maxScore == minScore) {
      if (maxScore > 0) {
        maxScore *= 1.1;
        minScore *= 0.9;
      } else {
        maxScore = 10;
        minScore = 0;
      }
    }

    // Add padding to range
    double maxY = maxScore > 10 ? maxScore * 1.1 : 10.5; // If total score, add 10% padding. If average (<=10), use 10.5
    double minY = minScore > 10 ? minScore * 0.9 : 0; // If total score, sub 10% padding. If average, use 0
    
    // Ensure range is valid
    if (maxY <= minY) {
      maxY = minY + 1;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: !isCompact,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !isCompact,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == minY || value == maxY) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !isCompact,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < validScores.length) {
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
        maxX: (validScores.length > 1 ? validScores.length - 1 : 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: validScores.asMap().entries.map((e) {
               // If only one point, center it or put at 0. 
               // With maxX=1, putting it at 0 is fine.
               return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: validScores.length > 2, // Only curve if enough points
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: !isCompact || validScores.length == 1), // Show dot if single point
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
