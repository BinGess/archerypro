import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  bool isTargetView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Real-time Scoring', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () {}),
        actions: [IconButton(icon: const Icon(Icons.analytics_outlined), onPressed: () {})],
      ),
      body: Column(
        children: [
          // Header Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildHeaderStat('CURRENT END', '4', '/10', Colors.white, AppColors.textSlate900)),
                const SizedBox(width: 12),
                Expanded(child: _buildHeaderStat('TOTAL SCORE', '284', '', AppColors.primary, Colors.white)),
              ],
            ),
          ),
          
          // Toggle
          Container(
            height: 44,
            width: 260,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildToggleBtn('Target View', Icons.track_changes, isTargetView, () => setState(() => isTargetView = true)),
                _buildToggleBtn('Grid View', Icons.grid_view, !isTargetView, () => setState(() => isTargetView = false)),
              ],
            ),
          ),
          
          Expanded(
            child: isTargetView ? _buildTargetView() : _buildGridView(),
          ),
          
          if (!isTargetView) _buildKeypad(),
          if (isTargetView) _buildTargetFooter(),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, String sub, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text.withOpacity(0.6))),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: text)),
                TextSpan(text: " $sub", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? AppColors.primary : AppColors.textSlate500),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? AppColors.primary : AppColors.textSlate500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current End
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('END 4 RECORD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('27 pts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _scoreBox(10, AppColors.targetGold, Colors.black),
                  _scoreBox(9, AppColors.targetGold, Colors.black),
                  _scoreBox(8, AppColors.targetRed, Colors.white),
                  _emptyScoreBox(),
                  _emptyScoreBox(),
                  _emptyScoreBox(),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text('HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate400, letterSpacing: 1.5))),
        ),
        _buildHistoryRow('END 3', '54', [10, 9, 9, 9, 9, 8]),
        const SizedBox(height: 12),
        _buildHistoryRow('END 2', '52', [9, 9, 9, 9, 8, 8]),
      ],
    );
  }

  Widget _buildTargetView() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Mini score strip
           Container(
             margin: const EdgeInsets.symmetric(horizontal: 20),
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _scoreBoxSmall(10, AppColors.targetGold),
                 _scoreBoxSmall(9, AppColors.targetGold),
                 _scoreBoxSmall(8, AppColors.targetRed),
                 _scoreBoxSmallEmpty(),
                 _scoreBoxSmallEmpty(),
                 _scoreBoxSmallEmpty(),
               ],
             ),
           ),
           const SizedBox(height: 20),
           // Target Face
           SizedBox(
             width: 320, height: 320,
             child: CustomPaint(
               painter: TargetFacePainter(),
               child: Stack(
                 children: [
                    _arrowMarker(150, 140),
                    _arrowMarker(170, 160),
                    _arrowMarker(160, 150),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }
  
  Widget _arrowMarker(double top, double left) {
    return Positioned(
      top: top, left: left,
      child: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.3,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _keypadBtn('X', Colors.orange, isText: true),
          _keypadBtn('10', AppColors.textSlate900),
          _keypadBtn('9', AppColors.textSlate900),
          _iconKeypadBtn(Icons.backspace, 'Remove'),
          _keypadBtn('8', AppColors.textSlate900),
          _keypadBtn('7', AppColors.textSlate900),
          _keypadBtn('6', AppColors.textSlate900),
          _keypadBtn('5', AppColors.textSlate900),
          _keypadBtn('4', AppColors.textSlate900),
          _keypadBtn('3', AppColors.textSlate900),
          _saveBtn(),
          _keypadBtn('2', AppColors.textSlate900),
          _keypadBtn('1', AppColors.textSlate900),
          _keypadBtn('M', Colors.red, isText: true),
        ],
      ),
    );
  }
  
  Widget _buildTargetFooter() {
     return Container(
       padding: const EdgeInsets.all(20),
       color: Colors.white,
       child: Row(
         children: [
           Expanded(
             child: ElevatedButton.icon(
               onPressed: (){},
               icon: const Icon(Icons.close, color: AppColors.textSlate500),
               label: const Text('REMOVE', style: TextStyle(color: AppColors.textSlate500, fontWeight: FontWeight.bold)),
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.grey.shade100,
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 elevation: 0,
               ),
             ),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: ElevatedButton.icon(
               onPressed: (){},
               icon: const Icon(Icons.save, color: Colors.white),
               label: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.primary,
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 elevation: 4,
                 shadowColor: AppColors.primary.withOpacity(0.4),
               ),
             ),
           ),
         ],
       ),
     );
  }

  Widget _keypadBtn(String text, Color color, {bool isText = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 2))]),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
    );
  }

  Widget _iconKeypadBtn(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, color: AppColors.textSlate500), Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSlate500))],
      ),
    );
  }
  
  Widget _saveBtn() {
    return Container(
      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(Icons.check_circle, color: Colors.white, size: 28), Text('SAVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white))],
      ),
    );
  }

  Widget _scoreBox(int score, Color bg, Color text) {
    return Container(
      width: 48, height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)]),
      child: Text('$score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: text)),
    );
  }
  
  Widget _scoreBoxSmall(int score, Color bg) {
    return Container(
      width: 32, height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text('$score', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
  Widget _scoreBoxSmallEmpty() => Container(width: 32, height: 32, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(6)));

  Widget _emptyScoreBox() {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200, width: 2)),
    );
  }

  Widget _buildHistoryRow(String end, String total, List<int> scores) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(end, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSlate500)), Text(total, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textSlate400))],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: scores.map((s) => Container(
              width: 40, height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
              child: Text('$s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSlate500)),
            )).toList(),
          )
        ],
      ),
    );
  }
}

class TargetFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Rings
    _drawRing(canvas, center, radius, AppColors.targetWhite);
    _drawRing(canvas, center, radius * 0.8, AppColors.targetBlack);
    _drawRing(canvas, center, radius * 0.6, AppColors.targetBlue);
    _drawRing(canvas, center, radius * 0.4, AppColors.targetRed);
    _drawRing(canvas, center, radius * 0.2, AppColors.targetGold);
    
    // X Ring
    canvas.drawCircle(center, radius * 0.02, Paint()..color = Colors.black.withOpacity(0.2));
  }
  
  void _drawRing(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
    // Divider line
    canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..color = Colors.black12..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
