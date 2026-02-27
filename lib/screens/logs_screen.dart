import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logger_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final _logger = LoggerService();
  String _logContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final content = await _logger.getCurrentLogContent();
      setState(() {
        _logContent = content;
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _logContent = l10n.logsFailedToLoad(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _copyLogsToClipboard() async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _logContent));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.logsCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearLogs() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearLogsTitle),
        content: Text(l10n.clearLogsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logger.clearLogs();
      await _loadLogs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.logsCleared),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.logsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: l10n.refreshLogsTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: l10n.copyLogsTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: l10n.clearLogsTooltip,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.amber.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 20, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.logsLocalOnlyHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _logContent.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noLogsAvailable,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSlate500,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            _logContent,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
