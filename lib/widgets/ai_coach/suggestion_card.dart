import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/ai_coach/ai_coach_result.dart';

/// 建议卡片组件
class SuggestionCard extends StatefulWidget {
  final CoachingSuggestion suggestion;
  final int index;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.index,
  });

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard> {
  bool _isExpanded = false;

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'technique':
        return AppColors.primary;
      case 'physical':
        return AppColors.accentRust;
      case 'mental':
        return const Color(0xFF6B4FA0);
      case 'equipment':
        return const Color(0xFF2D6A4F);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technique':
        return Icons.psychology;
      case 'physical':
        return Icons.fitness_center;
      case 'mental':
        return Icons.self_improvement;
      case 'equipment':
        return Icons.tune;
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'technique':
        return '技术';
      case 'physical':
        return '体能';
      case 'mental':
        return '心理';
      case 'equipment':
        return '器材';
      default:
        return '综合';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.suggestion.category);
    final categoryIcon = _getCategoryIcon(widget.suggestion.category);
    final categoryLabel = _getCategoryLabel(widget.suggestion.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：序号、类别、优先级
                Row(
                  children: [
                    // 序号圆圈
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index + 1}',
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 类别标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 14, color: categoryColor),
                          const SizedBox(width: 4),
                          Text(
                            categoryLabel,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // 优先级星标
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < widget.suggestion.priority
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: i < widget.suggestion.priority
                              ? AppColors.accentGold
                              : AppColors.borderLight,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 展开/折叠图标
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 标题
                Text(
                  widget.suggestion.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                // 描述
                Text(
                  widget.suggestion.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                // 行动步骤（展开时显示）
                if (_isExpanded &&
                    widget.suggestion.actionSteps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              size: 16,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '行动步骤',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...widget.suggestion.actionSteps
                            .asMap()
                            .entries
                            .map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.value,
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
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
