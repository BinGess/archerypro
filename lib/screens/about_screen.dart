import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _feedbackEmail = 'baibin1989@foxmail.com';
  static const String _privacyPolicyUrl =
      'https://lucky-geranium-802.notion.site/314407f7a7018042a975fc1f44683f27?source=copy_link';

  Future<void> _openEmail(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: _feedbackEmail,
    );
    await _openUrlOrCopy(
      context: context,
      uri: emailUri,
      fallbackText: _feedbackEmail,
      fallbackMessage: '邮箱地址已复制',
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    await _openUrlOrCopy(
      context: context,
      uri: Uri.parse(_privacyPolicyUrl),
      fallbackText: _privacyPolicyUrl,
      fallbackMessage: '隐私协议地址已复制',
    );
  }

  Future<void> _openUrlOrCopy({
    required BuildContext context,
    required Uri uri,
    required String fallbackText,
    required String fallbackMessage,
  }) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;

    await Clipboard.setData(ClipboardData(text: fallbackText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallbackMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.about),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'web/icons/Icon-512.png',
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AboutItem(
            title: 'App 名称',
            value: l10n.appName,
          ),
          const SizedBox(height: 10),
          _AboutItem(
            title: '反馈联系方式',
            value: _feedbackEmail,
            onTap: () => _openEmail(context),
            trailing:
                const Icon(Icons.open_in_new, color: AppColors.textSlate400),
          ),
          const SizedBox(height: 10),
          _AboutItem(
            title: '隐私协议',
            value: _privacyPolicyUrl,
            onTap: () => _openPrivacyPolicy(context),
            trailing:
                const Icon(Icons.open_in_new, color: AppColors.textSlate400),
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({
    required this.title,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSlate500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSlate900,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }
}
