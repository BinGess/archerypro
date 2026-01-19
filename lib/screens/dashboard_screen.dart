import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: AppColors.backgroundLight.withOpacity(0.95),
              title: const Text(
                'Training History',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSlate900),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.tune, color: AppColors.primary, size: 20),
                )
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildHistoryItem(
                    isHighRecord: true,
                    date: 'OCT 24',
                    score: 590,
                    total: 600,
                    type: 'Compound • 18m',
                    child: _buildMiniHeatmap(),
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryItem(
                    isHighRecord: false,
                    date: 'OCT 22',
                    score: 284,
                    total: 300,
                    type: 'Recurve • 70m',
                    child: _buildBarChart(),
                  ),
                  const SizedBox(height: 32),
                  const Opacity(
                    opacity: 0.4,
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 64, color: AppColors.textSlate500),
                        SizedBox(height: 16),
                        Text('All October records shown', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return ArcheryCard(
      padding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(100)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text('12', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                            const SizedBox(width: 4),
                            Text('sessions', style: TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('2,400 arrows this month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate500)),
                          ],
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text('9.2', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1, color: AppColors.primary)),
                            const SizedBox(width: 4),
                            Text('avg', style: TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(text: '↑ 0.3', color: Colors.green.shade700, backgroundColor: Colors.green.shade50),
                            const SizedBox(width: 4),
                            Text('Average', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate400)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: CustomPaint(painter: CustomCurvePainter(color: AppColors.primary)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Goal: 3000', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                    Text('80%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.8,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
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

  Widget _buildHistoryItem({
    required bool isHighRecord,
    required String date,
    required int score,
    required int total,
    required String type,
    required Widget child,
  }) {
    return Stack(
      children: [
        if (isHighRecord)
          Positioned(
            left: 0, bottom: 0, top: 0,
            child: Container(width: 4, color: AppColors.accentGold),
          ),
        ArcheryCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isHighRecord) ...[
                              StatusBadge(text: 'BEST', color: AppColors.accentGold, backgroundColor: AppColors.accentGold.withOpacity(0.1)),
                              const SizedBox(width: 8),
                            ],
                            Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSlate400)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('$score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isHighRecord ? AppColors.primary : AppColors.textSlate900)),
                            Text('/$total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textSlate400)),
                          ],
                        ),
                        Text(type, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(isHighRecord ? 'Analytics' : 'Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isHighRecord ? AppColors.primary : AppColors.textSlate400)),
                        Icon(Icons.chevron_right, size: 16, color: isHighRecord ? AppColors.primary : AppColors.textSlate400),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: isHighRecord ? Colors.white : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: child,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniHeatmap() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Target rings simplified
        Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
        Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
        Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
        
        // Shots
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: List.generate(8, (index) => Center(
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(index == 0 ? 1 : 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            )),
          ),
        ),
        const Positioned(
          bottom: 4, right: 4,
          child: Icon(Icons.workspace_premium, color: AppColors.accentGold, size: 20),
        )
      ],
    );
  }

  Widget _buildBarChart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bar(0.4, 0.2),
                _bar(0.6, 0.4),
                _bar(1.0, 1.0),
                _bar(0.5, 0.3),
                _bar(0.3, 0.2),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Stability: 84%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
        ),
      ],
    );
  }

  Widget _bar(double heightFactor, double opacity) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        width: 12,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(opacity),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        ),
      ),
    );
  }
}
