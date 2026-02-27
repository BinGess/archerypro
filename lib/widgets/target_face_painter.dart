import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

/// Paints a WA (World Archery) compliant target face.
///
/// Coordinate system: r = distance from center / max_display_radius (0.0–1.0)
/// • Full face (isTripleFace=false): r=1.0 is the outer edge of ring 1.
/// • Triple face (isTripleFace=true): r=1.0 is the outer edge of ring 6.
///   Rings 1-5 are not shown. Display is 2× zoomed relative to full target.
///   (display_r = full_target_r * 2)
class TargetFacePainter extends CustomPainter {
  final bool isTripleFace;
  final bool isCompoundIndoor;

  const TargetFacePainter({
    required this.isTripleFace,
    this.isCompoundIndoor = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (isTripleFace) {
      _paintTripleFace(canvas, center, radius);
    } else {
      _paintFullFace(canvas, center, radius);
    }
  }

  /// Full 10-ring face.
  /// Color zones (r = fraction of full target radius):
  ///   rings 1–2  → white  (0.80–1.00)
  ///   rings 3–4  → black  (0.60–0.80)
  ///   rings 5–6  → blue   (0.40–0.60)
  ///   rings 7–8  → red    (0.20–0.40)
  ///   rings 9–10 → gold   (0.00–0.20)
  ///   10-ring boundary (touch-friendly) → kTargetTenRingBoundary
  ///   X indicator (touch-friendly) → kTargetXRingBoundary
  void _paintFullFace(Canvas canvas, Offset center, double radius) {
    // Color zones — draw outside → inside so each fills over the previous
    _fillCircle(canvas, center, radius, AppColors.targetWhite); // rings 1–2
    _fillCircle(
        canvas, center, radius * 0.80, AppColors.targetBlack); // rings 3–4
    _fillCircle(
        canvas, center, radius * 0.60, AppColors.targetBlue); // rings 5–6
    _fillCircle(
        canvas, center, radius * 0.40, AppColors.targetRed); // rings 7–8
    _fillCircle(
        canvas, center, radius * 0.20, AppColors.targetGold); // rings 9–10

    // Crosshair
    _drawCrosshair(canvas, center, radius);

    // Ring dividers. We intentionally enlarge the visual X/10 split for mobile UX.
    const ringFractions = <double>[
      kTargetTenRingBoundary,
      0.20,
      0.30,
      0.40,
      0.50,
      0.60,
      0.70,
      0.80,
      0.90,
      1.00,
    ];
    for (final frac in ringFractions) {
      final isZoneBoundary = frac == 0.20 ||
          frac == 0.40 ||
          frac == 0.60 ||
          frac == 0.80 ||
          frac == 1.00;
      _strokeCircle(
        canvas,
        center,
        radius * frac,
        isZoneBoundary
            ? Colors.black.withOpacity(0.28)
            : Colors.black.withOpacity(0.16),
        isZoneBoundary ? 1.2 : 0.7,
      );
    }

    // X ring indicator (subtle)
    _strokeCircle(
      canvas,
      center,
      radius * kTargetXRingBoundary,
      Colors.black.withOpacity(0.35),
      0.7,
    );

    // Compound indoor inner-10 boundary highlight
    if (isCompoundIndoor) {
      _strokeCircle(
        canvas,
        center,
        radius * kTargetTenRingBoundary,
        AppColors.primary.withOpacity(0.80),
        2.0,
      );
    }
  }

  /// Triple (6-ring) face.
  /// Display maps the inner 50% of the full target (rings 6–10 only).
  /// Display fractions relative to triple display radius:
  ///   ring 6  → 0.80–1.00 → blue
  ///   ring 7  → 0.60–0.80 → red
  ///   ring 8  → 0.40–0.60 → red
  ///   ring 9  → 0.20–0.40 → gold
  ///   ring 10 boundary uses (kTargetTenRingBoundary * 2)
  ///   X boundary uses (kTargetXRingBoundary * 2)
  void _paintTripleFace(Canvas canvas, Offset center, double radius) {
    final tenBoundary = kTargetTenRingBoundary * 2;
    final xBoundary = kTargetXRingBoundary * 2;

    // Color zones — draw outside → inside
    _fillCircle(canvas, center, radius, AppColors.targetBlue); // ring 6
    _fillCircle(
        canvas, center, radius * 0.80, AppColors.targetRed); // rings 7–8
    _fillCircle(
        canvas, center, radius * 0.40, AppColors.targetGold); // rings 9–10 + X

    // Crosshair
    _drawCrosshair(canvas, center, radius);

    // Ring dividers
    // Outer edge (ring 6 boundary)
    _strokeCircle(canvas, center, radius, Colors.black.withOpacity(0.28), 1.2);
    // ring 7–6 boundary (zone boundary → bold)
    _strokeCircle(
        canvas, center, radius * 0.80, Colors.black.withOpacity(0.28), 1.2);
    // ring 8–7 boundary (within red zone → thin)
    _strokeCircle(
        canvas, center, radius * 0.60, Colors.black.withOpacity(0.16), 0.7);
    // ring 9–8 boundary (zone boundary → bold)
    _strokeCircle(
        canvas, center, radius * 0.40, Colors.black.withOpacity(0.28), 1.2);
    // ring 10–9 boundary (within gold zone → thin, touch-friendly)
    _strokeCircle(canvas, center, radius * tenBoundary,
        Colors.black.withOpacity(0.16), 0.7);
    // X boundary
    _strokeCircle(canvas, center, radius * xBoundary,
        Colors.black.withOpacity(0.35), 0.7);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _fillCircle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  void _strokeCircle(
      Canvas canvas, Offset center, double radius, Color color, double width) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = width,
    );
  }

  void _drawCrosshair(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 0.7;
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), paint);
  }

  @override
  bool shouldRepaint(covariant TargetFacePainter oldDelegate) =>
      oldDelegate.isTripleFace != isTripleFace ||
      oldDelegate.isCompoundIndoor != isCompoundIndoor;
}
