import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/analytics_provider.dart';
import '../providers/session_provider.dart';
import '../utils/constants.dart';
import '../services/analytics_service.dart';

import '../widgets/growth_mixed_chart.dart';
import '../widgets/quadrant_radar_chart.dart';
import '../widgets/stability_radar_chart.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final stats = analyticsState.statistics;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('综合分析', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            ref.read(analyticsProvider.notifier).refreshAnalytics();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTab(context, ref, kPeriod7Days, selectedPeriod),
              _buildTab(context, ref, kPeriod1Month, selectedPeriod),
              _buildTab(context, ref, kPeriodCurrentYear, selectedPeriod),
              _buildTab(context, ref, kPeriodAll, selectedPeriod),
            ],
          ),
        ),
      ),
      body: analyticsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Core Metrics Cards
                _buildCoreMetricsSection(stats),
                const SizedBox(height: 20),

                // Growth Trend Mixed Chart
                _buildGrowthTrendCard(stats),
                const SizedBox(height: 20),

                // Stability Radar Chart
                _buildStabilityRadarCard(stats, ref, selectedPeriod),
                const SizedBox(height: 20),

                // Quadrant Radar Chart
                _buildQuadrantRadarCard(stats),
                const SizedBox(height: 20),

                // Period AI Insights
                _buildPeriodInsightsSection(stats, ref, selectedPeriod),
              ],
            ),
    );
  }

  Widget _buildTab(BuildContext context, WidgetRef ref, String period, String selectedPeriod) {
    final isSelected = period == selectedPeriod;
    return GestureDetector(
      onTap: () async {
        await ref.read(analyticsProvider.notifier).changePeriod(period);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 2, color: isSelected ? AppColors.primary : Colors.transparent)),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primary : AppColors.textSlate400,
          ),
        ),
      ),
    );
  }

  /// Build core metrics cards (总箭数, 平均环数, 10环率)
  Widget _buildCoreMetricsSection(dynamic stats) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.show_chart,
            label: '总箭数',
            value: stats.totalArrows.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.adjust,
            label: '平均环数',
            value: stats.avgArrowScore.toStringAsFixed(1),
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.stars,
            label: '10环率',
            value: '${stats.tenRingRate.toStringAsFixed(1)}%',
            color: AppColors.targetGold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSlate400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build growth trend chart card
  Widget _buildGrowthTrendCard(dynamic stats) {
    // Prepare volume data from score trend data
    final volumeData = <DateTime, int>{};
    for (final date in stats.scoreTrendData.keys) {
      // This is a simplification - ideally we'd track actual arrow counts per day
      // For now, estimate based on sessions
      volumeData[date] = 30; // Placeholder
    }

    return ArcheryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('成长趋势图', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('分数走势 + 训练量', style: TextStyle(fontSize: 11, color: AppColors.textSlate400)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, color: AppColors.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats.scoreTrendData.isNotEmpty)
            GrowthMixedChart(
              scoreTrendData: stats.scoreTrendData,
              volumeData: volumeData,
              height: 280,
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                '所选时段暂无数据',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  /// Build stability radar chart card with comparison
  Widget _buildStabilityRadarCard(dynamic stats, WidgetRef ref, String selectedPeriod) {
    if (stats.radarMetrics == null) {
      return ArcheryCard(
        child: Column(
          children: [
            const Text('稳定性雷达图', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                '需要更多训练数据',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // Get previous period data for comparison
    // For now, we'll just show current period radar
    // A more sophisticated implementation would calculate previous period metrics

    return ArcheryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('稳定性雷达图', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('6维度能力评估', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          StabilityRadarChart(
            currentMetrics: stats.radarMetrics,
            previousMetrics: null, // TODO: Calculate previous period metrics
            size: 260,
          ),
        ],
      ),
    );
  }

  /// Build quadrant radar chart card
  Widget _buildQuadrantRadarCard(dynamic stats) {
    final quadrantDist = stats.quadrantDistribution;
    final total = quadrantDist.values.fold(0, (sum, count) => sum + count);

    return ArcheryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('顽固偏差诊断', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('9环以下箭支方向分布', style: TextStyle(fontSize: 11, color: AppColors.textSlate400)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gps_fixed, color: Colors.purple, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total > 0)
            QuadrantRadarChartDetailed(quadrantDistribution: quadrantDist)
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
                  const SizedBox(height: 8),
                  Text(
                    '太棒了！所有箭支都在9环及以上',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build period insights section using AnalyticsService
  Widget _buildPeriodInsightsSection(dynamic stats, WidgetRef ref, String selectedPeriod) {
    final analyticsService = AnalyticsService();
    final sessionState = ref.watch(sessionProvider);
    final allSessions = sessionState.sessions;

    // Filter sessions for current period
    final periodSessions = allSessions.where((session) {
      final now = DateTime.now();
      switch (selectedPeriod) {
        case kPeriod7Days:
          return session.date.isAfter(now.subtract(const Duration(days: 7)));
        case kPeriod1Month:
          return session.date.isAfter(now.subtract(const Duration(days: 30)));
        case kPeriodCurrentYear:
          final startOfYear = DateTime(now.year, 1, 1);
          return session.date.isAfter(startOfYear);
        default:
          return true;
      }
    }).toList();

    // Generate period insights
    final insights = analyticsService.generatePeriodInsights(
      currentStats: stats,
      previousStats: null, // TODO: Calculate previous period stats
      recentSessions: periodSessions,
    );

    if (insights.isEmpty) {
      return ArcheryCard(
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI 周期分析',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '继续训练以获取AI周期分析建议',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.targetGold, size: 20),
            SizedBox(width: 8),
            Text('AI 周期分析', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSlate900)),
          ],
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPeriodInsightCard(insight),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPeriodInsightCard(PeriodInsight insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            insight.color.withOpacity(0.1),
            insight.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight.color.withOpacity(0.3)),
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(insight.icon, color: insight.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: insight.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSlate700,
                  ),
                ),
                if (insight.actionable) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: insight.color),
                      const SizedBox(width: 4),
                      Text(
                        '可执行建议',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: insight.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
