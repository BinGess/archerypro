import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('PERFORMANCE ANALYSIS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () {}),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.share, size: 18, color: AppColors.primary),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTab('7D', false),
              _buildTab('1M', true),
              _buildTab('3M', false),
              _buildTab('ALL', false),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildScoreTrendCard(),
          const SizedBox(height: 20),
          _buildHeatmapCard(),
          const SizedBox(height: 20),
          _buildInsightSection(),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 2, color: isSelected ? AppColors.primary : Colors.transparent)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? AppColors.primary : AppColors.textSlate400,
        ),
      ),
    );
  }

  Widget _buildScoreTrendCard() {
    return ArcheryCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AVG. END SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('8.4', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(width: 8),
                      Text('5.2%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                      Icon(Icons.trending_up, size: 16, color: Colors.green.shade600),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.insights, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(painter: CustomCurvePainter(color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OCT 01', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
              Text('OCT 15', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
              Text('OCT 30', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeatmapCard() {
    return ArcheryCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IMPACT ACCURACY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              StatusBadge(text: 'TREND: LOW LEFT', color: AppColors.accentRust, backgroundColor: AppColors.accentRust.withOpacity(0.1)),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              // Target Faces
              _buildRing(180, Colors.grey.shade100),
              _buildRing(150, Colors.white), // Simplified for aesthetics
              _buildRing(120, Colors.white),
              _buildRing(90, Colors.white),
              _buildRing(60, Colors.white),
              _buildRing(30, AppColors.accentGold.withOpacity(0.2)),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentGold, shape: BoxShape.circle)),

              // Heat blobs
              Positioned(
                bottom: 40, left: 60,
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ).blur(),
              ),
              Positioned(
                bottom: 50, left: 80,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ).blur(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppColors.primary, 'GROUPING'),
              const SizedBox(width: 24),
              _buildLegend(AppColors.accentGold, 'BULLSEYE'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRing(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
      ],
    );
  }

  Widget _buildInsightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 20),
            const SizedBox(width: 8),
            const Text('AI COACH INSIGHTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSlate900)),
          ],
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.track_changes,
          color: AppColors.primary,
          title: 'Stability Focus',
          desc: 'Back tension decreased slightly in last 3 ends. Maintain expansion through clicker.',
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: Icons.fitness_center,
          color: AppColors.accentRust,
          title: 'Suggestion: 30m Drills',
          desc: 'To correct the low-left tendency, perform 30 arrows on blank bale focusing on bow arm.',
          hasAction: true,
        ),
      ],
    );
  }

  Widget _buildInsightItem({required IconData icon, required Color color, required String title, required String desc, bool hasAction = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAction ? Colors.white : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasAction ? AppColors.borderLight : color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSlate500)),
                if (hasAction) ...[
                  const SizedBox(height: 8),
                  Text('START DRILL →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}

extension BlurExt on Widget {
  Widget blur() => this; // Placeholder for ImageFilter.blur if needed, or just standard opacity overlay
}
