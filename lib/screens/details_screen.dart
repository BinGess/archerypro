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
import '../models/training_session.dart';
import '../models/equipment.dart';
import '../services/session_analysis_service.dart';

class DetailsScreen extends ConsumerWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSession = ref.watch(selectedSessionProvider);
    final sessionState = ref.watch(sessionProvider);

    // Use selected session or most recent session
    final session = selectedSession ?? sessionState.sessions.firstOrNull;

    if (session == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.list_alt, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('暂无训练记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('完成一次训练后可在此查看详情', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('训练详情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        DateFormat('yyyy MMM dd').format(session.date).toUpperCase(),
                        style: const TextStyle(color: AppColors.textSlate400, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(session.date),
                        style: const TextStyle(color: AppColors.textSlate900, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  _buildSimpleInfo(Icons.architecture, session.equipment.bowTypeDisplay),
                  _buildSimpleInfo(Icons.straighten, '${session.distance.toInt()}m'),
                  _buildSimpleInfo(Icons.adjust, '${session.targetFaceSize}cm'),
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
                          TextSpan(text: '${session.totalScore}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          TextSpan(text: '/${session.maxScore}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
                        ],
                      ),
                    ),
                    const Text('总分', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textSlate400)),
                  ],
                ),
                Container(height: 50, width: 1, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 32)),
                Column(
                  children: [
                    Text('${session.consistency.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textSlate900)),
                    const Text('稳定性', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textSlate400)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Visualization Section
            _buildVisualizationSection(session),

            const SizedBox(height: 32),

            // AI Coach Analysis (优先在线，失败降级到本地)
            _buildAICoachAnalysis(session, ref),

            const SizedBox(height: 20),

            // Ends List
            if (session.ends.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('各组成绩', style: TextStyle(fontWeight: FontWeight.bold)),
                        StatusBadge(
                          text: '共 ${session.ends.length} 组',
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
                            List<int>.from(end.arrows.map((a) => a.pointValue)),
                          ),
                        )),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
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
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: const Text('删除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement Edit
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('编辑功能开发中')),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        label: const Text('编辑', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  Widget _buildVisualizationSection(TrainingSession session) {
    final useSixRingFace = session.targetFaceSize == 40 && session.equipment.bowType == BowType.compound;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '数据可视化',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Heatmap with Center
          _buildChartCard(
            title: '本次落点热力图',
            subtitle: '所有箭支位置分布 + 几何中心',
            child: HeatmapWithCenter(
              arrowPositions: session.heatmapPositions,
              geometricCenter: session.geometricCenter,
              targetFaceSize: session.targetFaceSize,
              useSixRingFace: useSixRingFace,
              size: 280,
            ),
          ),

          const SizedBox(height: 16),

          // 2. End-by-End Trend
          _buildChartCard(
            title: '组间走势图',
            subtitle: '各组平均分趋势',
            child: EndTrendChart(
              endAverageScores: session.endAverageScores,
              sessionAverage: session.averageArrowScore,
              height: 220,
            ),
          ),

          const SizedBox(height: 16),

          // 3. Score Distribution
          _buildChartCard(
            title: '分数分布',
            subtitle: '各环数箭支统计',
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
            color: Colors.black.withOpacity(0.02),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate900)),
      ],
    );
  }

  void _deleteSession(BuildContext context, WidgetRef ref, TrainingSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条训练记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(sessionProvider.notifier).deleteSession(session.id);
              ref.read(selectedSessionProvider.notifier).state = null; // Clear selection
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('记录已删除')),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _endItem(String endNum, String total, List<int> scores) {
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
            child: Text(endNum, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSlate400, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scores
                  .map((s) => Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: s >= 9 ? AppColors.backgroundLight : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: s >= 9 ? Border.all(color: AppColors.primary.withOpacity(0.2)) : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          '$s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: s >= 9 ? AppColors.primary : AppColors.textSlate500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          Text(total, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textSlate900)),
        ],
      ),
    );
  }

  /// Build AI Coach analysis section (智能降级：在线 → 本地)
  Widget _buildAICoachAnalysis(TrainingSession session, WidgetRef ref) {
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
            color: Colors.black.withOpacity(0.04),
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
                  color: AppColors.primary.withOpacity(0.1),
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
                    const Text(
                      'AI 教练分析',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // 显示来源标识
                        if (sessionResult != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sessionResult.source == 'coze'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  sessionResult.source == 'coze'
                                      ? Icons.cloud_done
                                      : Icons.phone_android,
                                  size: 10,
                                  color: sessionResult.source == 'coze'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sessionResult.source == 'coze' ? '在线分析' : '本地分析',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: sessionResult.source == 'coze'
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Expanded(
                          child: Text(
                            '基于本次训练的专业建议',
                            style: TextStyle(
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
                  label: const Text(
                    '开始分析',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Content area
          if (isAnalyzing)
            AILoadingWidget(message: aiCoachState.loadingMessage)
          else if (aiCoachState.error != null && aiCoachState.currentAnalysisType == 'session')
            _buildAnalysisError(ref, session.id, aiCoachState.error!)
          else if (sessionResult != null)
            Column(
              children: [
                AIResultCard(
                  result: sessionResult,
                  onDismiss: () {
                    ref.read(aiCoachProvider.notifier).clearSessionResult(session.id);
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(aiCoachProvider.notifier).analyzeSession(session);
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(
                    '重新分析',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            )
          else
            _buildAnalysisEmpty(),
        ],
      ),
    );
  }

  /// Error state for analysis
  Widget _buildAnalysisError(WidgetRef ref, String sessionId, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '分析失败',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              ref.read(aiCoachProvider.notifier).clearError();
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// Empty state for analysis
  Widget _buildAnalysisEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            '点击"开始分析"获取 AI 教练的专业建议\n优先使用在线分析，离线时自动切换本地分析',
            style: TextStyle(
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
}
