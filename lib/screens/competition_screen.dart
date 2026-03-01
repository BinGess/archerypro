import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/competition_settings.dart';
import '../providers/competition_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/competition/competition_results_view.dart';
import '../widgets/competition/competition_scoring_bar.dart';
import '../widgets/competition/competition_timer_display.dart';
import '../widgets/competition/pause_overlay.dart';
import '../widgets/target_face_painter.dart';

enum _CompetitionInputMode { keyboard, target }

class CompetitionScreen extends ConsumerStatefulWidget {
  final CompetitionSettings settings;
  const CompetitionScreen({super.key, required this.settings});

  @override
  ConsumerState<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends ConsumerState<CompetitionScreen> {
  late _CompetitionInputMode _inputMode;
  final List<_TargetMark> _targetMarks = [];

  @override
  void initState() {
    super.initState();
    _inputMode = widget.settings.useTargetScoring
        ? _CompetitionInputMode.target
        : _CompetitionInputMode.keyboard;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitionState = ref.watch(competitionProvider(widget.settings));
    final notifier = ref.read(competitionProvider(widget.settings).notifier);

    return PopScope(
      canPop: !competitionState.isTimerActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && competitionState.isTimerActive) {
          _showExitConfirmation(context);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildPhaseContent(competitionState, notifier),
            if (competitionState.isPaused)
              PauseOverlay(
                remainingSeconds: competitionState.remainingSeconds,
                onResume: notifier.resume,
                onReset: () {
                  _clearTargetMarks();
                  notifier.resetCurrentEnd();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseContent(
    CompetitionState state,
    CompetitionNotifier notifier,
  ) {
    switch (state.phase) {
      case CompetitionPhase.wait:
      case CompetitionPhase.preparation:
      case CompetitionPhase.shooting:
      case CompetitionPhase.warning:
      case CompetitionPhase.timesUp:
        return CompetitionTimerDisplay(
          phase: state.phase,
          currentEnd: state.currentEnd,
          totalEnds: state.settings.totalEnds,
          remainingSeconds: state.remainingSeconds,
          totalShootingTime: state.totalShootingTime,
          onStart: notifier.startEnd,
          onSkip: notifier.skipToScoring,
          onPause: notifier.pause,
        );

      case CompetitionPhase.scoring:
        return _buildScoringView(state, notifier);

      case CompetitionPhase.finished:
        return CompetitionResultsView(
          endResults: state.endResults,
          settings: state.settings,
          onDone: () => Navigator.of(context).pop(),
        );
    }
  }

  Widget _buildScoringView(
    CompetitionState state,
    CompetitionNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context);
    final isTargetMode = _inputMode == _CompetitionInputMode.target;

    if (state.currentArrowScores.isEmpty && _targetMarks.isNotEmpty) {
      _targetMarks.clear();
    }
    if (_targetMarks.length > state.currentArrowScores.length) {
      _targetMarks.removeRange(
          state.currentArrowScores.length, _targetMarks.length);
    }

    return Container(
      color: AppColors.backgroundLight,
      child: Column(
        children: [
          CompetitionScoringBar(
            currentEnd: state.currentEnd,
            totalEnds: state.settings.totalEnds,
            arrowScores: state.currentArrowScores,
            arrowsPerEnd: state.settings.arrowsPerEnd,
            totalScore: state.totalScore,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.endNumber} ${state.currentEnd}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        l10n.scoreLabel(
                          _effectiveEndScore(state.currentArrowScores)
                              .toString(),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(state.settings.arrowsPerEnd, (i) {
                      if (i < state.currentArrowScores.length) {
                        return _scoreBox(state.currentArrowScores[i]);
                      }
                      return _emptyScoreBox();
                    }),
                  ),
                ],
              ),
            ),
          ),
          _buildInputModeSwitch(l10n),
          if (isTargetMode)
            Expanded(child: _buildTargetInput(state, notifier))
          else
            const Spacer(),
          if (isTargetMode)
            _buildTargetModeBottomBar(state, notifier)
          else
            _buildKeypad(state, notifier),
        ],
      ),
    );
  }

