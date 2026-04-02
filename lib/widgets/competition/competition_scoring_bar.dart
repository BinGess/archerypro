import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class CompetitionScoringBar extends StatelessWidget {
  final int currentEnd;
  final int totalEnds;
  final List<int> arrowScores;
  final int arrowsPerEnd;
  final int totalScore;

  const CompetitionScoringBar({
    super.key,
    required this.currentEnd,
    required this.totalEnds,
    required this.arrowScores,
    required this.arrowsPerEnd,
    required this.totalScore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.endNumber} $currentEnd / $totalEnds',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSlate500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.totalScoreLabel(totalScore.toString()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSlate900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: List.generate(arrowsPerEnd, (i) {
                final hasScore = i < arrowScores.length;
                return Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasScore
                        ? _scoreColor(arrowScores[i])
                        : AppColors.surfaceSubtle,
                    border: hasScore
                        ? null
                        : Border.all(color: AppColors.surfaceMid, width: 1.5),
                  ),
                  child: hasScore
                      ? Text(
                          arrowScores[i] == kXRingScore
                              ? 'X'
                              : '${arrowScores[i]}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: arrowScores[i] >= 9
                                ? Colors.black
                                : Colors.white,
                          ),
                        )
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 9) return AppColors.targetGold;
    if (score >= 7) return AppColors.targetRed;
    if (score >= 5) return AppColors.targetBlue;
    if (score >= 3) return AppColors.targetBlack;
    return AppColors.textSlate400;
  }
}
