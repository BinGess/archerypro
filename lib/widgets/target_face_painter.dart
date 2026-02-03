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
      // The face is cut at the 6-ring boundary (20cm diameter).
      // Ratios relative to this boundary (10cm radius):
      // 10 ring (2cm rad) = 0.2
      // 9 ring (4cm rad) = 0.4
      // 8 ring (6cm rad) = 0.6
      // 7 ring (8cm rad) = 0.8
      // 6 ring (10cm rad) = 1.0
      
      // Blue ring (6)
      _drawRing(canvas, center, radius, AppColors.targetBlue);
      
      // Red rings (7-8)
      _drawRing(canvas, center, radius * 0.8, AppColors.targetRed);
      _drawRing(canvas, center, radius * 0.6, AppColors.targetRed);
      
      // Gold rings (9-10)
      _drawRing(canvas, center, radius * 0.4, AppColors.targetGold);
      _drawRing(canvas, center, radius * 0.2, AppColors.targetGold);
      
      // X Ring (Inner 10 - 1cm rad = 0.1)
      canvas.drawCircle(center, radius * 0.1, Paint()..color = Colors.black.withOpacity(0.15));
      canvas.drawCircle(
        center, 
        radius * 0.1, 
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black.withOpacity(0.2)
          ..strokeWidth = 1.0
      );
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
