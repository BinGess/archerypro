import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/analytics_provider.dart';
import '../utils/constants.dart';

import '../widgets/score_trend_chart.dart';
import '../widgets/target_face_painter.dart';

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
        title: const Text('表现分析', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            ref.read(analyticsProvider.notifier).refreshAnalytics();
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.share, size: 18, color: AppColors.primary),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTab(context, ref, kPeriod7Days, selectedPeriod),
              _buildTab(context, ref, kPeriod1Month, selectedPeriod),
              _buildTab(context, ref, kPeriod3Months, selectedPeriod),
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
                _buildScoreTrendCard(stats),
                const SizedBox(height: 20),
                _buildHeatmapCard(stats),
                const SizedBox(height: 20),
                _buildInsightSection(analyticsState.insights),
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

  Widget _buildScoreTrendCard(dynamic stats) {
    return ArcheryCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('平均组分', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(stats.avgEndScore.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(width: 8),
                      Text(
                        stats.trendDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: stats.trend >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                        ),
                      ),
                      Icon(
                        stats.trend >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: stats.trend >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.insights, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180, // Increased height for detail
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 8),
              child: ScoreTrendChart(
                scores: stats.scoreTrendData.values.toList(),
                isCompact: false,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (stats.totalSessions > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${stats.totalSessions} 次训练', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
                Text('${stats.totalArrows} 支箭', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
                Text('${stats.scorePercentage.toStringAsFixed(1)}% 平均', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
              ],
            )
          else
            const Text('所选时段暂无数据', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard(dynamic stats) {
    final hasData = stats.heatmapData.isNotEmpty;
    String tendency = 'CENTERED';

    if (hasData) {
      // Calculate center of mass for grouping tendency
      final centerX = stats.heatmapData.fold(0.0, (sum, p) => sum + p.dx) / stats.heatmapData.length;
      final centerY = stats.heatmapData.fold(0.0, (sum, p) => sum + p.dy) / stats.heatmapData.length;

      if (centerX < -0.15 && centerY < -0.15) {
        tendency = 'LOW LEFT';
      } else if (centerX > 0.15 && centerY < -0.15) {
        tendency = 'LOW RIGHT';
      } else if (centerY < -0.15) {
        tendency = 'LOW';
      } else if (centerY > 0.15) {
        tendency = 'HIGH';
      } else if (centerX < -0.15) {
        tendency = 'LEFT';
      } else if (centerX > 0.15) {
        tendency = 'RIGHT';
      }
    }

    return ArcheryCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('着靶精度', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              StatusBadge(
                text: 'TREND: $tendency',
                color: tendency == 'CENTERED' ? AppColors.primary : AppColors.accentRust,
                backgroundColor: tendency == 'CENTERED' ? AppColors.primary.withOpacity(0.1) : AppColors.accentRust.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Target Face
                CustomPaint(
                  size: const Size(240, 240),
                  painter: TargetFacePainter(targetFaceSize: 122),
                ),

                // Plot actual arrow positions if available
                if (hasData)
                  ...stats.heatmapData.take(50).map((position) {
                    // Normalize position to fit 240x240
                    // position.dx/dy are -1 to 1 (usually) relative to center
                    // We assume the stored heatmap data is normalized (-1 to 1)
                    // Radius = 120
                    const double radius = 120.0;
                    return Positioned(
                      left: 120.0 + position.dx * radius - 4,
                      top: 120.0 + position.dy * radius - 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.6),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 2)],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppColors.primary, 'GROUPING'),
              const SizedBox(width: 24),
              _buildLegend(AppColors.accentGold, 'BULLSEYE'),
            ],
          ),
          if (!hasData) ...[
            const SizedBox(height: 16),
            const Text('射更多箭以查看分组模式', style: TextStyle(fontSize: 11, color: AppColors.textSlate400)),
          ],
        ],
      ),
    );
  }

  // _buildRing helper is no longer needed but we can leave it or remove it. 
  // I will remove it to be clean. But I need to verify if it is used elsewhere.
  // It was only used in _buildHeatmapCard. So I can safely remove it.
  
  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
      ],
    );
  }

  Widget _buildInsightSection(List<dynamic> insights) {
    if (insights.isEmpty) {
      return ArcheryCard(
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 8),
                Text('AI 教练建议', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Complete more training sessions to receive personalized AI insights',
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
            Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 20),
            SizedBox(width: 8),
            Text('AI 教练建议', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSlate900)),
          ],
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInsightItem(
              icon: insight.icon,
              color: insight.color,
              title: insight.title,
              desc: insight.description,
              hasAction: insight.hasAction,
              actionLabel: insight.actionLabel,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    bool hasAction = false,
    String? actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAction ? Colors.white : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasAction ? AppColors.borderLight : color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSlate500)),
                if (hasAction && actionLabel != null) ...[
                  const SizedBox(height: 8),
                  Text('${actionLabel.toUpperCase()} →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
