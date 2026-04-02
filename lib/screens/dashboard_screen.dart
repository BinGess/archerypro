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
                              bowLabel: _getBowTypeDisplay(
                                  session.equipment.bowType, l10n),
                              distance: session.distance,
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
    required String bowLabel,
    required double distance,
    required double percentage,
    required int arrowCount,
    required VoidCallback onTap,
    required AppLocalizations l10n,
  }) {
    // Format date based on locale
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final monthFormat = DateFormat.MMM(localeTag);

    final isChinese = localeTag.startsWith('zh');
    final isJapanese = localeTag.startsWith('ja');
    final String monthPart = isChinese
        ? '${date.month}月'
        : monthFormat.format(date);
    final String dayPart = date.day.toString();
    final String dateLabel = (isChinese || isJapanese)
        ? '$monthPart$dayPart日'
        : '$monthPart $dayPart';
    final normalizedPercentage = (percentage.isNaN || percentage.isInfinite)
        ? 0.0
        : percentage.clamp(0.0, 100.0);
    final accentColor = isHighRecord
        ? AppColors.accentGold
        : _getPercentageColor(normalizedPercentage);
    final subtitle = isChinese
        ? '$bowLabel · ${distance.toInt()}m · $arrowCount支箭'
        : '$bowLabel · ${distance.toInt()}m · $arrowCount ${l10n.unitArrows}';
    final dateChipBackground =
        Color.alphaBlend(accentColor.withValues(alpha: 0.14), Colors.white);
    final dateChipBorder = accentColor.withValues(alpha: 0.24);
    final dateChipTextColor = Color.alphaBlend(
        accentColor.withValues(alpha: 0.55), AppColors.textSlate900);

    return GestureDetector(
      onTap: onTap,
      child: ArcheryCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg - 1),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CardTexturePainter(
                      tint: accentColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: dateChipBackground,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: dateChipBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month,
                                  size: 12,
                                  color: dateChipTextColor.withValues(
                                      alpha: 0.86)),
                              const SizedBox(width: 4),
                              Text(
                                dateLabel,
                                style: AppTextStyles.micro.copyWith(
                                  color: dateChipTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isHighRecord) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accentGold.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.accentGold
                                    .withValues(alpha: 0.38),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events,
                                    size: 11, color: AppColors.accentRust),
                                const SizedBox(width: 3),
                                Text(
                                  isChinese
                                      ? '最佳记录'
                                      : (isJapanese
                                          ? 'ベスト'
                                          : l10n.competitionBest),
                                  style: AppTextStyles.micro.copyWith(
                                    color: AppColors.accentRust,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: AppColors.surfaceIcon, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$score/$total',
                      style: AppTextStyles.mediumNumber.copyWith(
                        color: AppColors.textSlate900,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subLabel.copyWith(
                        color: AppColors.textSlate700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: normalizedPercentage / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceSubtle,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: normalizedPercentage.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                              TextSpan(
                                text: '%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

class _CardTexturePainter extends CustomPainter {
  final Color tint;

  const _CardTexturePainter({required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final softFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tint.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, softFill);

    final stripePaint = Paint()
      ..color = tint.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const stripeGap = 16.0;
    for (double x = -size.height; x < size.width; x += stripeGap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        stripePaint,
      );
    }

    final orbPaint = Paint()..color = tint.withValues(alpha: 0.05);
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.1),
      size.shortestSide * 0.12,
      orbPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.86),
      size.shortestSide * 0.08,
      orbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CardTexturePainter oldDelegate) {
    return oldDelegate.tint != tint;
  }
}
