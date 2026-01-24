import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// AI 来源标识组件
/// 显示分析结果的来源（在线 Coze AI / 离线本地 AI）
class AISourceBadge extends StatelessWidget {
  final String source;
  final bool showIcon;

  const AISourceBadge({
    super.key,
    required this.source,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = source == 'coze';
    final isFallback = source == 'fallback';

    Color backgroundColor;
    Color textColor;
    IconData? icon;
    String label;

    if (isOnline) {
      backgroundColor = AppColors.primary.withOpacity(0.1);
      textColor = AppColors.primary;
      icon = Icons.cloud_done;
      label = 'AI 在线分析';
    } else if (isFallback) {
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey;
      icon = Icons.offline_bolt;
      label = '离线模式';
    } else {
      backgroundColor = AppColors.accentRust.withOpacity(0.1);
      textColor = AppColors.accentRust;
      icon = Icons.devices;
      label = '本地分析';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
