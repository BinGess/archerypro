import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text style constants for ArcheryPro.
/// All screens should use these instead of inline TextStyle definitions.
class AppTextStyles {
  AppTextStyles._();

  // ── AppBar / Page Titles ──────────────────────────────────────────────────
  /// Primary page title used in AppBar
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textSlate900,
    letterSpacing: 0,
  );

  // ── Section Headers ───────────────────────────────────────────────────────
  /// Grouped-list section header
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSlate500,
    letterSpacing: 0.35,
  );

  /// Card section title
  static const TextStyle cardSectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textSlate900,
  );

  // ── Body / Row Labels ─────────────────────────────────────────────────────
  /// Primary list-row label
  static const TextStyle rowLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSlate900,
    height: 1.25,
  );

  /// Secondary body text / descriptions
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSlate700,
    height: 1.5,
  );

  /// Muted sub-label below row titles
  static const TextStyle subLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSlate500,
    height: 1.4,
  );

  // ── Captions / Tags ───────────────────────────────────────────────────────
  /// Small uppercase caption, e.g. metric labels
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSlate400,
    letterSpacing: 0.3,
  );

  /// Micro-label for dense data visuals
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSlate400,
    letterSpacing: 0.2,
  );

  // ── Numeric Displays ──────────────────────────────────────────────────────
  /// Hero score number, e.g. total session score
  static const TextStyle heroNumber = TextStyle(
    fontSize: 46,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.0,
    letterSpacing: -0.5,
  );

  /// Large stat number on dashboard / cards
  static const TextStyle largeNumber = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.4,
  );

  /// Medium stat number
  static const TextStyle mediumNumber = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.2,
  );

  /// Inline fraction denominator
  static const TextStyle numberDenominator = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textSlate400,
  );

  // ── Navigation Bar ────────────────────────────────────────────────────────
  static const TextStyle navSelected = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle navUnselected = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // ── Buttons ───────────────────────────────────────────────────────────────
  static const TextStyle primaryButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
