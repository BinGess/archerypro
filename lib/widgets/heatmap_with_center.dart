import 'package:flutter/material.dart';
import 'target_face_painter.dart';
import '../theme/app_colors.dart';

/// Heatmap widget displaying arrow positions with geometric center marker
/// Used in training session details page for visualizing shot grouping.
///
/// Arrow positions are stored in FULL-TARGET normalized coordinates (-1.0 to
/// 1.0 where 1.0 = outer edge of ring 1). For triple face sessions the
/// positions are in the 0–0.5 range (inner 50% of the full target).
class HeatmapWithCenter extends StatelessWidget {
  /// Arrow positions in full-target normalized coordinates (-1.0 to 1.0).
  final List<Offset> arrowPositions;

  /// Geometric center (centroid) in full-target normalized coordinates.
  final Offset? geometricCenter;

  /// Target face size in cm (used to determine face type if not overridden).
  final int targetFaceSize;

  /// When true, renders a 6-ring triple face (rings 6-10 only) and scales
  /// arrow positions accordingly (2× because the display is zoomed 2×).
  final bool isTripleFace;

  /// When true, highlights the compound inner-10 boundary on the target.
  final bool isCompoundIndoor;

  /// Size of the widget in logical pixels.
  final double size;

  /// Whether to show the geometric center crosshair marker.
  final bool showCenter;

  const HeatmapWithCenter({
    super.key,
    required this.arrowPositions,
    this.geometricCenter,
    required this.targetFaceSize,
    this.isTripleFace = false,
    this.isCompoundIndoor = false,
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
          isTripleFace: isTripleFace,
          isCompoundIndoor: isCompoundIndoor,
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
  final bool isTripleFace;
  final bool isCompoundIndoor;
  final bool showCenter;

  _HeatmapPainter({
    required this.arrowPositions,
    required this.geometricCenter,
    required this.isTripleFace,
    required this.isCompoundIndoor,
    required this.showCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw target face first
    TargetFacePainter(
      isTripleFace: isTripleFace,
      isCompoundIndoor: isCompoundIndoor,
    ).paint(canvas, size);

    // For triple face the display is 2× zoomed, so we multiply pos by 2×
    // to get the display-canvas position.
    final double posScale = isTripleFace ? radius * 2.0 : radius;

    // Draw arrow impact points
    final arrowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final normalizedPos in arrowPositions) {
      final canvasX = center.dx + normalizedPos.dx * posScale;
      final canvasY = center.dy + normalizedPos.dy * posScale;

      canvas.drawCircle(Offset(canvasX, canvasY), 4.0, arrowPaint);

      // White border for visibility
      canvas.drawCircle(
        Offset(canvasX, canvasY),
        4.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Geometric center crosshair
    if (showCenter && geometricCenter != null) {
      final centerCanvasX = center.dx + geometricCenter!.dx * posScale;
      final centerCanvasY = center.dy + geometricCenter!.dy * posScale;
      final centerPoint = Offset(centerCanvasX, centerCanvasY);

      final centerPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(centerPoint.dx - 12, centerPoint.dy),
          Offset(centerPoint.dx + 12, centerPoint.dy), centerPaint);
      canvas.drawLine(Offset(centerPoint.dx, centerPoint.dy - 12),
          Offset(centerPoint.dx, centerPoint.dy + 12), centerPaint);

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
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) =>
      oldDelegate.arrowPositions != arrowPositions ||
      oldDelegate.geometricCenter != geometricCenter ||
      oldDelegate.isTripleFace != isTripleFace ||
      oldDelegate.isCompoundIndoor != isCompoundIndoor ||
      oldDelegate.showCenter != showCenter;
}

/// Compact version of heatmap for use in cards
class HeatmapWithCenterCompact extends StatelessWidget {
  final List<Offset> arrowPositions;
  final Offset? geometricCenter;
  final int targetFaceSize;
  final bool isTripleFace;
  final bool isCompoundIndoor;

  const HeatmapWithCenterCompact({
    super.key,
    required this.arrowPositions,
    this.geometricCenter,
    required this.targetFaceSize,
    this.isTripleFace = false,
    this.isCompoundIndoor = false,
  });

  @override
  Widget build(BuildContext context) {
    return HeatmapWithCenter(
      arrowPositions: arrowPositions,
      geometricCenter: geometricCenter,
      targetFaceSize: targetFaceSize,
      isTripleFace: isTripleFace,
      isCompoundIndoor: isCompoundIndoor,
      size: 150.0,
      showCenter: true,
    );
  }
}
