import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/session_provider.dart';
import '../models/training_session.dart';

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

            // AI Advice Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text('AI 训练建议', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generateAdvice(session),
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSlate500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

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

            const SizedBox(height: 40),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteSession(context, ref, session),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('删除记录', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement Edit
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('编辑功能开发中')));
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('编辑记录', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
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

  String _generateAdvice(dynamic session) {
    final avgScore = session.averageArrowScore;
    final consistency = session.consistency;

    if (consistency > 90 && avgScore > 9) {
      return '表现出色！你的稳定性 (${consistency.toStringAsFixed(1)}%) 和精准度都非常棒。可以考虑增加距离或尝试室外环境来进一步挑战自己。';
    } else if (consistency > 85) {
      return '稳定性极佳，达到了 ${consistency.toStringAsFixed(1)}%。你的技术很扎实。专注于微调瞄准，争取将平均分从 ${avgScore.toStringAsFixed(1)} 提升到 9.5 以上。';
    } else if (consistency < 70) {
      return '稳定性 (${consistency.toStringAsFixed(1)}%) 还有提升空间。请专注于保持一致的靠位、撒放和后续动作。建议进行近距离光靶练习以优化动作。';
    } else {
      return '不错的训练，稳定性为 ${consistency.toStringAsFixed(1)}%，平均分为 ${avgScore.toStringAsFixed(1)}。继续练习基本动作和呼吸控制以取得更好成绩。';
    }
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

