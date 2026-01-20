import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/scoring_provider.dart';
import '../providers/session_provider.dart';
import '../models/equipment.dart';
import '../models/training_session.dart';
import '../widgets/target_face_painter.dart';

class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key});

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  // List of temporary ripple effects
  final List<RippleModel> _ripples = [];

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
    ref.read(scoringProvider.notifier).startNewSession(
          equipment: const Equipment(bowType: BowType.compound, bowName: 'My Bow'),
          distance: 18.0,
          targetFaceSize: 40,
          environment: EnvironmentType.indoor,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scoringState = ref.watch(scoringProvider);

    if (!scoringState.hasActiveSession) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('实时计分', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveSession(),
          )
        ],
      ),
      body: Column(
        children: [
          // Header Stats & Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.backgroundLight,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderStat(
                        '当前组',
                        '${scoringState.currentEndNumber}',
                        '/${scoringState.maxEnds}',
                        Colors.white,
                        AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHeaderStat(
                        '总分',
                        '${scoringState.totalScore}',
                        '',
                        AppColors.primary,
                        Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildToggleBtn(
                        '列表视图',
                        Icons.grid_view,
                        !scoringState.isTargetView,
                        () => ref.read(scoringProvider.notifier).toggleView(),
                      ),
                      _buildToggleBtn(
                        '靶面视图',
                        Icons.track_changes,
                        scoringState.isTargetView,
                        () => ref.read(scoringProvider.notifier).toggleView(),
                      ),
                    ],
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
          if (!scoringState.isTargetView) _buildKeypad() else _buildTargetPanel(scoringState),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text('暂无训练', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('点击下方开始计分', style: TextStyle(color: AppColors.textSlate500)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startNewSession,
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始训练'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
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
    final displayCount = max(maxEnds, ends.length);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: displayCount + 1, // +1 for "One More End" button
      itemBuilder: (context, index) {
        if (index == displayCount) {
          // Footer Button
          if (ends.length >= maxEnds) {
             return Padding(
               padding: const EdgeInsets.only(top: 16),
               child: _oneMoreEndButton(),
             );
          }
          return const SizedBox.shrink();
        }

        final endNumber = index + 1;
        // Find existing end data if available
        final End? endData = index < ends.length ? ends[index] : null;
        
        // Determine status
        final isCurrent = index == scoringState.focusedEndIndex;
        final isPast = index < scoringState.focusedEndIndex;
        final isFuture = index > scoringState.focusedEndIndex && endData == null;

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
    // Calculate total score for this end
    final endScore = endData?.totalScore ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent 
            ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isFuture ? 0.02 : 0.05), 
            blurRadius: 8,
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '第 $endNumber 组', 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: isFuture ? AppColors.textSlate300 : AppColors.textSlate900
                )
              ),
              if (!isFuture)
                Text(
                  '得分: $endScore', 
                  style: const TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w900, 
                    color: AppColors.primary
                  )
                ),
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

              final isFocused = (endIndex == scoringState.focusedEndIndex) && (arrowIndex == scoringState.focusedArrowIndex);
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (endIndex <= (scoringState.currentSession?.ends.length ?? 0)) {
                       ref.read(scoringProvider.notifier).setFocus(endIndex, arrowIndex);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFocused ? AppColors.primary.withOpacity(0.05) : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: isFocused 
                          ? Border.all(color: AppColors.primary, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(
                      arrow != null ? '${arrow.pointValue == 11 ? 'X' : (arrow.pointValue == 0 ? 'M' : arrow.pointValue)}' : (isFuture ? '' : '${arrowIndex + 1}.'),
                      style: TextStyle(
                        fontSize: arrow != null ? 18 : 12,
                        fontWeight: arrow != null ? FontWeight.w900 : FontWeight.normal,
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
    return Container(
      height: 380, // Fixed height for target panel
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              child: GestureDetector(
                onTapDown: (details) => _handleTargetTap(details.localPosition),
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(300, 300),
                        painter: TargetFacePainter(
                          targetFaceSize: scoringState.currentSession?.targetFaceSize ?? 122,
                        ),
                      ),
                      // Show marker for current focused arrow if it has a position
                      // Or show all markers for current end?
                      // The requirement says "Target View". Usually you want to see where you hit.
                      // Let's show markers for the *currently focused end*
                      if (scoringState.focusedEndIndex < (scoringState.currentSession?.ends.length ?? 0))
                         ...scoringState.currentSession!.ends[scoringState.focusedEndIndex].arrows
                             .where((a) => a.position != null)
                             .map((arrow) {
                               final position = arrow.position!;
                               // normalized position (-1 to 1) -> scaled to 300x300
                               // center 150, radius 140 (drawable)
                               return _arrowMarker(150.0 + position.dy * 140 - 6, 150.0 + position.dx * 140 - 6);
                             }).toList(),
                             
                      ..._ripples.map((ripple) => RippleWidget(
                        key: ValueKey(ripple.id),
                        position: ripple.position,
                      )).toList(),
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
                    onPressed: () => ref.read(scoringProvider.notifier).removeLastArrow(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('移除成绩', style: TextStyle(color: AppColors.textSlate500)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('完成成绩', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _arrowMarker(double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: const Center(
          child: Text(
            '', // Could put arrow number here
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Override oneMoreEndButton to be a full width button
  Widget _oneMoreEndButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(scoringProvider.notifier).addOneMoreEnd();
        },
        icon: const Icon(Icons.add, color: AppColors.primary),
        label: const Text('再来一组', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Update keypad to be fixed bottom panel
  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Expanded(child: _keypadBtn('X', Colors.black, isText: true, onTap: () => _addScore(11))),
              const SizedBox(width: 8),
              Expanded(child: _keypadBtn('10', AppColors.textSlate900, onTap: () => _addScore(10))),
              const SizedBox(width: 8),
              Expanded(child: _keypadBtn('9', AppColors.textSlate900, onTap: () => _addScore(9))),
              const SizedBox(width: 8),
              Expanded(
                child: _iconKeypadBtn(
                  Icons.backspace_outlined,
                  '移除',
                  onTap: () => ref.read(scoringProvider.notifier).removeLastArrow(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

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
                          Expanded(child: _keypadBtn('8', AppColors.textSlate900, onTap: () => _addScore(8))),
                          const SizedBox(width: 8),
                          Expanded(child: _keypadBtn('7', AppColors.textSlate900, onTap: () => _addScore(7))),
                          const SizedBox(width: 8),
                          Expanded(child: _keypadBtn('6', AppColors.textSlate900, onTap: () => _addScore(6))),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Row 3: 5, 4, 3
                      Row(
                        children: [
                          Expanded(child: _keypadBtn('5', AppColors.textSlate900, onTap: () => _addScore(5))),
                          const SizedBox(width: 8),
                          Expanded(child: _keypadBtn('4', AppColors.textSlate900, onTap: () => _addScore(4))),
                          const SizedBox(width: 8),
                          Expanded(child: _keypadBtn('3', AppColors.textSlate900, onTap: () => _addScore(3))),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Row 4: 2, 1, M
                      Row(
                        children: [
                          Expanded(child: _keypadBtn('2', AppColors.textSlate900, onTap: () => _addScore(2))),
                          const SizedBox(width: 8),
                          Expanded(child: _keypadBtn('1', AppColors.textSlate900, onTap: () => _addScore(1))),
                          const SizedBox(width: 8),
                          Expanded(child: _keypadBtn('M', Colors.red, isText: true, onTap: () => _addScore(0))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

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

  Widget _buildTargetFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => ref.read(scoringProvider.notifier).removeLastArrow(),
              icon: const Icon(Icons.close, color: AppColors.textSlate500),
              label: const Text('删除', style: TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveSession,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('保存', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addScore(int score) async {
    final scoringState = ref.read(scoringProvider);
    if (scoringState.currentEnd == null) return;

    // Check if end is full BEFORE adding arrow (for notification logic)
    final isEndFullBefore = scoringState.currentEnd!.arrows.length >= (scoringState.arrowsPerEnd - 1);

    // Add arrow and check if session is complete
    final isComplete = await ref.read(scoringProvider.notifier).addArrow(score);

    // End Completion Notification
    if (!isComplete && isEndFullBefore) {
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
                  Text('第 ${scoringState.currentEndNumber} 组完成', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('总分: ${scoringState.totalScore}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (isComplete && mounted) {
      // Refresh session list
      await ref.read(sessionProvider.notifier).refresh();

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('训练完成！成绩已保存'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to home immediately
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      
      // Reset state after navigation
      ref.read(scoringProvider.notifier).resetSession();
    }
  }

  /// Handle tap on target face to record arrow score
  void _handleTargetTap(Offset localPosition) async {
    final scoringState = ref.read(scoringProvider);
    if (scoringState.currentEnd == null) return;

    // Add ripple effect
    _addRipple(localPosition);

    // Get target face size from session
    final targetFaceSize = scoringState.currentSession?.targetFaceSize ?? 122;

    // Target dimensions
    const double targetSize = 320.0;
    const double center = targetSize / 2; // 160
    const double drawableRadius = 140.0; // Visual radius for arrow markers

    // Calculate offset from center
    final double dx = localPosition.dx - center;
    final double dy = localPosition.dy - center;

    // Calculate distance from center as fraction of radius
    final double distance = sqrt(dx * dx + dy * dy) / center;

    // Determine score based on distance and target face size
    int score;

    if (targetFaceSize == 40) {
      // 40cm target: 6-ring face (only scores 6-10 + X)
      if (distance > 1.0) {
        score = 0; // Miss
      } else if (distance <= 0.08) {
        score = 11; // X (inner 10)
      } else if (distance <= 0.17) {
        score = 10;
      } else if (distance <= 0.33) {
        score = 9;
      } else if (distance <= 0.50) {
        score = 8;
      } else if (distance <= 0.67) {
        score = 7;
      } else {
        score = 6;
      }
    } else {
      // Full 10-ring target (60cm, 80cm, 122cm)
      if (distance > 1.0) {
        score = 0; // Miss
      } else if (distance <= 0.05) {
        score = 11; // X (inner 10)
      } else if (distance <= 0.1) {
        score = 10;
      } else if (distance <= 0.2) {
        score = 9;
      } else if (distance <= 0.3) {
        score = 8;
      } else if (distance <= 0.4) {
        score = 7;
      } else if (distance <= 0.5) {
        score = 6;
      } else if (distance <= 0.6) {
        score = 5;
      } else if (distance <= 0.7) {
        score = 4;
      } else if (distance <= 0.8) {
        score = 3;
      } else if (distance <= 0.9) {
        score = 2;
      } else {
        score = 1;
      }
    }

    // Calculate normalized position for storage (-1 to 1 range)
    final normalizedPosition = Offset(dx / drawableRadius, dy / drawableRadius);

    // Add arrow with position
    await _addScore(score); // Re-use _addScore for consistent logic
  }

  Future<void> _saveSession() async {
    await ref.read(scoringProvider.notifier).saveSession();
    await ref.read(sessionProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('训练已保存！'),
          backgroundColor: Colors.green,
        ),
      );
      // Exit after manual save
      Navigator.of(context).popUntil((route) => route.isFirst);
      ref.read(scoringProvider.notifier).resetSession();
    }
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出计分？'),
        content: const Text('当前记录将丢失。是否保存后退出？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(scoringProvider.notifier).cancelSession();
              Navigator.of(context).popUntil((route) => route.isFirst); // Return to home
            },
            child: const Text('丢弃', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _saveSession();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst); // Return to home
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _keypadBtn(String text, Color color, {bool isText = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            child: Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          ),
        ),
      ),
    );
  }

  Widget _iconKeypadBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon, color: AppColors.textSlate500), Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSlate500))],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveSession,
          borderRadius: BorderRadius.circular(12),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text('保存', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _completeEndBtn() {
    return GestureDetector(
      onTap: () => ref.read(scoringProvider.notifier).completeEnd(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 28),
            Text('NEXT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white))
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
      text: Colors.black, // Small text is usually black for readability unless bg is dark
      isSmall: true,
    );
  }

  Widget _scoreBoxSmallEmpty() => Container(width: 32, height: 32, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(6)));

  Widget _emptyScoreBox() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200, width: 2)),
    );
  }

  Widget _buildHistoryRow(String end, String total, List<int> scores) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(end, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate500)), Text(total, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textSlate400))],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: scores
                .map((s) => Container(
                      width: 40,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
                      child: Text('$s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSlate500)),
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

class _RippleWidgetState extends State<RippleWidget> with SingleTickerProviderStateMixin {
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
                  color: AppColors.primary.withOpacity(0.2),
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

class _AnimatedScoreBoxState extends State<AnimatedScoreBox> with SingleTickerProviderStateMixin {
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
          boxShadow: widget.isSmall ? null : [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)
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
