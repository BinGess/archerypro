import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../models/competition_settings.dart';
import '../../providers/competition_provider.dart';
import '../../services/logger_service.dart';
import '../../theme/app_colors.dart';

class CompetitionResultsView extends StatelessWidget {
  final List<CompetitionEndResult> endResults;
  final CompetitionSettings settings;
  final VoidCallback onDone;
  final String? heroTitle;
  final String? doneLabel;
  final int maxArrowScore;

  const CompetitionResultsView({
    super.key,
    required this.endResults,
    required this.settings,
    required this.onDone,
    this.heroTitle,
    this.doneLabel,
    this.maxArrowScore = 10,
  });

  List<int> get _endScores => endResults.map((e) => e.totalScore).toList();
  int get _maxPerEnd => settings.arrowsPerEnd * maxArrowScore;
  int get totalScore => endResults.fold(0, (a, r) => a + r.totalScore);
  int get maxScore => endResults.length * _maxPerEnd;
  int get _shotArrows => endResults.fold(0, (a, r) => a + r.arrowScores.length);

  CompetitionEndResult? get bestEnd => endResults.isEmpty
      ? null
      : endResults.reduce((a, b) => a.totalScore >= b.totalScore ? a : b);
  CompetitionEndResult? get worstEnd => endResults.isEmpty
      ? null
      : endResults.reduce((a, b) => a.totalScore <= b.totalScore ? a : b);

  double get averagePerEnd =>
      endResults.isEmpty ? 0 : totalScore / endResults.length;
  double get averagePerArrow => _shotArrows == 0 ? 0 : totalScore / _shotArrows;
  double get scoreRate => maxScore == 0 ? 0 : (totalScore / maxScore) * 100;

  int get goldHits {
    return endResults.expand((r) => r.arrowScores).where((s) => s >= 9).length;
  }

  int get missHits {
    return endResults.expand((r) => r.arrowScores).where((s) => s == 0).length;
  }

  double get goldRate => _shotArrows == 0 ? 0 : (goldHits / _shotArrows) * 100;
  double get missRate => _shotArrows == 0 ? 0 : (missHits / _shotArrows) * 100;

