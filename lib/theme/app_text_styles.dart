import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text style constants for ArcheryPro.
/// All screens should use these instead of inline TextStyle definitions.
class AppTextStyles {
  AppTextStyles._();

  // ── AppBar / Page Titles ──────────────────────────────────────────────────
  /// Primary page title used in AppBar (17sp, w800)
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textSlate900,
    letterSpacing: 0,
  );

  // ── Section Headers ───────────────────────────────────────────────────────
  /// Grouped-list section header, e.g. "语言设置" (13sp, w700, muted)
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textSlate500,
    letterSpacing: 0.4,
  );

  /// Card section title, e.g. "器材设置" with icon (15sp, w700)
  static const TextStyle cardSectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textSlate900,
  );

  // ── Body / Row Labels ─────────────────────────────────────────────────────
  /// Primary list-row label (15sp, w600)
  static const TextStyle rowLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textSlate900,
  );

  /// Secondary body text / descriptions (14sp, w500)
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSlate700,
  );

  /// Muted sub-label below row titles (13sp, w500)
  static const TextStyle subLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSlate500,
  );

  // ── Captions / Tags ───────────────────────────────────────────────────────
  /// Small uppercase caption, e.g. metric labels (11sp, w700, letterSpacing)
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSlate400,
    letterSpacing: 0.8,
  );

  /// Even smaller micro-label (10sp, w700)
  static const TextStyle micro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textSlate400,
    letterSpacing: 0.5,
  );

  // ── Numeric Displays ──────────────────────────────────────────────────────
  /// Hero score number, e.g. total session score (48sp, w900)
  static const TextStyle heroNumber = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: AppColors.primary,
    height: 1.0,
  );

  /// Large stat number on dashboard / cards (32sp, w900)
  static const TextStyle largeNumber = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.0,
  );

  /// Medium stat number (24sp, w900)
  static const TextStyle mediumNumber = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1.0,
  );

  /// Inline fraction denominator (18sp, w700, muted)
  static const TextStyle numberDenominator = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textSlate400,
  );

  // ── Navigation Bar ────────────────────────────────────────────────────────
  static const TextStyle navSelected = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle navUnselected = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // ── Buttons ───────────────────────────────────────────────────────────────
  static const TextStyle primaryButton = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
