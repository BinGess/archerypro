import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/ai_coach/ai_coach_result.dart';
import 'suggestion_card.dart';
import 'training_plan_card.dart';

/// AI 分析结果完整展示卡片
class AIResultCard extends StatelessWidget {
  final AICoachResult result;

  const AIResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 核心诊断
            _buildDiagnosis(),

            const SizedBox(height: 20),

            // 优势和弱点
            if (result.strengths.isNotEmpty || result.weaknesses.isNotEmpty)
              _buildStrengthsWeaknesses(),

            if (result.strengths.isNotEmpty || result.weaknesses.isNotEmpty)
              const SizedBox(height: 20),

            // 改进建议
            if (result.suggestions.isNotEmpty) ...[
              _buildSuggestionsSection(),
              const SizedBox(height: 20),
            ],

            // 训练计划
            if (result.trainingPlan != null) ...[
              TrainingPlanCard(plan: result.trainingPlan!),
              const SizedBox(height: 20),
            ],

            // 鼓励语
            if (result.encouragement != null &&
                result.encouragement!.isNotEmpty)
              _buildEncouragement(),
          ],
        ),
      ),
    );
  }

  /// 核心诊断
  Widget _buildDiagnosis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assessment,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '核心诊断',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.diagnosis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 优势和弱点
  Widget _buildStrengthsWeaknesses() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 优势
        if (result.strengths.isNotEmpty)
          Expanded(
            child: _buildInfoBox(
              title: '优势',
              icon: Icons.thumb_up_outlined,
              color: const Color(0xFF10B981),
              items: result.strengths,
            ),
          ),

        if (result.strengths.isNotEmpty && result.weaknesses.isNotEmpty)
          const SizedBox(width: 12),

        // 弱点
        if (result.weaknesses.isNotEmpty)
          Expanded(
            child: _buildInfoBox(
              title: '待改进',
              icon: Icons.flag_outlined,
              color: AppColors.accentRust,
              items: result.weaknesses,
            ),
          ),
      ],
    );
  }

  /// 信息盒子（优势/弱点）
  Widget _buildInfoBox({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 建议部分
  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '改进建议',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${result.suggestions.length} 条',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...result.suggestions.asMap().entries.map((entry) {
          return SuggestionCard(
            suggestion: entry.value,
            index: entry.key,
          );
        }),
      ],
    );
  }

  /// 鼓励语
  Widget _buildEncouragement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withOpacity(0.1),
            AppColors.accentGold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentGold.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.encouragement!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
