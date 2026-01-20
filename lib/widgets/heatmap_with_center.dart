import 'package:flutter/material.dart';
import 'target_face_painter.dart';
import '../theme/app_colors.dart';

/// Heatmap widget displaying arrow positions with geometric center marker
/// Used in training session details page for visualizing shot grouping
class HeatmapWithCenter extends StatelessWidget {
  /// List of arrow positions in normalized coordinates (-1.0 to 1.0)
  final List<Offset> arrowPositions;

  /// Geometric center point (centroid) in normalized coordinates
  final Offset? geometricCenter;

  /// Target face size in centimeters
  final int targetFaceSize;

  /// Size of the widget
  final double size;

  /// Whether to show the geometric center marker
  final bool showCenter;

  const HeatmapWithCenter({
    super.key,
    required this.arrowPositions,
    this.geometricCenter,
    required this.targetFaceSize,
    this.size = 300.0,
    this.showCenter = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HeatmapPainter(
          arrowPositions: arrowPositions,
          geometricCenter: geometricCenter,
          targetFaceSize: targetFaceSize,
          showCenter: showCenter,
        ),
      ),
    );
  }
}

/// Custom painter for heatmap with center marker
class _HeatmapPainter extends CustomPainter {
  final List<Offset> arrowPositions;
  final Offset? geometricCenter;
  final int targetFaceSize;
  final bool showCenter;

  _HeatmapPainter({
    required this.arrowPositions,
    required this.geometricCenter,
    required this.targetFaceSize,
    required this.showCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw target face first
    final targetPainter = TargetFacePainter(targetFaceSize: targetFaceSize);
    targetPainter.paint(canvas, size);

    // Draw arrow impact points
    final arrowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final normalizedPos in arrowPositions) {
      // Convert normalized coordinates (-1.0 to 1.0) to canvas coordinates
      final canvasX = center.dx + (normalizedPos.dx * radius);
      final canvasY = center.dy + (normalizedPos.dy * radius);

      // Draw arrow impact point
      canvas.drawCircle(
        Offset(canvasX, canvasY),
        4.0, // Arrow dot radius
        arrowPaint,
      );

      // Draw white border for better visibility
      canvas.drawCircle(
        Offset(canvasX, canvasY),
        4.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Draw geometric center marker if enabled and available
    if (showCenter && geometricCenter != null) {
      final centerCanvasX = center.dx + (geometricCenter!.dx * radius);
      final centerCanvasY = center.dy + (geometricCenter!.dy * radius);
      final centerPoint = Offset(centerCanvasX, centerCanvasY);

      // Draw crosshair marker for geometric center
      final centerPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      // Horizontal line
      canvas.drawLine(
        Offset(centerPoint.dx - 12, centerPoint.dy),
        Offset(centerPoint.dx + 12, centerPoint.dy),
        centerPaint,
      );

      // Vertical line
      canvas.drawLine(
        Offset(centerPoint.dx, centerPoint.dy - 12),
        Offset(centerPoint.dx, centerPoint.dy + 12),
        centerPaint,
      );

      // Center circle
      canvas.drawCircle(
        centerPoint,
        5.0,
        Paint()
          ..color = Colors.red.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        centerPoint,
        5.0,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.arrowPositions != arrowPositions ||
        oldDelegate.geometricCenter != geometricCenter ||
        oldDelegate.targetFaceSize != targetFaceSize ||
        oldDelegate.showCenter != showCenter;
  }
}

/// Compact version of heatmap for use in cards
class HeatmapWithCenterCompact extends StatelessWidget {
  final List<Offset> arrowPositions;
  final Offset? geometricCenter;
  final int targetFaceSize;

  const HeatmapWithCenterCompact({
    super.key,
    required this.arrowPositions,
    this.geometricCenter,
    required this.targetFaceSize,
  });

  @override
  Widget build(BuildContext context) {
    return HeatmapWithCenter(
      arrowPositions: arrowPositions,
      geometricCenter: geometricCenter,
      targetFaceSize: targetFaceSize,
      size: 150.0,
      showCenter: true,
    );
  }
}
