import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TargetFacePainter extends CustomPainter {
  final int targetFaceSize;
  final bool useSixRingFace;

  TargetFacePainter({
    required this.targetFaceSize,
    bool? useSixRingFace,
  }) : useSixRingFace = useSixRingFace ?? targetFaceSize == 40;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Render different target faces based on size
    if (targetFaceSize == 40 && useSixRingFace) {
      // 40cm target: 6-ring face (rings 6-10 only)
      // Blue outer ring (6-7)
      _drawRing(canvas, center, radius, AppColors.targetBlue);
      // Red ring (8-9)
      _drawRing(canvas, center, radius * 0.67, AppColors.targetRed);
      // Yellow/Gold center (10-X)
      _drawRing(canvas, center, radius * 0.33, AppColors.targetGold);
      // X Ring
      canvas.drawCircle(center, radius * 0.08, Paint()..color = Colors.black.withOpacity(0.15));
    } else {
      // 60cm, 80cm, 122cm: Full 10-ring target
      // White outer ring (1-2)
      _drawRing(canvas, center, radius, AppColors.targetWhite);
      // Black ring (3-4)
      _drawRing(canvas, center, radius * 0.8, AppColors.targetBlack);
      // Blue ring (5-6)
      _drawRing(canvas, center, radius * 0.6, AppColors.targetBlue);
      // Red ring (7-8)
      _drawRing(canvas, center, radius * 0.4, AppColors.targetRed);
      // Yellow/Gold center (9-10)
      _drawRing(canvas, center, radius * 0.2, AppColors.targetGold);
      // X Ring
      canvas.drawCircle(center, radius * 0.05, Paint()..color = Colors.black.withOpacity(0.15));
    }
  }

  void _drawRing(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
    // Divider line
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is TargetFacePainter &&
        (oldDelegate.targetFaceSize != targetFaceSize || oldDelegate.useSixRingFace != useSixRingFace);
  }
}
