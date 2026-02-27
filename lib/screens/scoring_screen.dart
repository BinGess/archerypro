import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/scoring_provider.dart';
import '../providers/session_provider.dart';
import '../models/equipment.dart';
import '../models/training_session.dart';
import '../models/end.dart';
import '../models/arrow.dart';
import '../widgets/target_face_painter.dart';
import '../l10n/app_localizations.dart';

class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key});

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  // List of temporary ripple effects
  final List<RippleModel> _ripples = [];

  // Magnifier state — tracks the finger position while pressing on the target
  Offset? _magnifierPosition;
  bool _showMagnifier = false;

  @override
  void initState() {
    super.initState();
    // Start a new session if none exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scoringState = ref.read(scoringProvider);
      if (!scoringState.hasActiveSession) {
        _startNewSession();
      }
    });
  }

  void _addRipple(Offset position) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _ripples.add(RippleModel(id: id, position: position));
    });

    // Auto remove after animation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _ripples.removeWhere((r) => r.id == id);
        });
      }
    });
  }

  void _startNewSession() {
    final l10n = AppLocalizations.of(context);
    ref.read(scoringProvider.notifier).startNewSession(
          equipment: Equipment(
            bowType: BowType.compound,
            bowName: l10n.myBowName(l10n.bowCompound),
          ),
          distance: 18.0,
          targetFaceSize: 40,
          environment: EnvironmentType.indoor,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scoringState = ref.watch(scoringProvider);
    final l10n = AppLocalizations.of(context);

    if (!scoringState.hasActiveSession) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.scoring),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
      ),
      body: Column(
        children: [
          // Header Stats & Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.backgroundLight,
            child: Row(
              children: [
                Expanded(
                  child: _buildHeaderStat(
                    l10n.currentEnd,
                    '${scoringState.currentEndNumber}',
                    '/${scoringState.maxEnds}',
                    Colors.white,
                    AppColors.textSlate900,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeaderStat(
                    l10n.totalScore,
                    '${scoringState.totalScore}',
                    '',
                    AppColors.primary,
                    Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable List Area
          Expanded(
            child: _buildSessionList(scoringState),
          ),

          // Fixed Bottom Panel
          if (!scoringState.isTargetView)
            _buildKeypad()
          else
            _buildTargetPanel(scoringState),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(l10n.noActiveTraining,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate900)),
            const SizedBox(height: 8),
            Text(l10n.clickStartScoring,
                style: const TextStyle(color: AppColors.textSlate500)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startNewSession,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startTraining),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(
      String label, String value, String sub, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: text.withValues(alpha: 0.6))),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: text)),
                TextSpan(
                    text: " $sub",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: text.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(dynamic scoringState) {
    final ends = scoringState.currentSession?.ends ?? [];
    final maxEnds = scoringState.maxEnds;
    final currentEndNum = scoringState.currentEndNumber;

    // We want to render a list of cards, one for each end.
    // We should render up to maxEnds (or more if they added extra).
    // The number of items = max(maxEnds, ends.length) + (has extra button ? 1 : 0)
    // Actually, we just iterate up to maxEnds, filling with placeholder if end doesn't exist.
    // If ends.length > maxEnds, we show all of them.
    final displayCount = max<int>(maxEnds, ends.length);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: displayCount + 1, // +1 for "One More End" button
      itemBuilder: (context, index) {
        if (index == displayCount) {
          // Footer Button - Always show "One More End"
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _oneMoreEndButton(),
          );
        }

        final endNumber = index + 1;
        // Find existing end data if available
        final End? endData = index < ends.length ? ends[index] : null;

        // Determine status
        final isCurrent = index == scoringState.focusedEndIndex;
        final isPast = index < scoringState.focusedEndIndex;
        final isFuture =
            index > scoringState.focusedEndIndex && endData == null;

        return _buildEndCard(
          endNumber: endNumber,
          endData: endData,
          isCurrent: isCurrent,
          isPast: isPast,
          isFuture: isFuture,
          scoringState: scoringState,
          endIndex: index,
        );
      },
    );
  }

  Widget _buildEndCard({
    required int endNumber,
    required End? endData,
    required bool isCurrent,
    required bool isPast,
    required bool isFuture,
    required dynamic scoringState,
    required int endIndex,
  }) {
    final l10n = AppLocalizations.of(context);
    // Calculate total score for this end
    final endScore = endData?.totalScore ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isFuture ? 0.02 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.endLabel(endNumber.toString()),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isFuture
                          ? AppColors.textSlate300
                          : AppColors.textSlate900)),
              if (!isFuture)
                Text(l10n.scoreLabel(endScore.toString()),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(scoringState.arrowsPerEnd, (arrowIndex) {
              // Get arrow data if available
              Arrow? arrow;
              if (endData != null && arrowIndex < endData.arrows.length) {
                arrow = endData.arrows[arrowIndex];
              }

              final isFocused = (endIndex == scoringState.focusedEndIndex) &&
                  (arrowIndex == scoringState.focusedArrowIndex);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (endIndex <=
                        (scoringState.currentSession?.ends.length ?? 0)) {
                      ref
                          .read(scoringProvider.notifier)
                          .setFocus(endIndex, arrowIndex);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFocused
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: isFocused
                          ? Border.all(color: AppColors.primary, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(
                      arrow != null
                          ? arrow.displayScore
                          : (isFuture ? '' : '${arrowIndex + 1}.'),
                      style: TextStyle(
                        fontSize: arrow != null ? 18 : 12,
                        fontWeight:
                            arrow != null ? FontWeight.w900 : FontWeight.normal,
                        color: arrow != null
                            ? AppColors.textSlate900
                            : AppColors.textSlate300,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPanel(dynamic scoringState) {
    final l10n = AppLocalizations.of(context);
    final targetFaceSize = scoringState.currentSession?.targetFaceSize ?? 122;
    final bowType = scoringState.currentSession?.equipment.bowType;

    // WA rule: triple face = 40cm target + non-compound bow (recurve/barebow/longbow)
    // Compound ALWAYS uses full single face, regardless of target size
    final isTripleFace =
        targetFaceSize == 40 && bowType != BowType.compound;

    // Compound bow always uses inner-10 scoring (X ring only scores 10)
    final isCompoundIndoor = bowType == BowType.compound;

    // For triple face, arrow positions (full-target coords -1 to 1) need 2x scale
    // to map back to the 2x-zoomed display.
    // Full face: center + pos * 140    (140 keeps markers within bounds)
    // Triple face: center + pos * 280  (280 = 140 * 2.0)
    const double baseMarkerRadius = 140.0;
    final double markerDisplayRadius =
        isTripleFace ? baseMarkerRadius * 2.0 : baseMarkerRadius;

    return Container(
      height: 380, // Fixed height for target panel
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Target Face
          Expanded(
            child: Center(
              child: Listener(
                onPointerDown: (event) {
                  setState(() {
                    _magnifierPosition = event.localPosition;
                    _showMagnifier = true;
                  });
                },
                onPointerMove: (event) {
                  setState(() {
                    _magnifierPosition = event.localPosition;
                  });
                },
                onPointerUp: (event) {
                  if (_magnifierPosition != null) {
                    _handleTargetTap(_magnifierPosition!);
                  }
                  setState(() {
                    _showMagnifier = false;
                    _magnifierPosition = null;
                  });
                },
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Target face
                      CustomPaint(
                        size: const Size(300, 300),
                        painter: TargetFacePainter(
                          isTripleFace: isTripleFace,
                          isCompoundIndoor: isCompoundIndoor,
                        ),
                      ),

                      // Arrow markers for the currently focused end
                      if (scoringState.focusedEndIndex <
                          (scoringState.currentSession?.ends.length ?? 0))
                        ...scoringState.currentSession!
                            .ends[scoringState.focusedEndIndex].arrows
                            .where((a) => a.position != null)
                            .map((arrow) {
                          final pos = arrow.position!;
                          // pos is stored in full-target normalized coords
                          // map to display: center(150) + pos * markerDisplayRadius
                          final double left =
                              150.0 + pos.dx * markerDisplayRadius - 6;
                          final double top =
                              150.0 + pos.dy * markerDisplayRadius - 6;
                          return _arrowMarker(top, left, arrow.displayScore);
                        }).toList(),

                      // Ripple effects
                      ..._ripples
                          .map((ripple) => RippleWidget(
                                key: ValueKey(ripple.id),
                                position: ripple.position,
                              ))
                          .toList(),

                      // Magnifier lens shown while pressing
                      if (_showMagnifier && _magnifierPosition != null)
                        _buildMagnifier(
                          _magnifierPosition!,
                          isTripleFace: isTripleFace,
                          isCompoundIndoor: isCompoundIndoor,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Footer Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(scoringProvider.notifier).removeLastArrow(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.removeScore,
                        style: const TextStyle(color: AppColors.textSlate500)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(l10n.completeSession,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrowMarker(double top, double left, String scoreText) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Center(
          child: Text(
            scoreText,
            style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  /// Magnifier lens — shows a 2× zoomed view of the target centered on
  /// [fingerPos], positioned 60 px above the finger.
  Widget _buildMagnifier(
    Offset fingerPos, {
    required bool isTripleFace,
    required bool isCompoundIndoor,
  }) {
    const double magnifierSize = 120.0;
    const double halfSize = magnifierSize / 2;
    const double scale = 2.0;

    // Translate so that fingerPos on the 300×300 target appears at (60,60)
    // in the magnifier (the clipped circle center).
    final double tx = halfSize - scale * fingerPos.dx;
    final double ty = halfSize - scale * fingerPos.dy;

    // Keep magnifier inside the 300×300 Stack vertically
    final double topOffset = (fingerPos.dy - magnifierSize - 50)
        .clamp(0.0, 300.0 - magnifierSize);
    final double leftOffset =
        (fingerPos.dx - halfSize).clamp(0.0, 300.0 - magnifierSize);

    return Positioned(
      left: leftOffset,
      top: topOffset,
      child: IgnorePointer(
        child: Container(
          width: magnifierSize,
          height: magnifierSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 10,
                  spreadRadius: 1)
            ],
          ),
          child: ClipOval(
            child: Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.identity()
                ..translate(tx, ty)
                ..scale(scale),
              child: OverflowBox(
                minWidth: 300.0,
                maxWidth: 300.0,
                minHeight: 300.0,
                maxHeight: 300.0,
                child: CustomPaint(
                  painter: TargetFacePainter(
                    isTripleFace: isTripleFace,
                    isCompoundIndoor: isCompoundIndoor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Override oneMoreEndButton to be a full width button
  Widget _oneMoreEndButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(scoringProvider.notifier).addOneMoreEnd();
        },
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: Text(l10n.oneMoreEnd,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Update keypad to be fixed bottom panel
  Widget _buildKeypad() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: X, 10, 9, Delete
          Row(
            children: [
              Expanded(
                  child: _keypadBtn('X', Colors.black,
                      isText: true, onTap: () => _addScore(11))),
              const SizedBox(width: 6),
              Expanded(
                  child: _keypadBtn('10', AppColors.textSlate900,
                      onTap: () => _addScore(10))),
              const SizedBox(width: 6),
              Expanded(
                  child: _keypadBtn('9', AppColors.textSlate900,
                      onTap: () => _addScore(9))),
              const SizedBox(width: 6),
              Expanded(
                child: _iconKeypadBtn(
                  Icons.backspace_outlined,
                  l10n.removeShort,
                  onTap: () =>
                      ref.read(scoringProvider.notifier).removeLastArrow(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2-4: 8-1, M, and Save button on the right
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left side: Number grid
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Row 2: 8, 7, 6
                      Row(
                        children: [
                          Expanded(
                              child: _keypadBtn('8', AppColors.textSlate900,
                                  onTap: () => _addScore(8))),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _keypadBtn('7', AppColors.textSlate900,
                                  onTap: () => _addScore(7))),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _keypadBtn('6', AppColors.textSlate900,
                                  onTap: () => _addScore(6))),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Row 3: 5, 4, 3
                      Row(
                        children: [
                          Expanded(
                              child: _keypadBtn('5', AppColors.textSlate900,
                                  onTap: () => _addScore(5))),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _keypadBtn('4', AppColors.textSlate900,
                                  onTap: () => _addScore(4))),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _keypadBtn('3', AppColors.textSlate900,
                                  onTap: () => _addScore(3))),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Row 4: 2, 1, M
                      Row(
                        children: [
                          Expanded(
                              child: _keypadBtn('2', AppColors.textSlate900,
                                  onTap: () => _addScore(2))),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _keypadBtn('1', AppColors.textSlate900,
                                  onTap: () => _addScore(1))),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _keypadBtn('M', Colors.red,
                                  isText: true, onTap: () => _addScore(0))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Right side: Save button (spans 3 rows)
                Expanded(
                  child: _buildSaveButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addScore(int score) async {
    final l10n = AppLocalizations.of(context);
    final scoringState = ref.read(scoringProvider);
    if (scoringState.currentEnd == null) return;

    // Prevent auto-creating new ends via keypad if we reached maxEnds
    // Only allow input if we are editing an existing valid end or if focused index is within bounds
    // focusedEndIndex is 0-based. maxEnds is count.
    // If focusedEndIndex == maxEnds, it means we are trying to add to a new end beyond the limit.
    if (scoringState.focusedEndIndex >= scoringState.maxEnds) {
      // Allow if we are editing a past end? No, focusedEndIndex tracks cursor.
      // If cursor is past the end, block input.
      return;
    }

    // Check if we are about to fill the last arrow of the current end
    // This logic relies on the current focus state BEFORE adding the arrow
    final isLastArrowOfEnd =
        scoringState.focusedArrowIndex == (scoringState.arrowsPerEnd - 1);
    final currentEndNumForPopup = scoringState.focusedEndIndex + 1;

    // Add arrow and check if session is complete
    final isComplete = await ref.read(scoringProvider.notifier).addArrow(score);

    // End Completion Notification
    // Show only if we just completed an end (isLastArrowOfEnd was true) AND session is not complete yet
    // Note: addArrow returns true only if the ENTIRE SESSION is complete (all ends done)
    if (!isComplete && isLastArrowOfEnd) {
      // Re-read state to get the updated total score
      final updatedState = ref.read(scoringProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.endCompletedLabel(currentEndNumForPopup.toString()),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(l10n.totalScoreLabel(updatedState.totalScore.toString()),
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1), // Shortened duration
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (isComplete && mounted) {
      // Refresh session list
      await ref.read(sessionProvider.notifier).refresh();

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sessionCompleted),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to home immediately
      if (mounted) {
        final isEditing = ref.read(scoringProvider).isEditing;
        if (isEditing) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }

      // Reset state after navigation
      ref.read(scoringProvider.notifier).resetSession();
    }
  }

  /// Calculate score from normalized full-target radius [r] (0.0–1.0).
  ///
  /// Uses WA ring boundaries with a 0.01R line tolerance (rounds UP to
  /// higher score at boundaries).
  ///
  /// [r]              Distance from center in full-target coordinates.
  ///                  r=1.0 = outer edge of ring 1.
  /// [isTripleFace]   When true, r > 0.50 (outside ring 6) = Miss.
  /// [isCompoundIndoor] When true, the 10-ring zone (0.05–0.10) scores 9,
  ///                  not 10. Only X ring (r ≤ 0.05) scores 10 points.
  int _calcScore(double r, bool isTripleFace, bool isCompoundIndoor) {
    const double tol = 0.01; // line tolerance in full-target coords

    // Miss check
    final double maxR = isTripleFace ? 0.50 : 1.00;
    if (r > maxR + tol) return 0; // Miss

    // X ring (r ≤ 0.05 + tolerance)
    if (r <= 0.05 + tol) return 11; // stored as 11, displayed as 'X'

    // 10-ring zone (0.05–0.10)
    if (r <= 0.10 + tol) {
      // Compound indoor: 10-ring scores as 9 (only X ring counts as 10)
      return isCompoundIndoor ? 9 : 10;
    }

    // Remaining rings use the same boundaries for all face types
    if (r <= 0.20 + tol) return 9;
    if (r <= 0.30 + tol) return 8;
    if (r <= 0.40 + tol) return 7;
    if (r <= 0.50 + tol) return 6;
    if (r <= 0.60 + tol) return 5;
    if (r <= 0.70 + tol) return 4;
    if (r <= 0.80 + tol) return 3;
    if (r <= 0.90 + tol) return 2;
    if (r <= 1.00 + tol) return 1;
    return 0; // Miss
  }

  /// Handle tap / release on target face to record an arrow score.
  void _handleTargetTap(Offset localPosition) async {
    final scoringState = ref.read(scoringProvider);
    if (scoringState.currentEnd == null) return;
    if (scoringState.focusedEndIndex >= scoringState.maxEnds) return;

    // Add ripple effect at tap position
    _addRipple(localPosition);

    // Session parameters
    final targetFaceSize = scoringState.currentSession?.targetFaceSize ?? 122;
    final bowType = scoringState.currentSession?.equipment.bowType;

    // WA rule: triple face = 40 cm + non-compound
    final bool isTripleFace =
        targetFaceSize == 40 && bowType != BowType.compound;
    // Compound bow always uses inner-10 scoring
    final bool isCompoundIndoor = bowType == BowType.compound;

    // Target widget is always 300×300 px; center at (150, 150)
    const double targetRadius = 150.0;
    const double targetCenter = targetRadius; // 150

    // Pixel offset from center
    final double dx = localPosition.dx - targetCenter;
    final double dy = localPosition.dy - targetCenter;

    // Display-normalised distance (0.0 = center, 1.0 = display edge)
    final double rDisplay = sqrt(dx * dx + dy * dy) / targetRadius;

    // Convert to full-target coordinates.
    // Triple face display represents the inner 50% of the full target,
    // so rDisplay = 1.0 on the triple face equals r = 0.5 on the full target.
    final double rFull = isTripleFace ? rDisplay * 0.5 : rDisplay;

    // Score using full-target coordinates
    final int score = _calcScore(rFull, isTripleFace, isCompoundIndoor);

    // Store position in FULL-TARGET normalized coordinates (-1 to 1).
    // Triple face: dx / 150 gives display-norm; multiply by 0.5 → full-target norm.
    // Full face: dx / 150 directly gives full-target norm.
    final Offset normalizedPosition = isTripleFace
        ? Offset(dx / targetRadius * 0.5, dy / targetRadius * 0.5)
        : Offset(dx / targetRadius, dy / targetRadius);

    // Record the arrow
    await ref
        .read(scoringProvider.notifier)
        .addArrow(score, position: normalizedPosition);
  }

  Future<void> _saveSession() async {
    final l10n = AppLocalizations.of(context);
    final isEditing = ref.read(scoringProvider).isEditing;
    await ref.read(scoringProvider.notifier).saveSession();
    await ref.read(sessionProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sessionSaved),
          backgroundColor: Colors.green,
        ),
      );
      // Exit after manual save
      if (isEditing) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      ref.read(scoringProvider.notifier).resetSession();
    }
  }

  void _confirmExit(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = ref.read(scoringProvider).isEditing;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.scoringExitTitle),
        content: Text(l10n.scoringExitMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(scoringProvider.notifier).cancelSession();
              if (isEditing) {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context)
                    .popUntil((route) => route.isFirst); // Return to home
              }
            },
            child:
                Text(l10n.discard, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _saveSession();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _keypadBtn(String text, Color color,
      {bool isText = false, VoidCallback? onTap}) {
    return Container(
      height: 54, // Fixed height, slightly taller
      margin: const EdgeInsets.all(
          0), // Margin handled by parent layout for tighter control
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            child: Text(text,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          ),
        ),
      ),
    );
  }

  Widget _iconKeypadBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return Container(
      height: 54,
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textSlate500, size: 24),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSlate500))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: _saveSession,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(l10n.save,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 9) return AppColors.targetGold;
    if (score >= 7) return AppColors.targetRed;
    if (score >= 5) return AppColors.targetBlue;
    if (score >= 3) return AppColors.targetBlack;
    if (score >= 1) return AppColors.targetWhite;
    return Colors.grey;
  }

  Color _getScoreTextColor(int score) {
    if (score >= 9 || score >= 7 || score >= 3) return Colors.black;
    return Colors.white;
  }

  Widget _scoreBox(int score, Color bg, Color text) {
    return AnimatedScoreBox(
      score: score,
      bg: bg,
      text: text,
      isSmall: false,
    );
  }

  Widget _scoreBoxSmall(int score, Color bg) {
    return AnimatedScoreBox(
      score: score,
      bg: bg,
      text: Colors
          .black, // Small text is usually black for readability unless bg is dark
      isSmall: true,
    );
  }

  Widget _scoreBoxSmallEmpty() => Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.borderLight, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(6)));

  Widget _emptyScoreBox() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight, width: 2)),
    );
  }

  Widget _buildHistoryRow(String end, String total, List<int> scores) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(end,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSlate500)),
              Text(total,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSlate400))
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: scores
                .map((s) => Container(
                      width: 40,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('$s',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSlate500)),
                    ))
                .toList(),
          )
        ],
      ),
    );
  }
}

class RippleModel {
  final String id;
  final Offset position;
  RippleModel({required this.id, required this.position});
}

class RippleWidget extends StatefulWidget {
  final Offset position;
  final VoidCallback? onComplete;

  const RippleWidget({super.key, required this.position, this.onComplete});

  @override
  State<RippleWidget> createState() => _RippleWidgetState();
}

class _RippleWidgetState extends State<RippleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.position.dy - 40,
      left: widget.position.dx - 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedScoreBox extends StatefulWidget {
  final int score;
  final Color bg;
  final Color text;
  final bool isSmall;

  const AnimatedScoreBox({
    super.key,
    required this.score,
    required this.bg,
    required this.text,
    this.isSmall = false,
  });

  @override
  State<AnimatedScoreBox> createState() => _AnimatedScoreBoxState();
}

class _AnimatedScoreBoxState extends State<AnimatedScoreBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.isSmall ? 32 : 48,
        height: widget.isSmall ? 32 : 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.bg,
          borderRadius: BorderRadius.circular(widget.isSmall ? 6 : 8),
          boxShadow: widget.isSmall
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)
                ],
        ),
        child: Text(
          '${widget.score}',
          style: TextStyle(
            fontSize: widget.isSmall ? 14 : 18,
            fontWeight: widget.isSmall ? FontWeight.bold : FontWeight.w900,
            color: widget.text,
          ),
        ),
      ),
    );
  }
}
