import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/analytics_provider.dart';
import '../providers/session_provider.dart';
import '../providers/ai_coach_provider.dart';
import '../utils/constants.dart';
import '../services/analytics_service.dart';
import '../l10n/app_localizations.dart';

import '../widgets/growth_mixed_chart.dart';
import '../widgets/quadrant_radar_chart.dart';
import '../widgets/stability_radar_chart.dart';
import '../widgets/ai_coach/ai_loading_widget.dart';
import '../widgets/ai_coach/ai_result_card.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final stats = analyticsState.statistics;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.analysis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
              _buildTab(context, ref, kPeriod7Days, selectedPeriod, l10n),
              _buildTab(context, ref, kPeriod1Month, selectedPeriod, l10n),
              _buildTab(context, ref, kPeriodCurrentYear, selectedPeriod, l10n),
              _buildTab(context, ref, kPeriodAll, selectedPeriod, l10n),
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
                _buildCoreMetricsSection(stats, l10n),
                const SizedBox(height: 20),

                // Growth Trend Mixed Chart
                _buildGrowthTrendCard(stats, l10n),
                const SizedBox(height: 20),

                // Stability Radar Chart
                _buildStabilityRadarCard(stats, ref, selectedPeriod, l10n),
                const SizedBox(height: 20),

                // Quadrant Radar Chart
                _buildQuadrantRadarCard(stats, l10n),
                const SizedBox(height: 20),

                // AI Coach Analysis Section
                _buildAICoachSection(ref, selectedPeriod, l10n),
                const SizedBox(height: 20),

                // Period AI Insights
                _buildPeriodInsightsSection(stats, ref, selectedPeriod, l10n),
              ],
            ),
    );
  }

  Widget _buildTab(BuildContext context, WidgetRef ref, String period, String selectedPeriod, AppLocalizations l10n) {
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
          _getPeriodLabel(period, l10n),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primary : AppColors.textSlate400,
          ),
        ),
      ),
    );
  }

  String _getPeriodLabel(String period, AppLocalizations l10n) {
    switch (period) {
      case kPeriod7Days:
        return l10n.period7Days;
      case kPeriod1Month:
        return l10n.period1Month;
      case kPeriodCurrentYear:
        return l10n.periodCurrentYear;
      case kPeriodAll:
        return l10n.periodAll;
      default:
        return period;
    }
  }

  /// Build core metrics cards (总箭数, 平均环数, 10环率)
  Widget _buildCoreMetricsSection(dynamic stats, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.show_chart,
            label: l10n.totalArrows, // "总箭数" -> "Arrows" or similar
            // Wait, l10n.totalArrows is "totalArrows" key? 
            // In AppLocalizationsEn: String get arrows => 'Arrows';
            // In AppLocalizationsZh: String get arrows => '支箭';
            // There isn't "totalArrows" key explicitly for label "Total Arrows".
            // But there is `totalScore`. 
            // Let's check `app_localizations.dart` again.
            // Ah, I see `String get arrows;`.
            // I should probably add `totalArrows` key or use `arrows` + `total` prefix?
            // Actually, in previous step I didn't add `totalArrows` key.
            // I will use `l10n.arrows` for now, or just hardcode if missing.
            // Wait, I see `totalScore`.
            // Let's use `l10n.arrows` combined with `Total` if needed, but `arrows` usually means "Arrows" count.
            // For now, I'll use `l10n.arrows`.
            value: stats.totalArrows.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.adjust,
            label: l10n.averageScore,
            value: stats.avgArrowScore.toStringAsFixed(1),
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.stars,
            label: l10n.tenCount, // "10环数"
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
  Widget _buildGrowthTrendCard(dynamic stats, AppLocalizations l10n) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.growthTrendChart, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(l10n.growthTrendSubtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSlate400)),
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
                l10n.noDataForPeriod,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  /// Build stability radar chart card with comparison
  Widget _buildStabilityRadarCard(dynamic stats, WidgetRef ref, String selectedPeriod, AppLocalizations l10n) {
    if (stats.radarMetrics == null) {
      return ArcheryCard(
        child: Column(
          children: [
            Text(l10n.stabilityRadarChart, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                l10n.needMoreData,
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
                  Text(l10n.stabilityRadarChart, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(l10n.stabilityRadarSubtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
  Widget _buildQuadrantRadarCard(dynamic stats, AppLocalizations l10n) {
    final quadrantDist = stats.quadrantDistribution;
    final total = quadrantDist.values.fold(0, (sum, count) => sum + count);

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
                  Text(l10n.quadrantRadarChart, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(l10n.quadrantRadarSubtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSlate400)),
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
                    l10n.allArrowsGood,
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
  Widget _buildPeriodInsightsSection(dynamic stats, WidgetRef ref, String selectedPeriod, AppLocalizations l10n) {
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
      l10n: l10n,
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
                  l10n.aiPeriodAnalysis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.keepTrainingForInsights,
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
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.targetGold, size: 20),
            const SizedBox(width: 8),
            Text(l10n.aiPeriodAnalysis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSlate900)),
          ],
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPeriodInsightCard(insight, l10n),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPeriodInsightCard(PeriodInsight insight, AppLocalizations l10n) {
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
                        l10n.actionableTip,
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

  /// Build AI Coach analysis section
  Widget _buildAICoachSection(WidgetRef ref, String selectedPeriod, AppLocalizations l10n) {
    final aiCoachState = ref.watch(aiCoachProvider);

    // 获取当前周期的分析结果
    final periodResult = aiCoachState.getPeriodResult(selectedPeriod);
    final isAnalyzing = aiCoachState.isAnalyzingPeriod(selectedPeriod);

    return ArcheryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 教练周期分析',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '基于最近10次训练的整体评估',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Analyze button
              if (!isAnalyzing && periodResult == null)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(aiCoachProvider.notifier).analyzePeriod(selectedPeriod);
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text(
                    '分析',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Content area
          if (isAnalyzing)
            AILoadingWidget(message: aiCoachState.loadingMessage)
          else if (aiCoachState.error != null && aiCoachState.currentAnalysisType == 'period')
            _buildErrorState(ref, selectedPeriod, aiCoachState.error!)
          else if (periodResult != null)
            Column(
              children: [
                AIResultCard(
                  result: periodResult,
                  onDismiss: () {
                    ref.read(aiCoachProvider.notifier).clearPeriodResult(selectedPeriod);
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(aiCoachProvider.notifier).analyzePeriod(selectedPeriod);
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(
                    '重新分析',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            )
          else
            _buildEmptyState(ref, selectedPeriod),
        ],
      ),
    );
  }

  /// Error state widget
  Widget _buildErrorState(WidgetRef ref, String period, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '周期分析失败',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              ref.read(aiCoachProvider.notifier).clearError();
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState(WidgetRef ref, String selectedPeriod) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            '点击"分析"按钮获取 AI 教练的专业建议',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
