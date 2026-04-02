# ArcheryPro UI/UX Review (2026-03-01)

## Context
- Skill used: `ui-ux-pro-max`
- Product type: sports performance analytics app (Flutter)
- Goal: unify color, typography, spacing, and reduce style fragmentation

## Style Direction (Unified)
- Visual language: clean data-focused sports analytics
- Primary palette:
  - Primary `#1E40AF`
  - Secondary `#3B82F6`
  - Accent/CTA `#F59E0B`
  - Background `#F8FAFC`
  - Text base `#0F172A`
- Typography:
  - Body: `Noto Sans SC` (cross-locale readability)
  - Numeric/stat emphasis via heavier weights and tightened letter spacing
- Spacing scale:
  - `4 / 8 / 12 / 16 / 20 / 24 / 32 / 40`
- Interaction baseline:
  - 44x44 minimum tap target for buttons
  - Consistent card radius + border + soft shadow

## High-Priority Findings
1. Theme fragmentation:
   - Multiple inline `ThemeData`/style decisions were not centralized.
2. Color inconsistency:
   - Extensive mixed `Colors.grey.*` / `Colors.black87` usage across charts and screens.
3. Typography inconsistency:
   - Dense use of ad-hoc sizes (`7/9/10/11/12/13...`) in UI and data visuals.
4. Spacing inconsistency:
   - Repeated manual paddings/margins without tokenized rhythm.

## Implemented Changes
- Added theme system:
  - `lib/theme/app_theme.dart`
  - `lib/theme/app_spacing.dart`
- Refined tokens:
  - `lib/theme/app_colors.dart`
  - `lib/theme/app_text_styles.dart`
- Wired global theme:
  - `lib/main.dart` now uses `AppTheme.lightTheme`
- Unified reusable UI primitives:
  - `lib/widgets/common_widgets.dart` (`ArcheryCard`, badge text sizing, shadow/tap behavior)
- Normalized chart visual tokens:
  - `lib/widgets/score_distribution_chart.dart`
  - `lib/widgets/score_trend_chart.dart`
  - `lib/widgets/stability_radar_chart.dart`
  - `lib/widgets/quadrant_radar_chart.dart`
  - `lib/widgets/growth_mixed_chart.dart`
  - `lib/widgets/end_trend_chart.dart`
- Applied spacing/typography tokens to dashboard:
  - `lib/screens/dashboard_screen.dart`
- Fully migrated setup/scoring flow to token system:
  - `lib/screens/scoring_screen.dart`
  - `lib/screens/session_setup_screen.dart`

## Remaining Inconsistencies (Backlog)
- Still has low-size text or hardcoded greys:
  - `lib/screens/competition_screen.dart`
  - `lib/screens/dashboard_screen_with_logic.dart`
  - `lib/widgets/competition/competition_setup_sheet.dart`
  - `lib/widgets/ai_coach/ai_source_badge.dart`

## Validation
- `flutter analyze` result:
  - No `error`
  - Existing `warning/info` remain in unrelated areas; tracked separately.
