import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/session_provider.dart';
import '../providers/analytics_provider.dart';
import 'details_screen.dart';

import '../widgets/score_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: sessionState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: AppColors.backgroundLight.withOpacity(0.95),
                    title: const Text(
                      'Training History',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSlate900),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.read(sessionProvider.notifier).refresh();
                          ref.read(analyticsProvider.notifier).refreshAnalytics();
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                      )
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSummaryCard(analyticsState.statistics),
                        const SizedBox(height: 24),

                        // Display sessions from provider
                        ...sessionState.recentSessions.map((session) {
                          final isHighRecord = session == sessionState.bestSession;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildHistoryItem(
                              context: context,
                              isHighRecord: isHighRecord,
                              date: _formatDate(session.date),
                              score: session.totalScore,
                              total: session.maxScore,
                              type: '${session.equipment.bowTypeDisplay} • ${session.distance.toInt()}m',
                              percentage: session.scorePercentage,
                              arrowCount: session.arrowCount,
                              onTap: () {
                                ref.read(selectedSessionProvider.notifier).state = session;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const DetailsScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: 32),
                        if (sessionState.sessions.isEmpty)
                          const Opacity(
                            opacity: 0.4,
                            child: Column(
                              children: [
                                Icon(Icons.history, size: 64, color: AppColors.textSlate500),
                                SizedBox(height: 16),
                                Text('暂无训练记录', style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 8),
                                Text('点击"添加"开始第一次训练', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          )
                        else
                          Opacity(
                            opacity: 0.4,
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle, size: 48, color: AppColors.textSlate500),
                                const SizedBox(height: 12),
                                Text('显示最近 ${sessionState.recentSessions.length} 次训练', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard(dynamic stats) {
    return ArcheryCard(
      padding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(100)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${stats.totalSessions}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                            const SizedBox(width: 4),
                            const Text('次训练', style: TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('本月已射 ${stats.currentMonthArrows} 支箭', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate500)),
                          ],
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(stats.avgArrowScore.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1, color: AppColors.primary)),
                            const SizedBox(width: 4),
                            const Text('平均', style: TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(
                              text: stats.trendDisplay,
                              color: stats.trend >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                              backgroundColor: stats.trend >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                            ),
                            const SizedBox(width: 4),
                            const Text('趋势', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate400)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: ScoreTrendChart(
                    scores: stats.scoreTrendData.values.toList(),
                    isCompact: true,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('月度目标：${stats.monthlyGoal ?? 3000} 支箭', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                    Text('${stats.monthlyGoalProgress.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (stats.monthlyGoalProgress / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required BuildContext context,
    required bool isHighRecord,
    required String date,
    required int score,
    required int total,
    required String type,
    required double percentage,
    required int arrowCount,
    required VoidCallback onTap,
  }) {
    // 处理日期显示，适应中文格式
    String monthPart = '';
    String dayPart = '';
    
    if (date.contains('月')) {
       final parts = date.split('月');
       if (parts.length >= 2) {
         monthPart = '${parts[0]}月';
         dayPart = parts[1];
       } else {
         monthPart = date;
       }
    } else if (date.contains(' ')) {
      final parts = date.split(' ');
      if (parts.length >= 2) {
        monthPart = parts[0];
        dayPart = parts[1];
      } else {
        monthPart = date;
      }
    } else {
      monthPart = date;
    }

    return GestureDetector(
      onTap: onTap,
      child: ArcheryCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Date Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isHighRecord ? AppColors.accentGold.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    monthPart, 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHighRecord ? AppColors.accentGold : Colors.grey.shade600),
                  ),
                  Text(
                    dayPart,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isHighRecord ? AppColors.accentGold : AppColors.textSlate900),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textSlate900)),
                      Text('/$total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
                      if (isHighRecord) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.emoji_events, size: 16, color: AppColors.accentGold),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(type, style: const TextStyle(fontSize: 12, color: AppColors.textSlate500)),
                  const SizedBox(height: 2),
                  Text('$arrowCount 支箭', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ),

            // Percentage Circle
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade100,
                    color: _getPercentageColor(percentage),
                    strokeWidth: 4,
                  ),
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPercentageColor(percentage)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return AppColors.targetGold;
    if (percentage >= 80) return AppColors.targetRed;
    if (percentage >= 70) return AppColors.targetBlue;
    return AppColors.textSlate400;
  }


  String _formatDate(DateTime date) {
    return DateFormat('MM月dd日').format(date);
  }
}
