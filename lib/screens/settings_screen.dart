import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/statistics.dart';
import '../providers/analytics_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/scoring_provider.dart';
import 'about_screen.dart';
import 'logs_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final analyticsState = ref.watch(analyticsProvider);
    final stats = analyticsState.allTimeStatistics;
    final storedGoal = ref.read(storageServiceProvider).getMonthlyGoal();
    final currentGoal = stats.monthlyGoal ?? storedGoal;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 4),
          _buildSectionHeader(context, l10n.monthlyGoalSettings),
          _buildMonthlyGoalSection(
            context,
            ref,
            l10n,
            stats: stats,
            currentGoal: currentGoal,
          ),
          const SizedBox(height: 14),
          _buildSectionHeader(context, l10n.languageSettings),
          _buildLanguageSection(context, ref, l10n),
          const SizedBox(height: 14),
          _buildSectionHeader(context, l10n.debugSection),
          _buildDebugSection(context, l10n),
          const SizedBox(height: 14),
          _buildSectionHeader(context, l10n.about),
          _buildInfoSection(context, l10n),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSlate500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMonthlyGoalSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required Statistics stats,
    required int currentGoal,
  }) {
    final currentMonthArrows = stats.currentMonthArrows;
    final progressPercent = stats.monthlyGoalProgress.clamp(0.0, 999.0);
    final progressValue = (stats.monthlyGoalProgress / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          InkWell(
            onTap: () =>
                _showMonthlyGoalDialog(context, ref, l10n, currentGoal),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.track_changes_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.monthlyGoalMessage(currentGoal.toString()),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSlate900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.monthlyGoalSettingsSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSlate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSlate400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      l10n.monthlyGoalCurrentProgress,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSlate500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$currentMonthArrows ${l10n.unitArrows}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      l10n.monthlyGoalCompletion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSlate500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${progressPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceSubtle,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthlyGoalDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    int currentGoal,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _MonthlyGoalDialog(
        initialGoal: currentGoal,
        l10n: l10n,
      ),
    );

    if (result == null) return;

    await ref.read(storageServiceProvider).setMonthlyGoal(result);
    final analyticsNotifier = ref.read(analyticsProvider.notifier);
    analyticsNotifier.clearCache();
    await analyticsNotifier.refreshAnalytics();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.monthlyGoalSaveSuccess),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildLanguageSection(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final localeState = ref.watch(localeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          _buildLanguageOption(
            context: context,
            ref: ref,
            title: l10n.systemDefault,
            subtitle: _getSystemLanguageName(context),
            isSelected: localeState.isSystemDefault,
            onTap: () async {
              await ref.read(localeProvider.notifier).useSystemDefault();
            },
            isFirst: true,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildLanguageOption(
            context: context,
            ref: ref,
            title: l10n.chinese,
            subtitle: '简体中文',
            isSelected: !localeState.isSystemDefault &&
                localeState.locale.languageCode == 'zh',
            onTap: () async {
              await ref
                  .read(localeProvider.notifier)
                  .setLocale(const Locale('zh'));
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildLanguageOption(
            context: context,
            ref: ref,
            title: l10n.english,
            subtitle: 'English',
            isSelected: !localeState.isSystemDefault &&
                localeState.locale.languageCode == 'en',
            onTap: () async {
              await ref
                  .read(localeProvider.notifier)
                  .setLocale(const Locale('en'));
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSlate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LogsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bug_report_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.viewLogs,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.viewLogsSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSlate400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AboutScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.about,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '反馈&隐私协议',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSlate400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSystemLanguageName(BuildContext context) {
    final resolvedLocale = LocaleNotifier.resolveSupportedLocale(
      View.of(context).platformDispatcher.locale,
    );
    switch (resolvedLocale.languageCode) {
      case 'zh':
        return '简体中文';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }
}

class _MonthlyGoalDialog extends StatefulWidget {
  const _MonthlyGoalDialog({
    required this.initialGoal,
    required this.l10n,
  });

  final int initialGoal;
  final AppLocalizations l10n;

  @override
  State<_MonthlyGoalDialog> createState() => _MonthlyGoalDialogState();
}

class _MonthlyGoalDialogState extends State<_MonthlyGoalDialog> {
  late final TextEditingController _controller;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() {
        _validationError = widget.l10n.monthlyGoalInvalidValue;
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.monthlyGoalSetTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.l10n.monthlyGoalInputHint,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSlate500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.l10n.monthlyGoalInputLabel,
              errorText: _validationError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l10n.cancel),
        ),
        TextButton(
          onPressed: _handleSave,
          child: Text(widget.l10n.save),
        ),
      ],
    );
  }
}
