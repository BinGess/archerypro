import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../providers/session_provider.dart';

class DetailsScreen extends ConsumerWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSession = ref.watch(selectedSessionProvider);
    final sessionState = ref.watch(sessionProvider);

    // Use selected session or most recent session
    final session = selectedSession ?? sessionState.sessions.firstOrNull;

    if (session == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.list_alt, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('No Sessions Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Complete a training session to see details here', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Training Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Clear selection when going back
            ref.read(selectedSessionProvider.notifier).state = null;
          },
        ),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share, size: 20, color: AppColors.primary)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                DateFormat('yyyy MMM dd').format(session.date).toUpperCase(),
                style: const TextStyle(color: AppColors.textSlate400, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              session.sessionTypeDisplay,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textSlate900),
            ),
            const SizedBox(height: 32),

            // Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 24,
                children: [
                  _detailItem(Icons.architecture, session.equipment.bowTypeDisplay, 'Equipment'),
                  _detailItem(Icons.adjust, '${session.targetFaceSize}cm', 'Face'),
                  _detailItem(Icons.straighten, '${session.distance.toInt()}m', 'Distance'),
                  _detailItem(Icons.format_list_numbered, '${session.arrowCount} Arr', 'Volume'),
                  _detailItem(Icons.apartment, session.environmentDisplay, 'Environment'),
                  _detailItem(Icons.schedule, session.durationDisplay, 'Duration'),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
              child: Divider(color: Colors.grey.shade100, height: 1),
            ),

            // Big Score Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '${session.totalScore}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          TextSpan(text: '/${session.maxScore}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
                        ],
                      ),
                    ),
                    const Text('TOTAL SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textSlate400)),
                  ],
                ),
                Container(height: 50, width: 1, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 32)),
                Column(
                  children: [
                    Text('${session.consistency.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textSlate900)),
                    const Text('CONSISTENCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textSlate400)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // AI Advice Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text('AI Training Advice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generateAdvice(session),
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSlate500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Ends List
            if (session.ends.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ends Score', style: TextStyle(fontWeight: FontWeight.bold)),
                        StatusBadge(
                          text: '${session.ends.length} Ends',
                          color: AppColors.textSlate500,
                          backgroundColor: AppColors.backgroundLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...session.ends.map((end) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _endItem(
                            end.endNumber.toString().padLeft(2, '0'),
                            end.totalScore.toString(),
                            end.arrows.map<int>((a) => a.pointValue).toList(),
                          ),
                        )),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _generateAdvice(dynamic session) {
    final avgScore = session.averageArrowScore;
    final consistency = session.consistency;

    if (consistency > 90 && avgScore > 9) {
      return 'Outstanding performance! Your consistency (${consistency.toStringAsFixed(1)}%) and accuracy are excellent. Consider increasing distance or trying outdoor conditions to challenge yourself further.';
    } else if (consistency > 85) {
      return 'Excellent consistency at ${consistency.toStringAsFixed(1)}%. Your technique is solid. Focus on fine-tuning your aim to improve average score from ${avgScore.toStringAsFixed(1)} to 9.5+.';
    } else if (consistency < 70) {
      return 'Your consistency (${consistency.toStringAsFixed(1)}%) shows room for improvement. Focus on maintaining consistent anchor point, release, and follow-through. Consider blank bale practice to refine form.';
    } else {
      return 'Good session with ${consistency.toStringAsFixed(1)}% consistency and ${avgScore.toStringAsFixed(1)} average score. Continue practicing form fundamentals and breathing control for better results.';
    }
  }

  Widget _detailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(24)),
          child: Icon(icon, color: AppColors.textSlate400, size: 22),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSlate900)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSlate400)),
      ],
    );
  }

  Widget _endItem(String endNum, String total, List<int> scores) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(endNum, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSlate400, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scores
                  .map((s) => Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: s >= 9 ? AppColors.backgroundLight : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: s >= 9 ? Border.all(color: AppColors.primary.withOpacity(0.2)) : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          '$s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: s >= 9 ? AppColors.primary : AppColors.textSlate500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          Text(total, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textSlate900)),
        ],
      ),
    );
  }
}
