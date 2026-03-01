import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/competition_settings.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class CompetitionSetupSheet extends StatefulWidget {
  final int arrowsPerEnd;
  final int totalEnds;
  final bool fullScreen;

  const CompetitionSetupSheet({
    super.key,
    required this.arrowsPerEnd,
    required this.totalEnds,
    this.fullScreen = false,
  });

  @override
  State<CompetitionSetupSheet> createState() => _CompetitionSetupSheetState();
}

class _CompetitionSetupSheetState extends State<CompetitionSetupSheet> {
  late int _timePerArrow;
  bool _customTime = false;
  bool _soundEnabled = true;
  bool _useTargetScoring = false;
  final _customTimeController = TextEditingController(text: '40');

  @override
  void initState() {
    super.initState();
    _timePerArrow = 40;
  }

  @override
  void dispose() {
    _customTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = _buildForm(context, l10n);

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(l10n.competitionMode),
          centerTitle: true,
        ),
        body: content,
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: content,
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.fullScreen)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (!widget.fullScreen) const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.competitionMode,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSlate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.competitionWaStandard,
            style: const TextStyle(fontSize: 13, color: AppColors.textSlate500),
          ),
          const SizedBox(height: 24),
          _sectionLabel(l10n.competitionTimePerArrow),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 30,
                label: Text(_secondsText(context, 30)),
                icon: const Icon(Icons.speed, size: 16),
              ),
              ButtonSegment(
                value: 40,
                label: Text(_secondsText(context, 40)),
                icon: const Icon(Icons.schedule, size: 16),
              ),
              ButtonSegment(value: -1, label: Text(l10n.competitionCustom)),
            ],
            selected: {_customTime ? -1 : _timePerArrow},
            onSelectionChanged: (v) {
              setState(() {
                if (v.first == -1) {
                  _customTime = true;
                } else {
                  _customTime = false;
                  _timePerArrow = v.first;
                }
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
              selectedForegroundColor: AppColors.primary,
            ),
          ),
          if (_customTime) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _customTimeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0) {
                        setState(() => _timePerArrow = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.competitionSecondsPerArrow,
                  style: const TextStyle(color: AppColors.textSlate500),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.competitionWhistleSounds,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate900,
                    ),
                  ),
                  Text(
                    l10n.competitionWaWhistleDesc,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSlate500),
                  ),
                ],
              ),
              Switch(
                value: _soundEnabled,
                onChanged: (v) => setState(() => _soundEnabled = v),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionLabel(l10n.competitionInputMode),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(l10n.competitionKeyboardEntry),
                icon: const Icon(Icons.dialpad_rounded, size: 16),
              ),
              ButtonSegment(
                value: true,
                label: Text(l10n.competitionTargetEntry),
                icon: const Icon(Icons.gps_fixed_rounded, size: 16),
              ),
            ],
            selected: {_useTargetScoring},
            onSelectionChanged: (v) {
              setState(() => _useTargetScoring = v.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
              selectedForegroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem(l10n.competitionPrep, _secondsText(context, 10)),
                _summaryItem(
                  l10n.competitionShoot,
                  _secondsText(context, widget.arrowsPerEnd * _timePerArrow),
                ),
                _summaryItem(l10n.competitionWarn, l10n.competitionWarningLeft),
                _summaryItem(
                  l10n.competitionTotal,
                  _estimateMinutesText(
                    context,
                    (widget.totalEnds *
                            (widget.arrowsPerEnd * _timePerArrow + 10) /
                            60)
                        .ceil(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                final effectiveTime = _resolveEffectiveTime();
                Navigator.of(context).pop(CompetitionSettings(
                  arrowsPerEnd: widget.arrowsPerEnd,
                  timePerArrowSeconds: effectiveTime,
                  soundEnabled: _soundEnabled,
                  totalEnds: widget.totalEnds,
                  useTargetScoring: _useTargetScoring,
                ));
              },
              icon: const Icon(Icons.flag_rounded, size: 24),
              label: Text(
                l10n.competitionStartBtn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textSlate400,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSlate400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  String _secondsText(BuildContext context, int seconds) {
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';
    return isChinese ? '$seconds秒' : '${seconds}s';
  }

  String _estimateMinutesText(BuildContext context, int minutes) {
    final isChinese = Localizations.localeOf(context).languageCode == 'zh';
    return isChinese ? '~$minutes分钟' : '~${minutes}min';
  }

  int _resolveEffectiveTime() {
    if (!_customTime) return _timePerArrow;
    final raw = _customTimeController.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return _timePerArrow > 0 ? _timePerArrow : 40;
  }
}