  double get endStdDev {
    if (_endScores.length < 2) return 0;
    final mean = averagePerEnd;
    final variance =
        _endScores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) /
            _endScores.length;
    return math.sqrt(variance);
  }

  double get consistencyIndex {
    if (_maxPerEnd == 0) return 0;
    return (100 - (endStdDev / _maxPerEnd) * 100).clamp(0.0, 100.0).toDouble();
  }

  double get firstHalfAvg {
    if (_endScores.isEmpty) return 0;
    final mid = (_endScores.length / 2).ceil();
    final firstHalf = _endScores.take(mid).toList();
    if (firstHalf.isEmpty) return 0;
    return firstHalf.reduce((a, b) => a + b) / firstHalf.length;
  }

  double get secondHalfAvg {
    if (_endScores.isEmpty) return 0;
    final mid = (_endScores.length / 2).ceil();
    final secondHalf = _endScores.skip(mid).toList();
    if (secondHalf.isEmpty) return firstHalfAvg;
    return secondHalf.reduce((a, b) => a + b) / secondHalf.length;
  }

  double get trendDelta => secondHalfAvg - firstHalfAvg;

  double get averageShootingSeconds {
    final validMs = endResults
        .map((e) => e.shootingTime.inMilliseconds)
        .where((ms) => ms > 0)
        .toList();
    if (validMs.isEmpty) return 0;
    final avgMs = validMs.reduce((a, b) => a + b) / validMs.length;
    return avgMs / 1000.0;
  }

  double get totalShootingSeconds {
    final totalMs = endResults
        .map((e) => e.shootingTime.inMilliseconds)
        .where((ms) => ms > 0)
        .fold<int>(0, (sum, ms) => sum + ms);
    return totalMs / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeroHeader(context, l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                children: [
                  _buildKpiGrid(context),
                  const SizedBox(height: 12),
                  _buildAnalysisCard(context),
                  const SizedBox(height: 12),
                  _buildTrendCard(context),
                  const SizedBox(height: 12),
                  _buildEndBreakdownCard(context, l10n),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _showPosterSheet(context),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: Text(_t(context, zh: '分享', en: 'Share')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSlate900,
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          doneLabel ?? l10n.competitionDone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPosterSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSlate300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      _ResultPosterSection(
                        totalScore: totalScore,
                        maxScore: maxScore,
                        scoreRate: scoreRate,
                        averagePerArrow: averagePerArrow,
                        averagePerEnd: averagePerEnd,
                        goldRate: goldRate,
                        consistencyIndex: consistencyIndex,
                        endCount: endResults.length,
                        totalArrows: _shotArrows,
                        bestEndNumber: bestEnd?.endNumber,
                        bestEndScore: bestEnd?.totalScore,
                        worstEndNumber: worstEnd?.endNumber,
                        worstEndScore: worstEnd?.totalScore,
                        trendDelta: trendDelta,
                        endScores: List<int>.from(_endScores),
                        appName: AppLocalizations.of(sheetContext).appName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                heroTitle ?? l10n.competitionComplete,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ $maxScore',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _heroPill(
                label: _t(context, zh: '得分率', en: 'Rate'),
                value: '${scoreRate.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroTag(
                _t(context,
                    zh: '平均 ${averagePerEnd.toStringAsFixed(1)} 分/组',
                    en: 'Avg ${averagePerEnd.toStringAsFixed(1)} / end'),
              ),
              _heroTag(
                _t(context,
                    zh: '金区命中 ${goldRate.toStringAsFixed(1)}%',
                    en: 'Gold ${goldRate.toStringAsFixed(1)}%'),
              ),
              _heroTag(
                trendDelta >= 0
                    ? _t(
                        context,
                        zh: '后程 +${trendDelta.toStringAsFixed(1)}',
                        en: '2nd half +${trendDelta.toStringAsFixed(1)}',
                      )
                    : _t(
                        context,
                        zh: '后程 ${trendDelta.toStringAsFixed(1)}',
                        en: '2nd half ${trendDelta.toStringAsFixed(1)}',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _kpiCard(
                context,
                title: _t(context, zh: '箭均分', en: 'Avg/Arrow'),
                value: averagePerArrow.toStringAsFixed(2),
                icon: Icons.my_location_rounded,
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: _kpiCard(
                context,
                title: _t(context, zh: '稳定性', en: 'Consistency'),
                value: '${consistencyIndex.toStringAsFixed(1)}%',
                icon: Icons.insights_rounded,
                color: const Color(0xFF0F766E),
              ),
            ),
            SizedBox(
              width: width,
              child: _kpiCard(
                context,
                title: _t(context, zh: '最佳组', en: 'Best End'),
                value: '${bestEnd?.totalScore ?? '-'}',
                subtitle: bestEnd == null
                    ? null
                    : _t(context,
                        zh: '第 ${bestEnd!.endNumber} 组',
                        en: 'End ${bestEnd!.endNumber}'),
                icon: Icons.star_rounded,
                color: AppColors.accentGold,
              ),
            ),
            SizedBox(
              width: width,
              child: _kpiCard(
                context,
                title: _t(context, zh: '平均用时', en: 'Avg Time'),
                value: averageShootingSeconds <= 0
                    ? '--'
                    : _t(
                        context,
                        zh: '${averageShootingSeconds.toStringAsFixed(0)}秒',
                        en: '${averageShootingSeconds.toStringAsFixed(0)}s',
                      ),
                subtitle: totalShootingSeconds <= 0
                    ? null
                    : _t(
                        context,
                        zh: '总计 ${totalShootingSeconds.toStringAsFixed(0)}秒',
                        en: 'Total ${totalShootingSeconds.toStringAsFixed(0)}s',
                      ),
                icon: Icons.timer_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSlate500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              height: 1,
              color: AppColors.textSlate900,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSlate400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context) {
    final trendColor = trendDelta >= 0 ? AppColors.success : AppColors.danger;
    final trendText = trendDelta >= 0
        ? _t(
            context,
            zh: '后半程上升 ${trendDelta.toStringAsFixed(1)} 分',
            en: 'Second half +${trendDelta.toStringAsFixed(1)}',
          )
        : _t(
            context,
            zh: '后半程下降 ${trendDelta.abs().toStringAsFixed(1)} 分',
            en: 'Second half -${trendDelta.abs().toStringAsFixed(1)}',
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, zh: '本场分析', en: 'Session Insights'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _insightTile(
                  title: _t(context, zh: '金区命中率', en: 'Gold Rate'),
                  value: '${goldRate.toStringAsFixed(1)}%',
                  sub: _t(context,
                      zh: '$goldHits / $_shotArrows 箭',
                      en: '$goldHits / $_shotArrows arrows'),
                  valueColor: AppColors.accentGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _insightTile(
                  title: _t(context, zh: '脱靶率', en: 'Miss Rate'),
                  value: '${missRate.toStringAsFixed(1)}%',
                  sub: _t(context, zh: '$missHits 次脱靶', en: '$missHits misses'),
                  valueColor:
                      missHits == 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: trendColor.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Icon(
                  trendDelta >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: trendColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 12,
                      color: trendColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightTile({
    required String title,
    required String value,
    required String sub,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSlate500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              height: 1,
              color: valueColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSlate400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, zh: '组间走势', en: 'End Trend'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(context, zh: '每组总分变化', en: 'Score progression by end'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSlate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _EndTrendPainter(
                scores: _endScores,
                maxPerEnd: _maxPerEnd,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t(context,
                    zh: '起始: ${_endScores.isEmpty ? '-' : _endScores.first}',
                    en: 'Start: ${_endScores.isEmpty ? '-' : _endScores.first}'),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSlate400,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _t(context,
                    zh: '结束: ${_endScores.isEmpty ? '-' : _endScores.last}',
                    en: 'End: ${_endScores.isEmpty ? '-' : _endScores.last}'),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSlate400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEndBreakdownCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, zh: '分组明细', en: 'End Breakdown'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 10),
          ...endResults.map((result) {
            final normalized =
                (result.totalScore / _maxPerEnd).clamp(0.0, 1.0).toDouble();
            final isBest = result == bestEnd;
            final isWorst = result == worstEnd && result != bestEnd;
            final borderColor = isBest
                ? AppColors.accentGold.withValues(alpha: 0.45)
                : (isWorst
                    ? AppColors.danger.withValues(alpha: 0.25)
                    : AppColors.borderLight);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${l10n.endNumber} ${result.endNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSlate500,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isBest) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: AppColors.accentGold,
                        ),
                      ],
                      if (isWorst) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.danger,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${result.totalScore} / $_maxPerEnd',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSlate900,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: normalized,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceMid,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: result.arrowScores.map((s) {
                      return Container(
                        width: 24,
                        height: 22,
                        margin: const EdgeInsets.only(right: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _scoreColor(s).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s == 0 ? 'M' : (s == 11 ? 'X' : '$s'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor(s),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _t(
    BuildContext context, {
    required String zh,
    required String en,
  }) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  Color _scoreColor(int score) {
    if (score >= 9) return const Color(0xFFB8860B);
    if (score >= 7) return AppColors.targetRed;
    if (score >= 5) return AppColors.targetBlue;
    if (score >= 3) return AppColors.targetBlack;
    return AppColors.textSlate400;
  }
}

class _ResultPosterSection extends StatefulWidget {
  final int totalScore;
  final int maxScore;
  final double scoreRate;
  final double averagePerArrow;
  final double averagePerEnd;
  final double goldRate;
  final double consistencyIndex;
  final int endCount;
  final int totalArrows;
  final int? bestEndNumber;
  final int? bestEndScore;
  final int? worstEndNumber;
  final int? worstEndScore;
  final double trendDelta;
  final List<int> endScores;
  final String appName;

  const _ResultPosterSection({
    required this.totalScore,
    required this.maxScore,
    required this.scoreRate,
    required this.averagePerArrow,
    required this.averagePerEnd,
    required this.goldRate,
    required this.consistencyIndex,
    required this.endCount,
    required this.totalArrows,
    required this.bestEndNumber,
    required this.bestEndScore,
    required this.worstEndNumber,
    required this.worstEndScore,
    required this.trendDelta,
    required this.endScores,
    required this.appName,
  });

  @override
  State<_ResultPosterSection> createState() => _ResultPosterSectionState();
}

class _ResultPosterSectionState extends State<_ResultPosterSection> {
  final GlobalKey _posterKey = GlobalKey();
  final _logger = LoggerService();
  final List<File> _tempFilesToCleanup = [];
  Timer? _shareCleanupTimer;
  bool _isExporting = false;
  String? _statusText;
  bool _statusError = false;

  String _t({required String zh, required String en}) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  void _setStatus(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusText = text;
      _statusError = isError;
    });
  }

  @override
  void dispose() {
    _shareCleanupTimer?.cancel();
    _cleanupTempFiles();
    super.dispose();
  }

  /// Clean up temporary poster files
  Future<void> _cleanupTempFiles() async {
    for (final file in _tempFilesToCleanup) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        _logger.log('Failed to cleanup temp file: ${file.path}', level: LogLevel.warning);
      }
    }
    _tempFilesToCleanup.clear();
  }

  /// Generate unique filename to avoid collisions
  String _generateUniqueFileName() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = math.Random().nextInt(9999).toString().padLeft(4, '0');
    return 'archery_poster_${timestamp}_$random';
  }

  bool _isSaveResultSuccess(dynamic result) {
    try {
      if (result == null) return false;

      // Explicit boolean success
      if (result is bool) return result;

      // Map with explicit success indicators
      if (result is Map) {
        // Check explicit success flag first
        final dynamic isSuccess = result['isSuccess'] ?? result['success'];
        if (isSuccess is bool) return isSuccess;

        // Check for explicit error
        final dynamic errorMsg = result['error'] ?? result['errorMessage'];
        if (errorMsg != null) {
          _logger.log('Save result contains error: $errorMsg', level: LogLevel.warning);
          return false;
        }

        // Only accept if has valid file path AND not explicitly marked failed
        final dynamic filePath = result['filePath'] ?? result['savedFilePath'];
        if (filePath is String && filePath.isNotEmpty) return true;

        // Check for valid ID (must be positive)
        final dynamic id = result['id'] ?? result['ID'];
        if (id is num && id > 0) return true;

        // Map but no valid success indicators
        _logger.log('Save result Map has no valid success indicators: $result',
          level: LogLevel.warning);
        return false;
      }

      // Reject other types - too ambiguous
      _logger.log('Save result has unexpected type: ${result.runtimeType}',
        level: LogLevel.warning);
      return false;
    } catch (e, stackTrace) {
      _logger.logError('Error validating save result', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<Uint8List> _capturePosterBytes() async {
    final startTime = DateTime.now();
    try {
      // Pre-flight check
      if (_posterKey.currentContext == null) {
        throw StateError('Poster key not attached to widget tree');
      }

      final pixelRatio =
          (MediaQuery.of(context).devicePixelRatio * 2).clamp(2.0, 3.0);
      RenderRepaintBoundary? boundary;

      // Extended polling with adaptive backoff
      const maxIterations = 15;
      for (var i = 0; i < maxIterations; i++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) throw StateError('Widget unmounted during capture');

        final renderObject = _posterKey.currentContext?.findRenderObject();
        if (renderObject is RenderRepaintBoundary &&
            !renderObject.debugNeedsPaint) {
          boundary = renderObject;
          break;
        }

        // Adaptive delay: 20ms -> 40ms -> 60ms
        final delayMs = i < 5 ? 20 : (i < 10 ? 40 : 60);
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }

      if (boundary == null) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        throw StateError('Screenshot timeout: Poster rendering not complete after ${elapsed}ms');
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      if (!mounted) {
        image.dispose();
        throw StateError('Widget unmounted after toImage');
      }

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('Failed to encode poster to PNG');
      }

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _logger.log('Screenshot captured successfully in ${elapsed}ms');
      return byteData.buffer.asUint8List();
    } catch (e, stackTrace) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _logger.logError(
        'Failed to capture poster screenshot after ${elapsed}ms',
        error: e,
        stackTrace: stackTrace,
        context: 'PosterExport',
      );
      rethrow;
    }
  }

  Future<File> _persistToTempFile(Uint8List bytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = _generateUniqueFileName();
      final path = '${directory.path}/$fileName.png';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      // Track file for cleanup
      _tempFilesToCleanup.add(file);

      _logger.log('Persisted poster to temp file: $path');
      return file;
    } catch (e, stackTrace) {
      _logger.logError(
        'Failed to persist poster to temp file',
        error: e,
        stackTrace: stackTrace,
        context: 'PosterExport',
      );
      rethrow;
    }
  }

  Future<bool> _ensureSavePermission() async {
    if (!Platform.isIOS && !Platform.isAndroid) return true;

    final permission =
        Platform.isIOS ? Permission.photosAddOnly : Permission.photos;
    var status = await permission.status;
    if (!mounted) return false;

    if (status.isGranted || status.isLimited) return true;

    status = await permission.request();
    if (!mounted) return false;

    if (status.isGranted || status.isLimited) return true;

    // Handle different denial states
    if (status.isPermanentlyDenied) {
      _setStatus(
        _t(
          zh: '照片权限被永久拒绝。请到系统设置中开启“照片”权限后重试。',
          en: 'Photo permission is permanently denied. Enable it in system settings and try again.',
        ),
        isError: true,
      );
      return false;
    }

    if (status.isRestricted) {
      _setStatus(
        _t(
          zh: '照片权限受限制（可能由家长控制）。请在系统设置中检查。',
          en: 'Photo access is restricted (possibly by parental controls). Please check system settings.',
        ),
        isError: true,
      );
      return false;
    }

    if (status.isDenied) {
      _setStatus(
        _t(
          zh: '需要照片权限才能保存海报。请在权限弹窗中选择“允许”。',
          en: 'Photo access is required to save posters. Please choose "Allow" in the permission dialog.',
        ),
        isError: true,
      );
      return false;
    }

    // Other denied states
    _setStatus(
      _t(
        zh: '未获得照片权限，无法保存海报。',
        en: 'Photo permission denied, unable to save poster.',
      ),
      isError: true,
    );
    return false;
  }

  Future<void> _savePoster() async {
    if (_isExporting) return;

    // Clean up old temp files before starting
    _cleanupTempFiles();

    final startTime = DateTime.now();
    setState(() {
      _isExporting = true;
      _statusText = null;
    });

    try {
      final granted = await _ensureSavePermission();
      if (!mounted) return;
      if (!granted) return;

      final bytes = await _capturePosterBytes();
      if (!mounted) return;

      // Try direct byte save first (more efficient, works on most platforms)
      var result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: _generateUniqueFileName(),
        isReturnImagePathOfIOS: false,
      );
      if (!mounted) return;

      if (!_isSaveResultSuccess(result)) {
        _logger.log('Direct image save failed, trying file-based save',
          level: LogLevel.warning);

        // Fallback: persist to temp file then save (works on older Android versions)
        final file = await _persistToTempFile(bytes);
        if (!mounted) return;

        result = await ImageGallerySaver.saveFile(
          file.path,
          name: _generateUniqueFileName(),
          isReturnPathOfIOS: false,
        );
        if (!mounted) return;
      }

      if (!_isSaveResultSuccess(result)) {
        _logger.log('Both save attempts failed. Result: $result',
          level: LogLevel.error);
        throw StateError('Gallery save failed after both attempts');
      }

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _logger.log('Poster saved successfully in ${elapsed}ms');

      _setStatus(
        _t(zh: '海报已保存到相册', en: 'Poster saved to gallery'),
      );
    } catch (e, stackTrace) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _logger.logError(
        'Failed to save poster after ${elapsed}ms',
        error: e,
        stackTrace: stackTrace,
        context: 'PosterExport',
      );

      if (!mounted) return;
      _setStatus(
        _t(
          zh: '保存失败。请检查系统照片权限后重试。',
          en: 'Save failed. Please check photo permission and try again.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _sharePoster() async {
    if (_isExporting) return;

    final startTime = DateTime.now();

    // Get share position safely
    RenderBox? box;
    try {
      final renderObj = context.findRenderObject();
      if (renderObj is RenderBox && renderObj.hasSize) {
        box = renderObj;
      }
    } catch (e) {
      _logger.log('Could not determine share position', level: LogLevel.warning);
    }

    setState(() {
      _isExporting = true;
      _statusText = null;
    });

    Rect? sharePositionOrigin;
    if (box != null) {
      sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
    } else {
      // iPad requires a non-empty origin rect when using popover style share sheet.
      final size = MediaQuery.of(context).size;
      final center = Offset(size.width / 2, size.height / 2);
      sharePositionOrigin = center & const Size(1, 1);
    }

    try {
      final bytes = await _capturePosterBytes();
      if (!mounted) return;

      final posterFile = await _persistToTempFile(bytes);
      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(posterFile.path)],
          text: _buildShareCaption(),
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      if (!mounted) return;

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _logger.log('Share panel opened successfully in ${elapsed}ms');

      _setStatus(
        _t(zh: '海报已打开分享面板', en: 'Share panel opened'),
      );

      // Schedule cleanup of share temp file after delay
      _shareCleanupTimer?.cancel();
      _shareCleanupTimer = Timer(const Duration(seconds: 30), () {
        _cleanupTempFiles();
      });
    } catch (e, stackTrace) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _logger.logError(
        'Failed to share poster after ${elapsed}ms',
        error: e,
        stackTrace: stackTrace,
        context: 'PosterExport',
      );

      if (!mounted) return;
      final fallbackShared = await _shareAsTextFallback(
        sharePositionOrigin: sharePositionOrigin,
      );
      if (!mounted) return;
      if (fallbackShared) {
        _setStatus(
          _t(
            zh: '图片分享失败，已回退为文本分享。',
            en: 'Image share failed. Fell back to text sharing.',
          ),
        );
      } else {
        _setStatus(
          _t(
            zh: '分享失败。请检查系统分享权限后重试。',
            en: 'Share failed. Please check system share permission and try again.',
          ),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _buildShareCaption() {
    return _t(
      zh: '我在${widget.appName}打出了 ${widget.totalScore}/${widget.maxScore}，来挑战我！',
      en: 'I scored ${widget.totalScore}/${widget.maxScore} in ${widget.appName}. Come challenge me!',
    );
  }

  String _buildFallbackShareText() {
    final avgArrow = widget.averagePerArrow.toStringAsFixed(2);
    final avgEnd = widget.averagePerEnd.toStringAsFixed(1);
    final consistency = widget.consistencyIndex.toStringAsFixed(1);
    final rate = widget.scoreRate.toStringAsFixed(1);
    if (Localizations.localeOf(context).languageCode == 'zh') {
      return '我在${widget.appName}完成了一场训练\n'
          '总分：${widget.totalScore}/${widget.maxScore}\n'
          '得分率：$rate%\n'
          '箭均分：$avgArrow | 组均分：$avgEnd\n'
          '稳定性：$consistency%\n'
          '来挑战我吧！';
    }
    return 'I finished a training session in ${widget.appName}\n'
        'Score: ${widget.totalScore}/${widget.maxScore}\n'
        'Rate: $rate%\n'
        'Avg/Arrow: $avgArrow | Avg/End: $avgEnd\n'
        'Consistency: $consistency%\n'
        'Can you beat me?';
  }

  Future<bool> _shareAsTextFallback({required Rect? sharePositionOrigin}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _buildFallbackShareText(),
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      _logger.log('Text fallback share opened successfully');
      return true;
    } catch (fallbackError, fallbackStack) {
      _logger.logError(
        'Fallback text sharing also failed',
        error: fallbackError,
        stackTrace: fallbackStack,
        context: 'PosterExport',
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportLabel = _t(zh: '正在生成海报...', en: 'Preparing poster...');
    final now = DateTime.now();
    final dateString =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(zh: '成绩海报', en: 'Score Poster'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              zh: '一键保存或分享，让朋友来挑战你的成绩',
              en: 'Save or share and challenge your friends',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSlate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            key: _posterKey,
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B1A4A),
                      Color(0xFF10398E),
                      Color(0xFF0EA5A4)
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          dateString,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _t(zh: '本场总分', en: 'TOTAL SCORE'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.totalScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 68,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '/ ${widget.maxScore}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _posterMetric(
                          _t(zh: '得分率', en: 'Rate'),
                          '${widget.scoreRate.toStringAsFixed(1)}%',
                        ),
                        _posterMetric(
                          _t(zh: '箭均分', en: 'Avg'),
                          widget.averagePerArrow.toStringAsFixed(2),
                        ),
                        _posterMetric(
                          _t(zh: '金区命中', en: 'Gold'),
                          '${widget.goldRate.toStringAsFixed(1)}%',
                        ),
                        _posterMetric(
                          _t(zh: '组均分', en: 'Avg/End'),
                          widget.averagePerEnd.toStringAsFixed(1),
                        ),
                        _posterMetric(
                          _t(zh: '稳定性', en: 'Consistency'),
                          '${widget.consistencyIndex.toStringAsFixed(1)}%',
                        ),
                        _posterMetric(
                          _t(zh: '总箭数', en: 'Arrows'),
                          '${widget.totalArrows}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _t(zh: '最佳组', en: 'Best End'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            widget.bestEndScore == null
                                ? '--'
                                : _t(
                                    zh: '第${widget.bestEndNumber}组 ${widget.bestEndScore}分',
                                    en: 'End ${widget.bestEndNumber} ${widget.bestEndScore}',
                                  ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _t(zh: '后程趋势', en: 'Trend'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            widget.trendDelta >= 0
                                ? _t(
                                    zh: '+${widget.trendDelta.toStringAsFixed(1)} 分',
                                    en: '+${widget.trendDelta.toStringAsFixed(1)}',
                                  )
                                : _t(
                                    zh: '${widget.trendDelta.toStringAsFixed(1)} 分',
                                    en: widget.trendDelta.toStringAsFixed(1),
                                  ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.endScores.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(
                            widget.endScores.length > 8
                                ? 8
                                : widget.endScores.length, (i) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _t(
                                zh: '${i + 1}组:${widget.endScores[i]}',
                                en: 'E${i + 1}:${widget.endScores[i]}',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }),
                      ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24)),
                      ),
                      child: Text(
                        _t(
                          zh: '我完成了 ${widget.endCount} 组射箭训练，来 ${widget.appName} 超越我！',
                          en: 'Finished ${widget.endCount} ends. Beat me in ${widget.appName}!',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _savePoster,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(_t(zh: '保存海报', en: 'Save Poster')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSlate900,
                    side: const BorderSide(color: AppColors.borderLight),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _sharePoster,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(_t(zh: '分享海报', en: 'Share Poster')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_statusText != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _statusError
                    ? Colors.red.withValues(alpha: 0.08)
                    : Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _statusError
                      ? Colors.red.withValues(alpha: 0.22)
                      : Colors.green.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                _statusText!,
                style: TextStyle(
                  fontSize: 12,
                  color: _statusError ? Colors.red.shade700 : Colors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (_isExporting) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  exportLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSlate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _posterMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EndTrendPainter extends CustomPainter {
  final List<int> scores;
  final int maxPerEnd;

  _EndTrendPainter({
    required this.scores,
    required this.maxPerEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgLine = Paint()
      ..color = AppColors.surfaceMid
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bgLine);
    }

    if (scores.isEmpty) return;
    if (scores.length == 1) {
      final dotPaint = Paint()..color = AppColors.primary;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, dotPaint);
      return;
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final areaPath = Path();
    final linePath = Path();

    for (var i = 0; i < scores.length; i++) {
      final x = i * (size.width / (scores.length - 1));
      final ratio = maxPerEnd == 0 ? 0.0 : (scores[i] / maxPerEnd);
      final y = size.height - (ratio.clamp(0.0, 1.0).toDouble() * size.height);
      final point = Offset(x, y);

      if (i == 0) {
        linePath.moveTo(point.dx, point.dy);
        areaPath.moveTo(point.dx, size.height);
        areaPath.lineTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
        areaPath.lineTo(point.dx, point.dy);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.24),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    for (var i = 0; i < scores.length; i++) {
      final x = i * (size.width / (scores.length - 1));
      final ratio = maxPerEnd == 0 ? 0.0 : (scores[i] / maxPerEnd);
      final y = size.height - (ratio.clamp(0.0, 1.0).toDouble() * size.height);
      canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EndTrendPainter oldDelegate) {
    return oldDelegate.scores != scores || oldDelegate.maxPerEnd != maxPerEnd;
  }
}
