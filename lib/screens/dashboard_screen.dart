import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/session_provider.dart';
import '../providers/analytics_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/equipment.dart';
import 'details_screen.dart';
import 'settings_screen.dart';

import '../widgets/score_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    final analyticsState = ref.watch(analyticsProvider);
    final l10n = AppLocalizations.of(context);

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
                    title: Text(
                      l10n.navHome, // "首页" / "Home"
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSlate900),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.read(sessionProvider.notifier).refresh();
                          ref.read(analyticsProvider.notifier).refreshAnalytics();
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                        ),
                      )
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSummaryCard(analyticsState.allTimeStatistics, l10n),
                        const SizedBox(height: 24),

                        // Display sessions from provider
                        ...sessionState.recentSessions.map((session) {
                          final isHighRecord = session == sessionState.bestSession;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildHistoryItem(
                              context: context,
                              isHighRecord: isHighRecord,
                              date: session.date,
                              score: session.totalScore,
                              total: session.maxScore,
                              // Localized Bow Type
                              type: '${_getBowTypeDisplay(session.equipment.bowType, l10n)} • ${session.distance.toInt()}m',
                              percentage: session.scorePercentage,
                              arrowCount: session.arrowCount,
                              l10n: l10n,
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
                          Opacity(
                            opacity: 0.4,
                            child: Column(
                              children: [
                                const Icon(Icons.history, size: 64, color: AppColors.textSlate500),
                                const SizedBox(height: 16),
                                Text(l10n.noRecords, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text(l10n.clickToAdd, style: const TextStyle(fontSize: 12)),
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
                                Text(l10n.showingRecentMessage(sessionState.recentSessions.length.toString()), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

  String _getBowTypeDisplay(BowType type, AppLocalizations l10n) {
    switch (type) {
      case BowType.compound:
        return l10n.bowCompound;
      case BowType.recurve:
        return l10n.bowRecurve;
      case BowType.barebow:
        return l10n.bowBarebow;
      case BowType.longbow:
        return l10n.bowLongbow;
    }
  }

  Widget _buildSummaryCard(dynamic stats, AppLocalizations l10n) {
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
                            Text(l10n.sessions, style: const TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(l10n.monthlyArrowsMessage(stats.currentMonthArrows.toString()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate500)),
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
                            Text(l10n.average, style: const TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(
                              text: stats.trendDisplay, // This might still be hardcoded in model, but acceptable for now
                              color: stats.trend >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                              backgroundColor: stats.trend >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                            ),
                            const SizedBox(width: 4),
                            Text(l10n.trend, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate400)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RepaintBoundary(
                  child: SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: ScoreTrendChart(
                      scores: stats.scoreTrendData.values.toList(),
                      isCompact: true,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.monthlyGoalMessage('${stats.monthlyGoal ?? 3000}'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
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
    required DateTime date,
    required int score,
    required int total,
    required String type,
    required double percentage,
    required int arrowCount,
    required VoidCallback onTap,
    required AppLocalizations l10n,
  }) {
    // Format date based on locale
    final locale = Localizations.localeOf(context).toString();
    final monthFormat = DateFormat.MMM(locale);
    final dayFormat = DateFormat.d(locale);
    
    // For Chinese, we want "X月" and "X日"
    // For English, we want "Jan" and "1"
    
    String monthPart = monthFormat.format(date);
    String dayPart = dayFormat.format(date);

    return GestureDetector(
      onTap: onTap,
      child: ArcheryCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Date Box
                SizedBox(
                  width: 56,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isHighRecord ? AppColors.accentGold : AppColors.primary).withOpacity(0.25),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.calendar_month_outlined,
                              color: (isHighRecord ? AppColors.accentGold : AppColors.primary).withOpacity(0.08),
                              size: 44,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: (isHighRecord ? AppColors.accentGold : AppColors.primary).withOpacity(0.95),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                monthPart,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  dayPart,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isHighRecord ? AppColors.accentGold : AppColors.textSlate900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
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
                  Text('$arrowCount ${l10n.unitArrows}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
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
                    value: (percentage.isNaN || percentage.isInfinite) ? 0 : (percentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade100,
                    color: _getPercentageColor(percentage),
                    strokeWidth: 4,
                  ),
                  Text(
                    '${(percentage.isNaN || percentage.isInfinite) ? 0 : percentage.toInt()}%',
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
}
