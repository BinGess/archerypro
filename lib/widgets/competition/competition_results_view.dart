import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/competition_settings.dart';
import '../../providers/competition_provider.dart';
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
    final valid = endResults
        .map((e) => e.shootingTime.inSeconds)
        .where((s) => s > 0)
        .toList();
    if (valid.isEmpty) return 0;
    return valid.reduce((a, b) => a + b) / valid.length;
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
              child: SizedBox(
                width: double.infinity,
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
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                  letterSpacing: 1,
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
