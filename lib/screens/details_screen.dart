import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../widgets/heatmap_with_center.dart';
import '../widgets/end_trend_chart.dart';
import '../widgets/score_distribution_chart.dart';
import '../widgets/ai_coach/ai_loading_widget.dart';
import '../widgets/ai_coach/ai_result_card.dart';
import '../providers/session_provider.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/scoring_provider.dart';
import '../models/training_session.dart';
import '../models/arrow.dart';
import 'scoring_screen.dart';
import '../models/equipment.dart';
import '../l10n/app_localizations.dart';
import '../widgets/ai_coach/ai_source_badge.dart';

class DetailsScreen extends ConsumerWidget {
  static const bool _showAICoachSection = false;

  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSession = ref.watch(selectedSessionProvider);
    final sessionState = ref.watch(sessionProvider);
    final l10n = AppLocalizations.of(context);

    // Use selected session or most recent session
    final session = selectedSession ?? sessionState.sessions.firstOrNull;

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.list_alt,
                  size: 64, color: AppColors.textSlate300),
              const SizedBox(height: 16),
              Text(l10n.noTrainingRecords,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate900)),
              const SizedBox(height: 8),
              Text(l10n.noSessionDetailsHint,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSlate500)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.sessionDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Clear selection when going back
            ref.read(selectedSessionProvider.notifier).state = null;
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy MMM dd')
                            .format(session.date)
                            .toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.textSlate400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(session.date),
                        style: const TextStyle(
                            color: AppColors.textSlate900,
                            fontSize: 20,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  _buildSimpleInfo(Icons.architecture,
                      _getBowTypeName(session.equipment.bowType, l10n)),
                  _buildSimpleInfo(Icons.straighten,
                      '${session.distance.toInt()}${l10n.meters}'),
                  _buildSimpleInfo(Icons.adjust,
                      '${session.targetFaceSize}${l10n.centimeters}'),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 32),

            // Big Score Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text: '${session.totalScore}',
                              style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary)),
                          TextSpan(
                              text: '/${session.maxScore}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSlate400)),
                        ],
                      ),
                    ),
                    Text(l10n.totalScore,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.textSlate400)),
                  ],
                ),
                Container(
                    height: 50,
                    width: 1,
                    color: AppColors.borderLight,
                    margin: const EdgeInsets.symmetric(horizontal: 32)),
                Column(
                  children: [
                    Text('${session.consistency.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textSlate900)),
                    Text(l10n.consistency,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.textSlate400)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Visualization Section
            _buildVisualizationSection(session, l10n),

            if (_showAICoachSection) ...[
              const SizedBox(height: 32),
              // AI Coach Analysis (优先在线，失败降级到本地)
              _buildAICoachAnalysis(session, ref, l10n),
              const SizedBox(height: 20),
            ],

            // Ends List
            if (session.ends.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.endsScoreTitle,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSlate900)),
                        StatusBadge(
                          text: l10n
                              .totalEndsLabel(session.ends.length.toString()),
                          color: AppColors.textSlate500,
                          backgroundColor: AppColors.backgroundLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...session.ends.map((end) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _endItem(
                            end.endNumber.toString().padLeft(2, '0'),
                            end.totalScore.toString(),
                            end.arrows,
                          ),
                        )),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                border: Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteSession(context, ref, session),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        label: Text(l10n.delete,
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Load session into scoring provider for editing
                          ref
                              .read(scoringProvider.notifier)
                              .loadSession(session);

                          // Navigate to scoring screen
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) => const ScoringScreen(),
                            ),
                          )
                              .then((_) {
                            // When returning, refresh the session data if needed
                            // Currently riverpod providers should handle updates if they watch the same source
                            // But selectedSessionProvider might hold an old copy if it's not auto-updated
                            // The sessionProvider list will be updated, but we might need to refresh the selected one
                            // Actually, if we edited it, the ID is same.
                            // We can re-fetch or let the provider update propagate.
                            // Since DetailsScreen watches selectedSessionProvider, we need to ensure it updates.
                            // But selectedSessionProvider is just a StateProvider<TrainingSession?>.
                            // It holds a specific instance. If that instance is immutable, it won't change.
                            // We need to find the updated session from sessionProvider and update selectedSessionProvider.

                            final updatedSessions =
                                ref.read(sessionProvider).sessions;
                            final updatedSession = updatedSessions.firstWhere(
                              (s) => s.id == session.id,
                              orElse: () => session,
                            );
                            ref.read(selectedSessionProvider.notifier).state =
                                updatedSession;
                          });
                        },
                        icon: const Icon(Icons.edit,
                            size: 18, color: Colors.white),
                        label: Text(l10n.edit,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build visualization section with three charts
  Widget _buildVisualizationSection(
      TrainingSession session, AppLocalizations l10n) {
    // WA rule: triple face = 40 cm target + non-compound bow
    final isTripleFace = session.targetFaceSize == 40 &&
        session.equipment.bowType != BowType.compound;
    final isCompoundIndoor = session.equipment.bowType == BowType.compound;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.visualization,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Heatmap with Center
          _buildChartCard(
            title: l10n.heatmapTitle,
            subtitle: l10n.heatmapSubtitle,
            child: HeatmapWithCenter(
              arrowPositions: session.heatmapPositions,
              geometricCenter: session.geometricCenter,
              targetFaceSize: session.targetFaceSize,
              isTripleFace: isTripleFace,
              isCompoundIndoor: isCompoundIndoor,
              size: 280,
            ),
          ),

          const SizedBox(height: 16),

          // 2. End-by-End Trend
          _buildChartCard(
            title: l10n.endTrendTitle,
            subtitle: l10n.endTrendSubtitle,
            child: EndTrendChart(
              endAverageScores: session.endAverageScores,
              sessionAverage: session.averageArrowScore,
              height: 220,
            ),
          ),

          const SizedBox(height: 16),

          // 3. Score Distribution
          _buildChartCard(
            title: l10n.scoreDistTitle,
            subtitle: l10n.scoreDistSubtitle,
            child: ScoreDistributionChart(
              scoreDistribution: session.scoreDistribution,
              xRingCount: session.xRingCount,
              height: 220,
            ),
          ),
        ],
      ),
    );
  }

  /// Build chart card wrapper
  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(child: child),
        ],
      ),
    );
  }

  Widget _buildSimpleInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSlate400),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSlate900)),
      ],
    );
  }

  void _deleteSession(
      BuildContext context, WidgetRef ref, TrainingSession session) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRecordTitle),
        content: Text(l10n.deleteRecordMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(sessionProvider.notifier).deleteSession(session.id);
              ref.read(selectedSessionProvider.notifier).state =
                  null; // Clear selection
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.recordDeleted)),
              );
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _endItem(String endNum, String total, List<Arrow> arrows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(endNum,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSlate400,
                    fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: arrows
                  .map((arrow) => Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: arrow.pointValue >= 9
                              ? AppColors.backgroundLight
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: arrow.pointValue >= 9
                              ? Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2))
                              : Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          arrow.displayScore,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: arrow.pointValue >= 9
                                ? AppColors.primary
                                : AppColors.textSlate500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          Text(total,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textSlate900)),
        ],
      ),
    );
  }

  /// Build AI Coach analysis section (智能降级：在线 → 本地)
  Widget _buildAICoachAnalysis(
    TrainingSession session,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final aiCoachState = ref.watch(aiCoachProvider);

    // 获取当前会话的分析结果
    final sessionResult = aiCoachState.getSessionResult(session.id);
    final isAnalyzing = aiCoachState.isAnalyzingSession(session.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiCoachAnalysis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (sessionResult != null) ...[
                          AISourceBadge(
                            source: sessionResult.source,
                            compact: true,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            l10n.aiCoachBasedOnCurrentSession,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Analyze button
              if (!isAnalyzing && sessionResult == null)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(aiCoachProvider.notifier).analyzeSession(session);
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    l10n.aiCoachAnalyzeButton,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

              // Close button
              if (sessionResult != null)
                IconButton(
                  onPressed: () {
                    ref
                        .read(aiCoachProvider.notifier)
                        .clearSessionResult(session.id);
                  },
                  icon: const Icon(Icons.close,
                      size: 20, color: AppColors.textSecondary),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Content area
          if (isAnalyzing)
            Center(child: AILoadingWidget(message: aiCoachState.loadingMessage))
          else if (aiCoachState.error != null &&
              aiCoachState.currentAnalysisType == 'session')
            _buildAnalysisError(ref, session.id, aiCoachState.error!, l10n)
          else if (sessionResult != null)
            Column(
              children: [
                AIResultCard(
                  result: sessionResult,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(aiCoachProvider.notifier).analyzeSession(session);
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(
                    l10n.aiCoachReanalyzeButton,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            )
          else
            _buildAnalysisEmpty(l10n),
        ],
      ),
    );
  }

  /// Error state for analysis
  Widget _buildAnalysisError(
    WidgetRef ref,
    String sessionId,
    String error,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 40),
          const SizedBox(height: 12),
          Text(
            l10n.aiCoachAnalysisFailed,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _localizedAiError(error, l10n),
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              ref.read(aiCoachProvider.notifier).clearError();
            },
            icon: const Icon(Icons.close, size: 16),
            label: Text(l10n.aiCoachClose),
          ),
        ],
      ),
    );
  }

  /// Empty state for analysis
  Widget _buildAnalysisEmpty(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.aiCoachClickToAnalyze}\n${l10n.aiCoachPreferOnlineFallbackToOffline}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getBowTypeName(BowType bowType, AppLocalizations l10n) {
    switch (bowType) {
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

  String _localizedAiError(String error, AppLocalizations l10n) {
    if (error == AICoachNotifier.errorNoData) {
      return l10n.keepTrainingForInsights;
    }
    return error;
  }
}
