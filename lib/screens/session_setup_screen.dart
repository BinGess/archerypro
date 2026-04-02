import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../models/equipment.dart';
import '../models/training_session.dart';
import '../models/competition_settings.dart';
import 'scoring_screen.dart';
import 'competition_screen.dart';
import '../providers/scoring_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/competition/competition_setup_sheet.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  static const double _compactPagePadding = 12;
  static const double _sectionGap = 14;
  static const double _cardHeaderBottom = 8;
  static const double _rowHorizontalPadding = 14;
  static const double _rowVerticalPadding = 10;
  static const double _toggleHeight = 32;
  static const double _toggleHorizontalPadding = 12;
  static const double _toggleVerticalPadding = 4;
  static const double _rulesCardPadding = 14;
  static const double _rulesCounterGap = 16;
  static const double _rulesSummaryVerticalPadding = 10;
  static const double _bottomSpacer = 76;

  BowType _selectedBowType = BowType.recurve;
  double _distance = 70;
  int _targetFaceSize = 122;
  int _endCount = 10;
  int _arrowsPerEnd = 6;
  EnvironmentType _environment = EnvironmentType.indoor;
  bool _isCompetitionMode = false;
  bool _isTargetMode = false; // Default to list view

  final List<double> _distanceOptions = [18, 30, 40, 50, 60, 70, 90];
  final List<int> _targetSizeOptions = [40, 60, 80, 122];

  @override
  void initState() {
    super.initState();
    _loadLastSettings();
  }

  /// Load last training settings from storage
  void _loadLastSettings() {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _selectedBowType = BowType
          .values[storage.getSetting<int>('lastBowType', defaultValue: 1) ?? 1];
      _distance =
          storage.getSetting<double>('lastDistance', defaultValue: 70.0) ??
              70.0;
      _targetFaceSize =
          storage.getSetting<int>('lastTargetSize', defaultValue: 122) ?? 122;
      _endCount =
          storage.getSetting<int>('lastEndCount', defaultValue: 10) ?? 10;
      _arrowsPerEnd =
          storage.getSetting<int>('lastArrowsPerEnd', defaultValue: 6) ?? 6;
      _environment = EnvironmentType.values[
          storage.getSetting<int>('lastEnvironment', defaultValue: 0) ?? 0];
      _isTargetMode =
          storage.getSetting<bool>('lastIsTargetMode', defaultValue: false) ??
              false;
    });
  }

  /// Save current settings to storage
  Future<void> _saveSettings() async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveSetting('lastBowType', _selectedBowType.index);
    await storage.saveSetting('lastDistance', _distance);
    await storage.saveSetting('lastTargetSize', _targetFaceSize);
    await storage.saveSetting('lastEndCount', _endCount);
    await storage.saveSetting('lastArrowsPerEnd', _arrowsPerEnd);
    await storage.saveSetting('lastEnvironment', _environment.index);
    await storage.saveSetting('lastIsTargetMode', _isTargetMode);
  }

  void _startTraining() async {
    final l10n = AppLocalizations.of(context);
    // Save current settings for next time
    await _saveSettings();

    if (_isCompetitionMode) {
      _startCompetition();
      return;
    }

    // Create equipment
    final equipment = Equipment(
      bowType: _selectedBowType,
      bowName: _getBowModelName(_selectedBowType, l10n),
    );

    // Start new session with configuration
    ref.read(scoringProvider.notifier).startNewSession(
          equipment: equipment,
          distance: _distance,
          targetFaceSize: _targetFaceSize,
          environment: _environment,
          maxEnds: _endCount,
          arrowsPerEnd: _arrowsPerEnd,
          isTargetMode: _isTargetMode,
        );

    // Navigate to scoring screen
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ScoringScreen(),
        ),
      );
    }
  }

  void _startCompetition() async {
    final settings = await Navigator.of(context).push<CompetitionSettings>(
      MaterialPageRoute(
        builder: (context) => CompetitionSetupSheet(
          arrowsPerEnd: _arrowsPerEnd,
          totalEnds: _endCount,
          fullScreen: true,
        ),
      ),
    );

    if (settings != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CompetitionScreen(settings: settings),
        ),
      );
    }
  }

  String _getBowModelName(BowType type, AppLocalizations l10n) {
    return l10n.myBowName(_getBowTypeLabel(type, l10n));
  }

  String _getBowTypeLabel(BowType type, AppLocalizations l10n) {
    switch (type) {
      case BowType.recurve:
        return l10n.bowRecurve;
      case BowType.compound:
        return l10n.bowCompound;
      case BowType.barebow:
        return l10n.bowBarebow;
      case BowType.longbow:
        return l10n.bowLongbow;
    }
  }

  String _formatDistance(double value, AppLocalizations l10n) {
    return '${value.toInt()}${l10n.meters}';
  }

  String _formatTargetSize(int value, AppLocalizations l10n) {
    return '$value${l10n.centimeters}';
  }

  @override
  Widget build(BuildContext context) {
    final totalArrows = _endCount * _arrowsPerEnd;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor:
          AppColors.backgroundLight, // Use light background for card contrast
      appBar: AppBar(
        title: Text(l10n.newTraining),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedBowType = BowType.recurve;
                _distance = 70;
                _targetFaceSize = 122;
                _endCount = 10;
                _arrowsPerEnd = 6;
                _environment = EnvironmentType.indoor;
                _isCompetitionMode = false;
                _isTargetMode = false;
              });
            },
            child: Text(l10n.reset),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_compactPagePadding),
        child: Column(
          children: [
            // 1. 器材设置 (Equipment)
            _buildCardGroup(
              title: l10n.sessionSetupEquipment,
              icon: Icons.sports_tennis,
              children: [
                _buildRowItem(
                  label: l10n.bowType,
                  child: DropdownButton<BowType>(
                    value: _selectedBowType,
                    underline: const SizedBox(),
                    items: BowType.values
                        .map((type) => DropdownMenuItem<BowType>(
                              value: type,
                              child: Text(_getBowTypeLabel(type, l10n),
                                  style: AppTextStyles.rowLabel.copyWith(
                                    fontSize: 14,
                                  )),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedBowType = value);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: _getBowModelName(_selectedBowType, l10n),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSlate900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _sectionGap),

            // 2. 场地与环境 (Venue & Environment)
            _buildCardGroup(
              title: l10n.sessionSetupVenue,
              icon: Icons.place,
              children: [
                _buildRowItem(
                  label: l10n.environment,
                  child: Container(
                    height: _toggleHeight,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleOption(
                            l10n.indoor,
                            _environment == EnvironmentType.indoor,
                            () => setState(
                                () => _environment = EnvironmentType.indoor)),
                        _buildToggleOption(
                            l10n.outdoor,
                            _environment == EnvironmentType.outdoor,
                            () => setState(
                                () => _environment = EnvironmentType.outdoor)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDropdownItem(
                          label: l10n.distance,
                          value: _formatDistance(_distance, l10n),
                          items: _distanceOptions
                              .map((d) => _formatDistance(d, l10n))
                              .toList(),
                          onChanged: (v) => setState(() => _distance =
                              double.parse(
                                  v!.replaceAll(RegExp(r'[^0-9.]'), ''))),
                        ),
                      ),
                      Container(
                          width: 1, height: 40, color: AppColors.borderLight),
                      Expanded(
                        child: _buildDropdownItem(
                          label: l10n.targetFaceSize,
                          value: _formatTargetSize(_targetFaceSize, l10n),
                          items: _targetSizeOptions
                              .map((s) => _formatTargetSize(s, l10n))
                              .toList(),
                          onChanged: (v) => setState(() => _targetFaceSize =
                              int.parse(v!.replaceAll(RegExp(r'[^0-9]'), ''))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: _sectionGap),

            // 3. 训练规则 (Rules)
            _buildCardGroup(
              title: l10n.sessionSetupRules,
              icon: Icons.rule,
              children: [
                Padding(
                  padding: const EdgeInsets.all(_rulesCardPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactCounter(
                            l10n.numberOfEnds,
                            _endCount,
                            () => setState(() => _endCount++),
                            () => setState(() {
                                  if (_endCount > 1) _endCount--;
                                })),
                      ),
                      const SizedBox(width: _rulesCounterGap),
                      Expanded(
                        child: _buildCompactCounter(
                            l10n.arrowsPerEnd,
                            _arrowsPerEnd,
                            () => setState(() {
                                  if (_arrowsPerEnd < 12) _arrowsPerEnd++;
                                }),
                            () => setState(() {
                                  if (_arrowsPerEnd > 1) _arrowsPerEnd--;
                                })),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _rulesCardPadding,
                    vertical: _rulesSummaryVerticalPadding,
                  ),
                  color: AppColors.primary.withValues(alpha: 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.estimatedTotalArrows,
                          style: AppTextStyles.subLabel.copyWith(
                            fontWeight: FontWeight.w500,
                          )),
                      Text('$totalArrows ${l10n.unitArrows}',
                          style: AppTextStyles.rowLabel.copyWith(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: _sectionGap),

            // 4. 偏好设置 (Preferences)
            _buildCardGroup(
              title: l10n.sessionSetupDisplayMode,
              icon: Icons.tune,
              children: [
                _buildRowItem(
                  label: l10n.scoringView,
                  child: Container(
                    height: _toggleHeight,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleOption(l10n.listView, !_isTargetMode,
                            () => setState(() => _isTargetMode = false)),
                        _buildToggleOption(l10n.targetView, _isTargetMode,
                            () => setState(() => _isTargetMode = true)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: Text(l10n.competitionMode,
                      style: AppTextStyles.rowLabel.copyWith(
                        fontSize: 14,
                      )),
                  value: _isCompetitionMode,
                  onChanged: (val) => setState(() => _isCompetitionMode = val),
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  dense: true,
                ),
              ],
            ),

            const SizedBox(height: _bottomSpacer), // Bottom padding for FAB
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: _startTraining,
            backgroundColor: AppColors.primary,
            elevation: 4,
            label: Text(l10n.startTraining,
                style: AppTextStyles.primaryButton.copyWith(
                  color: Colors.white,
                )),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCardGroup(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: _cardHeaderBottom),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSlate500),
              const SizedBox(width: 6),
              Text(title,
                  style: AppTextStyles.sectionHeader.copyWith(
                    fontSize: 13,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _buildRowItem({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _rowHorizontalPadding, vertical: _rowVerticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.rowLabel.copyWith(
                fontSize: 14,
              )),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: _toggleHorizontalPadding,
            vertical: _toggleVerticalPadding),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [const BoxShadow(color: AppColors.shadowMedium, blurRadius: 2)]
              : [],
        ),
        child: Text(
          text,
          style: AppTextStyles.subLabel.copyWith(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.textSlate900 : AppColors.textSlate500,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(
      {required String label,
      required String value,
      required List<String> items,
      required Function(String?) onChanged}) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => _showSelectionPicker(
        context,
        title: l10n.sessionSetupSelectLabel(label),
        currentValue: value,
        items: items,
        onSelected: (val) => onChanged(val),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.subLabel.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: AppTextStyles.rowLabel.copyWith(
                      fontSize: 15,
                    )),
                const Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textSlate400, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionPicker(
    BuildContext context, {
    required String title,
    required String currentValue,
    required List<String> items,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  title,
                  style: AppTextStyles.cardSectionTitle,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == currentValue;
                    return InkWell(
                      onTap: () {
                        onSelected(item);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item,
                              style: AppTextStyles.rowLabel.copyWith(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSlate900,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactCounter(String label, int value, VoidCallback onIncrement,
      VoidCallback onDecrement) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.subLabel.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                    padding: EdgeInsets.all(8),
                    child:
                        Icon(Icons.remove, size: 20, color: AppColors.primary)),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 40),
              alignment: Alignment.center,
              child: Text('$value',
                  style: AppTextStyles.cardSectionTitle.copyWith(
                    fontSize: 20,
                  )),
            ),
            Material(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.add, size: 20, color: AppColors.primary)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
