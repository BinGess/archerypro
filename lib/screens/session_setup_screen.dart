import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../models/equipment.dart';
import '../models/training_session.dart';
import 'scoring_screen.dart';
import '../providers/scoring_provider.dart';
import '../services/storage_service.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
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
      _selectedBowType = BowType.values[storage.getSetting<int>('lastBowType', defaultValue: 1) ?? 1];
      _distance = storage.getSetting<double>('lastDistance', defaultValue: 70.0) ?? 70.0;
      _targetFaceSize = storage.getSetting<int>('lastTargetSize', defaultValue: 122) ?? 122;
      _endCount = storage.getSetting<int>('lastEndCount', defaultValue: 10) ?? 10;
      _arrowsPerEnd = storage.getSetting<int>('lastArrowsPerEnd', defaultValue: 6) ?? 6;
      _environment = EnvironmentType.values[storage.getSetting<int>('lastEnvironment', defaultValue: 0) ?? 0];
      _isTargetMode = storage.getSetting<bool>('lastIsTargetMode', defaultValue: false) ?? false;
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
    // Save current settings for next time
    await _saveSettings();

    // Create equipment
    final equipment = Equipment(
      bowType: _selectedBowType,
      bowName: _getBowModelName(_selectedBowType),
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

  String _getBowModelName(BowType type) {
    switch (type) {
      case BowType.recurve:
        return 'My Hoyt Formula Xi';
      case BowType.compound:
        return 'My Compound Bow';
      case BowType.barebow:
        return 'My Barebow';
      case BowType.longbow:
        return 'My Longbow';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalArrows = _endCount * _arrowsPerEnd;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight, // Use light background for card contrast
      appBar: AppBar(
        title: const Text('训练设置', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
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
            child: const Text('重置', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. 器材设置 (Equipment)
            _buildCardGroup(
              title: '器材设置',
              icon: Icons.sports_tennis,
              children: [
                _buildRowItem(
                  label: '弓种',
                  child: DropdownButton<String>(
                    value: _selectedBowType.displayName,
                    underline: const SizedBox(),
                    items: BowType.values.map((type) => DropdownMenuItem(
                      value: type.displayName,
                      child: Text(type.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBowType = BowType.values.firstWhere((type) => type.displayName == value);
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: _getBowModelName(_selectedBowType),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14, color: AppColors.textSlate500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. 场地与环境 (Venue & Environment)
            _buildCardGroup(
              title: '场地环境',
              icon: Icons.place,
              children: [
                _buildRowItem(
                  label: '环境',
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleOption('室内', _environment == EnvironmentType.indoor, () => setState(() => _environment = EnvironmentType.indoor)),
                        _buildToggleOption('室外', _environment == EnvironmentType.outdoor, () => setState(() => _environment = EnvironmentType.outdoor)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownItem(
                        label: '距离', 
                        value: '${_distance.toInt()}m',
                        items: _distanceOptions.map((d) => '${d.toInt()}m').toList(),
                        onChanged: (v) => setState(() => _distance = double.parse(v!.replaceAll('m', ''))),
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.shade200),
                    Expanded(
                      child: _buildDropdownItem(
                        label: '靶面', 
                        value: '${_targetFaceSize}cm',
                        items: _targetSizeOptions.map((s) => '${s}cm').toList(),
                        onChanged: (v) => setState(() => _targetFaceSize = int.parse(v!.replaceAll('cm', ''))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. 训练规则 (Rules)
            _buildCardGroup(
              title: '训练规则',
              icon: Icons.rule,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactCounter('组数', _endCount, 
                          () => setState(() => _endCount++), 
                          () => setState(() { if (_endCount > 1) _endCount--; })
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildCompactCounter('每组箭数', _arrowsPerEnd, 
                          () => setState(() { if (_arrowsPerEnd < 12) _arrowsPerEnd++; }), 
                          () => setState(() { if (_arrowsPerEnd > 1) _arrowsPerEnd--; })
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.primary.withOpacity(0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('预计总箭数', style: TextStyle(fontSize: 12, color: AppColors.textSlate500)),
                      Text('$totalArrows 支', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. 偏好设置 (Preferences)
            _buildCardGroup(
              title: '显示与模式',
              icon: Icons.tune,
              children: [
                _buildRowItem(
                  label: '计分视图',
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleOption('列表', !_isTargetMode, () => setState(() => _isTargetMode = false)),
                        _buildToggleOption('靶面', _isTargetMode, () => setState(() => _isTargetMode = true)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('比赛模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  value: _isCompetitionMode,
                  onChanged: (val) => setState(() => _isCompetitionMode = val),
                  activeColor: AppColors.primary,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            
            const SizedBox(height: 100), // Bottom padding for FAB
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: _startTraining,
            backgroundColor: AppColors.primary,
            elevation: 4,
            label: const Text('开始训练', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCardGroup({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSlate500),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSlate500)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _buildRowItem({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textSlate900 : AppColors.textSlate500,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem({required String label, required String value, required List<String> items, required Function(String?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSlate400)),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCounter(String label, int value, VoidCallback onIncrement, VoidCallback onDecrement) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSlate400)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: onDecrement,
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, size: 20, color: AppColors.primary)),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              alignment: Alignment.center,
              child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            InkWell(
              onTap: onIncrement,
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size: 20, color: AppColors.primary)),
            ),
          ],
        ),
      ],
    );
  }
}

extension BowTypeExtension on BowType {
  String get displayName {
    switch (this) {
      case BowType.recurve:
        return '反曲弓';
      case BowType.compound:
        return '复合弓';
      case BowType.barebow:
        return '光弓';
      case BowType.longbow:
        return '长弓';
    }
  }
}
