import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// AI 来源标识组件
/// 显示分析结果的来源（在线 Coze AI / 离线本地 AI）
class AISourceBadge extends StatelessWidget {
  final String source;
  final bool showIcon;
  final bool compact;

  const AISourceBadge({
    super.key,
    required this.source,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnline = source == 'coze';
    final isFallback = source == 'fallback';

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    if (isOnline) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.1);
      textColor = AppColors.primary;
      icon = Icons.cloud_done;
      label = l10n.aiCoachSourceOnline;
    } else if (isFallback) {
      backgroundColor = Colors.grey.withValues(alpha: 0.1);
      textColor = Colors.grey;
      icon = Icons.offline_bolt;
      label = l10n.aiCoachSourceOffline;
    } else {
      backgroundColor = AppColors.accentRust.withValues(alpha: 0.1);
      textColor = AppColors.accentRust;
      icon = Icons.devices;
      label = l10n.aiCoachSourceLocal;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: compact ? 10 : 14, color: textColor),
            SizedBox(width: compact ? 2 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: compact ? 0 : 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