  Widget _buildInputModeSwitch(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SegmentedButton<_CompetitionInputMode>(
        segments: [
          ButtonSegment(
            value: _CompetitionInputMode.keyboard,
            label: Text(l10n.competitionKeyboardEntry),
            icon: const Icon(Icons.dialpad_rounded, size: 16),
          ),
          ButtonSegment(
            value: _CompetitionInputMode.target,
            label: Text(l10n.competitionTargetEntry),
            icon: const Icon(Icons.gps_fixed_rounded, size: 16),
          ),
        ],
        selected: {_inputMode},
        onSelectionChanged: (v) {
          setState(() => _inputMode = v.first);
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
          selectedForegroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTargetInput(
      CompetitionState state, CompetitionNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final targetSize = shortestSide.clamp(260.0, 420.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Text(
            l10n.competitionTapTargetHint,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: SizedBox(
                width: targetSize,
                height: targetSize,
                child: GestureDetector(
                  onTapUp: (details) => _handleTargetTap(
                      details.localPosition, targetSize, state, notifier),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(
                          painter: TargetFacePainter(isTripleFace: false),
                        ),
                      ),
                      ..._targetMarks.map((mark) {
                        final radius = targetSize / 2;
                        final left =
                            radius + (mark.normalizedPosition.dx * radius) - 9;
                        final top =
                            radius + (mark.normalizedPosition.dy * radius) - 9;
                        return Positioned(
                          left: left,
                          top: top,
                          child: _targetMarkWidget(mark.score),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetMarkWidget(int score) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        score == 0 ? 'M' : (score == kXRingScore ? 'X' : '$score'),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTargetModeBottomBar(
      CompetitionState state, CompetitionNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    final canSubmit = state.canSubmitScores;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  notifier.removeLastArrowScore();
                  if (_targetMarks.isNotEmpty) {
                    setState(() => _targetMarks.removeLast());
                  }
                },
                icon: const Icon(Icons.backspace_outlined),
                label: Text(l10n.removeShort),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSlate500,
                  side: const BorderSide(color: AppColors.surfaceMid),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    canSubmit ? () => _handleSubmit(state, notifier) : null,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(l10n.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.surfaceMid,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTargetTap(
    Offset localPosition,
    double targetSize,
    CompetitionState state,
    CompetitionNotifier notifier,
  ) {
    if (state.currentArrowScores.length >= state.settings.arrowsPerEnd) {
      return;
    }

    final radius = targetSize / 2;
    final dx = localPosition.dx - radius;
    final dy = localPosition.dy - radius;
    final normalized =
        Offset((dx / radius).clamp(-1, 1), (dy / radius).clamp(-1, 1));
    final r = math.sqrt(dx * dx + dy * dy) / radius;
    final score = _calcTargetScore(r);

    notifier.addArrowScore(score);
    setState(() {
      _targetMarks
          .add(_TargetMark(normalizedPosition: normalized, score: score));
    });
  }

  int _calcTargetScore(double r) {
    if (r > 1.0) return 0;
    if (r <= kTargetXRingBoundary) return kXRingScore;
    if (r <= kTargetTenRingBoundary) return 10;
    if (r <= 0.20) return 9;
    if (r <= 0.30) return 8;
    if (r <= 0.40) return 7;
    if (r <= 0.50) return 6;
    if (r <= 0.60) return 5;
    if (r <= 0.70) return 4;
    if (r <= 0.80) return 3;
    if (r <= 0.90) return 2;
    if (r <= 1.00) return 1;
    return 0;
  }

  Widget _buildKeypad(CompetitionState state, CompetitionNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.3,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _keypadBtn(
                'X', Colors.orange, () => notifier.addArrowScore(kXRingScore)),
            _keypadBtn(
                '10', AppColors.textSlate900, () => notifier.addArrowScore(10)),
            _keypadBtn(
                '9', AppColors.textSlate900, () => notifier.addArrowScore(9)),
            _iconKeypadBtn(
              Icons.backspace,
              AppLocalizations.of(context).removeShort,
              () {
                notifier.removeLastArrowScore();
                if (_targetMarks.isNotEmpty) {
                  setState(() => _targetMarks.removeLast());
                }
              },
            ),
            _keypadBtn(
                '8', AppColors.textSlate900, () => notifier.addArrowScore(8)),
            _keypadBtn(
                '7', AppColors.textSlate900, () => notifier.addArrowScore(7)),
            _keypadBtn(
                '6', AppColors.textSlate900, () => notifier.addArrowScore(6)),
            _keypadBtn(
                '5', AppColors.textSlate900, () => notifier.addArrowScore(5)),
            _keypadBtn(
                '4', AppColors.textSlate900, () => notifier.addArrowScore(4)),
            _keypadBtn(
                '3', AppColors.textSlate900, () => notifier.addArrowScore(3)),
            _saveBtn(state, notifier),
            _keypadBtn(
                '2', AppColors.textSlate900, () => notifier.addArrowScore(2)),
            _keypadBtn(
                '1', AppColors.textSlate900, () => notifier.addArrowScore(1)),
            _keypadBtn('M', Colors.red, () => notifier.addArrowScore(0)),
          ],
        ),
      ),
    );
  }

  void _handleSubmit(CompetitionState state, CompetitionNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    if (!state.canSubmitScores) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.competitionIncompleteEnd),
          content: Text(
            l10n.competitionIncompleteMessage(
              state.currentArrowScores.length,
              state.settings.arrowsPerEnd,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _clearTargetMarks();
                notifier.submitScores(force: true);
              },
              child: Text(l10n.competitionSubmit),
            ),
          ],
        ),
      );
    } else {
      _clearTargetMarks();
      notifier.submitScores();
    }
  }

  void _clearTargetMarks() {
    if (_targetMarks.isEmpty) return;
    setState(() => _targetMarks.clear());
  }

  void _showExitConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.competitionLeaveTitle),
        content: Text(l10n.competitionLeaveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.competitionStay),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.timerRed),
            child: Text(l10n.competitionLeave),
          ),
        ],
      ),
    );
  }

  Widget _keypadBtn(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceMid),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _iconKeypadBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceMid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSlate500),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.textSlate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveBtn(CompetitionState state, CompetitionNotifier notifier) {
    final canSubmit = state.canSubmitScores;
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _handleSubmit(state, notifier),
      child: Container(
        decoration: BoxDecoration(
          color: canSubmit ? Colors.green : AppColors.surfaceMid,
          borderRadius: BorderRadius.circular(12),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: canSubmit ? Colors.white : AppColors.textSlate400,
              size: 28,
            ),
            Text(
              l10n.save.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: canSubmit ? Colors.white : AppColors.textSlate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(int score) {
    final Color bg;
    final Color textColor;
    if (score >= 9) {
      bg = AppColors.targetGold;
      textColor = Colors.black;
    } else if (score >= 7) {
      bg = AppColors.targetRed;
      textColor = Colors.white;
    } else if (score >= 5) {
      bg = AppColors.targetBlue;
      textColor = Colors.white;
    } else if (score >= 3) {
      bg = AppColors.targetBlack;
      textColor = Colors.white;
    } else {
      bg = AppColors.textSlate400;
      textColor = Colors.white;
    }
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Text(
        score == 0 ? 'M' : (score == kXRingScore ? 'X' : '$score'),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }

  Widget _emptyScoreBox() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceMid, width: 2),
      ),
    );
  }

  int _effectiveEndScore(List<int> scores) {
    return scores.fold(0, (sum, score) {
      if (score == kXRingScore) return sum + 10;
      return sum + score;
    });
  }
}

class _TargetMark {
  final Offset normalizedPosition;
  final int score;

  const _TargetMark({
    required this.normalizedPosition,
    required this.score,
  });
}
