import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Training Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: Row(children: [const Icon(Icons.chevron_left, color: AppColors.primary), const Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))]),
        leadingWidth: 80,
        actions: [
           TextButton(onPressed: (){}, child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
           IconButton(onPressed: (){}, icon: const Icon(Icons.share, size: 20, color: AppColors.primary)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 4),
              child: Text('2023 OCT 24', style: TextStyle(color: AppColors.textSlate400, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const Text('Regular Training', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textSlate900)),
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
                  _detailItem(Icons.architecture, 'Compound', 'Equipment'),
                  _detailItem(Icons.adjust, '40cm', 'Face'),
                  _detailItem(Icons.straighten, '18m', 'Distance'),
                  _detailItem(Icons.format_list_numbered, '60 Arr', 'Volume'),
                  _detailItem(Icons.apartment, 'Indoor', 'Environment'),
                  _detailItem(Icons.schedule, '1:15h', 'Duration'),
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
                    RichText(text: const TextSpan(children: [
                      TextSpan(text: '590', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      TextSpan(text: '/600', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSlate400)),
                    ])),
                    const Text('TOTAL SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textSlate400)),
                  ],
                ),
                Container(height: 50, width: 1, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 32)),
                const Column(
                  children: [
                    Text('98.3%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textSlate900)),
                    Text('CONSISTENCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textSlate400)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // AI Advice Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    const Text('AI Training Advice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Release execution is extremely consistent. Suggest increasing distance to 30m next session and focusing on breath control.', style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSlate500)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Ends List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Ends Score', style: TextStyle(fontWeight: FontWeight.bold)),
                    StatusBadge(text: '20 Ends', color: AppColors.textSlate500, backgroundColor: AppColors.backgroundLight),
                  ]),
                  const SizedBox(height: 16),
                  _endItem('01', '29', [10, 10, 9]),
                  const SizedBox(height: 8),
                  _endItem('02', '30', [10, 10, 10]),
                  const SizedBox(height: 8),
                  _endItem('03', '28', [10, 9, 9]),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text(endNum, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSlate400, fontSize: 12))),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: scores.map((s) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 32, height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s == 10 ? AppColors.backgroundLight : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: s == 10 ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
                ),
                child: Text('$s', style: TextStyle(fontWeight: FontWeight.bold, color: s == 10 ? AppColors.primary : AppColors.textSlate500)),
              )).toList(),
            ),
          ),
          Text(total, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textSlate900)),
        ],
      ),
    );
  }
}
