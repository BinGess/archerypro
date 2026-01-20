import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../widgets/heatmap_with_center.dart';
import '../widgets/end_trend_chart.dart';
import '../widgets/score_distribution_chart.dart';
import '../providers/session_provider.dart';
import '../models/training_session.dart';
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

            // AI Advice Card
            _buildEnhancedAIAdvice(session, ref),

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
          child,
        ],
      ),
    );
  }

  /// Build enhanced AI advice using SessionAnalysisService
  Widget _buildEnhancedAIAdvice(TrainingSession session, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    final analysisService = SessionAnalysisService();

    // Generate insight using AI service
    final insight = analysisService.generateSessionInsight(
      session,
      sessionState.sessions.where((s) => s.id != session.id).toList(),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            insight.color.withOpacity(0.1),
            insight.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: insight.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: insight.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(insight.icon, size: 20, color: insight.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'AI 教练建议',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSlate400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: insight.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSlate700,
            ),
          ),
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
}

