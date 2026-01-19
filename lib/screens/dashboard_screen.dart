import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/session_provider.dart';
import '../providers/analytics_provider.dart';

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
                                Text('No training sessions yet', style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 8),
                                Text('Tap "Score" to start your first session', style: TextStyle(fontSize: 12)),
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
                                Text('Showing ${sessionState.recentSessions.length} recent sessions', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                            const Text('sessions', style: TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('${stats.currentMonthArrows} arrows this month', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate500)),
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
                            const Text('avg', style: TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.w600, fontSize: 13)),
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
                            const Text('Trend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate400)),
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
                  child: CustomPaint(painter: CustomCurvePainter(color: AppColors.primary)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Goal: ${stats.monthlyGoal ?? 3000}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          if (isHighRecord)
            Positioned(
              left: 0,
              bottom: 0,
              top: 0,
              child: Container(width: 4, color: AppColors.accentGold),
            ),
          ArcheryCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isHighRecord) ...[
                                StatusBadge(text: 'BEST', color: AppColors.accentGold, backgroundColor: AppColors.accentGold.withOpacity(0.1)),
                                const SizedBox(width: 8),
                              ],
                              Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate400)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('$score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isHighRecord ? AppColors.primary : AppColors.textSlate900)),
                              Text('/$total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textSlate400)),
                            ],
                          ),
                          Text(type, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isHighRecord ? AppColors.primary : AppColors.textSlate400)),
                          Icon(Icons.chevron_right, size: 16, color: isHighRecord ? AppColors.primary : AppColors.textSlate400),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: isHighRecord ? Colors.white : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: _buildMiniStats(percentage, arrowCount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStats(double percentage, int arrowCount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Accuracy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Text('$arrowCount arrows', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd').format(date).toUpperCase();
  }
}
