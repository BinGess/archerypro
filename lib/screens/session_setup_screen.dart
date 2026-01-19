import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../models/equipment.dart';
import 'scoring_screen.dart';
import '../providers/scoring_provider.dart';

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

  final List<double> _distanceOptions = [18, 30, 40, 50, 60, 70, 90];
  final List<int> _targetSizeOptions = [40, 60, 80, 122];

  void _startTraining() {
    // Create equipment
    final equipment = Equipment(
      bowType: _selectedBowType,
      model: _getBowModelName(_selectedBowType),
    );

    // Start new session with configuration
    ref.read(scoringProvider.notifier).startNewSession(
          equipment: equipment,
          distance: _distance,
          targetFaceSize: _targetFaceSize,
          environment: _environment,
        );

    // Navigate to scoring screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ScoringScreen(),
      ),
    );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('训练设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedBowType = BowType.recurve;
                _distance = 70;
                _targetFaceSize = 122;
                _endCount = 10;
                _arrowsPerEnd = 6;
                _environment = EnvironmentType.indoor;
                _isCompetitionMode = false;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '基本信息：${_selectedBowType.displayName} · ${_distance.toInt()}m · ${_targetFaceSize}cm靶面',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '训练',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Equipment Selection
            _buildSection(
              icon: Icons.sports_tennis,
              title: '器材',
              child: Column(
                children: [
                  _buildDropdown(
                    label: '弓型',
                    value: _selectedBowType.displayName,
                    items: BowType.values.map((type) => type.displayName).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBowType = BowType.values.firstWhere(
                          (type) => type.displayName == value,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '型号',
                      hintText: _getBowModelName(_selectedBowType),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Distance
            _buildSection(
              icon: Icons.straighten,
              title: '距离',
              child: _buildDropdown(
                label: '射击距离',
                value: '${_distance.toInt()}m',
                items: _distanceOptions.map((d) => '${d.toInt()}m').toList(),
                onChanged: (value) {
                  setState(() {
                    _distance = double.parse(value!.replaceAll('m', ''));
                  });
                },
              ),
            ),

            // Target Face Size
            _buildSection(
              icon: Icons.radio_button_checked,
              title: '靶面',
              child: _buildDropdown(
                label: '靶面大小',
                value: '${_targetFaceSize}cm',
                items: _targetSizeOptions.map((s) => '${s}cm').toList(),
                onChanged: (value) {
                  setState(() {
                    _targetFaceSize = int.parse(value!.replaceAll('cm', ''));
                  });
                },
              ),
            ),

            // Training Volume
            _buildSection(
              icon: Icons.format_list_numbered,
              title: '训练量',
              child: Column(
                children: [
                  _buildCounter(
                    label: '组数',
                    value: _endCount,
                    onIncrement: () => setState(() => _endCount++),
                    onDecrement: () => setState(() {
                      if (_endCount > 1) _endCount--;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _buildCounter(
                    label: '每组箭数',
                    value: _arrowsPerEnd,
                    onIncrement: () => setState(() {
                      if (_arrowsPerEnd < 12) _arrowsPerEnd++;
                    }),
                    onDecrement: () => setState(() {
                      if (_arrowsPerEnd > 1) _arrowsPerEnd--;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('总箭数', style: TextStyle(fontSize: 14)),
                        Text(
                          '$totalArrows 支箭',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Environment
            _buildSection(
              icon: Icons.location_on_outlined,
              title: '训练场地',
              child: Row(
                children: [
                  Expanded(
                    child: _buildEnvironmentButton(
                      label: '室内',
                      icon: Icons.home,
                      isSelected: _environment == EnvironmentType.indoor,
                      onTap: () => setState(() => _environment = EnvironmentType.indoor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnvironmentButton(
                      label: '室外',
                      icon: Icons.wb_sunny,
                      isSelected: _environment == EnvironmentType.outdoor,
                      onTap: () => setState(() => _environment = EnvironmentType.outdoor),
                    ),
                  ),
                ],
              ),
            ),

            // Competition Mode
            _buildSection(
              icon: Icons.emoji_events,
              title: '比赛模式',
              child: SwitchListTile(
                title: const Text('启用比赛模式'),
                subtitle: const Text('按照比赛规则进行训练'),
                value: _isCompetitionMode,
                onChanged: (value) => setState(() => _isCompetitionMode = value),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _startTraining,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, size: 24),
                SizedBox(width: 8),
                Text(
                  '开始训练',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSlate600),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSlate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCounter({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Row(
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.primary,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvironmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSlate600,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSlate600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
