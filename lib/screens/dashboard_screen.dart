import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
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

  static const double _historyCardGap = 10;

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
                    backgroundColor:
                        AppColors.backgroundLight.withValues(alpha: 0.95),
                    title: Text(l10n.navHome),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.read(sessionProvider.notifier).refresh();
                          ref
                              .read(analyticsProvider.notifier)
                              .refreshAnalytics();
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
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune,
                              color: AppColors.primary, size: 20),
                        ),
                      )
                    ],
                  ),
                  SliverPadding(
                    padding: AppSpacing.page,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSummaryCard(
                            analyticsState.allTimeStatistics, l10n),
                        const SizedBox(height: AppSpacing.xl),

                        // Display sessions from provider
                        ...sessionState.recentSessions.map((session) {
                          final isHighRecord =
                              session == sessionState.bestSession;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: _historyCardGap),
                            child: _buildHistoryItem(
                              context: context,
                              isHighRecord: isHighRecord,
                              date: session.date,
                              score: session.totalScore,
                              total: session.maxScore,
                              // Localized Bow Type
                              type:
                                  '${_getBowTypeDisplay(session.equipment.bowType, l10n)} * ${session.distance.toInt()}m',
                              percentage: session.scorePercentage,
                              arrowCount: session.arrowCount,
                              l10n: l10n,
                              onTap: () {
                                ref
                                    .read(selectedSessionProvider.notifier)
                                    .state = session;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const DetailsScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: AppSpacing.xxl),
                        if (sessionState.sessions.isEmpty)
                          _buildEmptyState(l10n)
                        else
                          Opacity(
                            opacity: 0.4,
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 48, color: AppColors.textSlate500),
                                const SizedBox(height: 12),
                                Text(
                                    l10n.showingRecentMessage(sessionState
                                        .recentSessions.length
                                        .toString()),
                                    style: AppTextStyles.subLabel.copyWith(
                                      fontWeight: FontWeight.w600,
                                    )),
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
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius:
                    const BorderRadius.only(bottomLeft: Radius.circular(100)),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.card,
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
                            Text('${stats.totalSessions}',
                                style: AppTextStyles.largeNumber),
                            const SizedBox(width: 4),
                            Text(l10n.sessions,
                                style: const TextStyle(
                                    color: AppColors.textSlate500,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                                l10n.monthlyArrowsMessage(
                                    stats.currentMonthArrows.toString()),
                                style: AppTextStyles.subLabel.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
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
                            Text(stats.avgArrowScore.toStringAsFixed(1),
                                style: AppTextStyles.largeNumber.copyWith(
                                  color: AppColors.primary,
                                )),
                            const SizedBox(width: 4),
                            Text(l10n.average,
                                style: const TextStyle(
                                    color: AppColors.textSlate500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(
                              text: stats
                                  .trendDisplay, // This might still be hardcoded in model, but acceptable for now
                              color: stats.trend >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              backgroundColor: stats.trend >= 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                            ),
                            const SizedBox(width: 4),
                            Text(l10n.trend,
                                style: AppTextStyles.subLabel.copyWith(
                                  color: AppColors.textSlate400,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        l10n.monthlyGoalMessage('${stats.monthlyGoal ?? 3000}'),
                        style: AppTextStyles.subLabel.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    Text('${stats.monthlyGoalProgress.toStringAsFixed(0)}%',
                        style: AppTextStyles.subLabel.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (stats.monthlyGoalProgress / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceSubtle,
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          SizedBox(
            width: 124,
            height: 124,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildTargetRing(
                    112, AppColors.textSlate300.withValues(alpha: 0.45)),
                _buildTargetRing(78, AppColors.primary.withValues(alpha: 0.18)),
                _buildTargetRing(
                    44, AppColors.accentGold.withValues(alpha: 0.35)),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.homeEmptyPrompt,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSlate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRing(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
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

    final isChinese = locale.startsWith('zh');
    final String monthPart =
        isChinese ? '${date.month}月' : monthFormat.format(date).toUpperCase();
    final String dayPart = dayFormat.format(date);
    final String infoLine = isChinese
        ? '$type · $arrowCount支箭'
        : '$type · $arrowCount ${l10n.unitArrows}';

    return GestureDetector(
      onTap: onTap,
      child: ArcheryCard(
        padding: AppSpacing.cardCompact,
        child: Row(
          children: [
            // Date Box
            SizedBox(
              width: 58,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isHighRecord
                        ? [
                            AppColors.accentGold.withValues(alpha: 0.12),
                            AppColors.accentGold.withValues(alpha: 0.03),
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.09),
                            AppColors.primary.withValues(alpha: 0.02),
                          ],
                  ),
                  border: Border.all(
                    color: (isHighRecord
                            ? AppColors.accentGold
                            : AppColors.primary)
                        .withValues(alpha: 0.26),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 17,
                      decoration: BoxDecoration(
                        color: isHighRecord
                            ? AppColors.accentGold
                            : AppColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            monthPart,
                            maxLines: 1,
                            style: AppTextStyles.micro.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          dayPart,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isHighRecord
                                ? AppColors.accentRust
                                : AppColors.textSlate900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 9, right: 9, bottom: 5),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: (isHighRecord
                                  ? AppColors.accentGold
                                  : AppColors.primary)
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$score',
                          style: AppTextStyles.mediumNumber.copyWith(
                            color: AppColors.textSlate900,
                          )),
                      Text('/$total',
                          style: AppTextStyles.numberDenominator.copyWith(
                            fontSize: 16,
                          )),
                      if (isHighRecord) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.emoji_events,
                            size: 16, color: AppColors.accentGold),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    infoLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subLabel,
                  ),
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
                    value: (percentage.isNaN || percentage.isInfinite)
                        ? 0
                        : (percentage / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceSubtle,
                    color: _getPercentageColor(percentage),
                    strokeWidth: 4,
                  ),
                  Text(
                    '${(percentage.isNaN || percentage.isInfinite) ? 0 : percentage.toInt()}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _getPercentageColor(percentage)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.surfaceIcon),
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
