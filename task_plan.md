# Task Plan: Archery Target Face & Scoring System Rewrite

## Goal
Reimplement the target face drawing and scoring logic to comply with World Archery (WA) standards as described in the PRD.

## Phases

### Phase 1 — Analysis ✅
- Read current `target_face_painter.dart` → proportions correct but `useSixRingFace` condition REVERSED
- Read `scoring_screen.dart` → scoring logic has 3 critical bugs
- Read `arrow.dart` / `end.dart` → model is fine (isX, pointValue=10 for X)

### Phase 2 — Rewrite TargetFacePainter ✅ (also updated `heatmap_with_center.dart` + `details_screen.dart`)
Files: `lib/widgets/target_face_painter.dart`
- New params: `isTripleFace` (bool), `isCompoundIndoor` (bool)
- Full 10-ring face: 5 color zones + individual ring dividers at every 0.1R + X at 0.05R + crosshair
- Triple 6-ring face: Blue(ring6) → Red(7-8) → Gold(9-10) + dividers + X at 0.1*display + crosshair
- Compound indoor indicator: highlight the inner10 boundary circle in AppColors.primary

### Phase 3 — Fix Scoring Logic ✅
Files: `lib/screens/scoring_screen.dart`
- Fixed `isTripleFace`: `targetFaceSize == 40 && bowType != BowType.compound`
- Fixed `isCompoundIndoor`: `bowType == BowType.compound`
- Added `_calcScore(r, isTripleFace, isCompoundIndoor)` with PRD table + 0.01 line tolerance
- For triple face: rFull = rDisplay * 0.5 (maps display coords to full-target coords)
- For compound indoor: 0.05 < r ≤ 0.10 + tol → score 9, not 10

### Phase 4 — Fix Arrow Marker Display ✅
Files: `lib/screens/scoring_screen.dart`
- Arrow positions stored in full-target normalized coords (-1 to 1)
- Full face: markerOffset = center + pos * 140 (keeps inside bounds)
- Triple face: markerOffset = center + pos * 280 (= 140 * 2.0 scale)
- Score label shown inside the marker dot
- Position normalization fixed: triple face stores pos * 0.5 (full-target coords)

### Phase 5 — Add Magnifier ✅
Files: `lib/screens/scoring_screen.dart`
- Switched from `onTapDown` to `Listener` (onPointerDown/Move/Up)
- On press: show 120×120 magnifier widget above finger (2× zoom via ClipOval + Transform)
- On release: commit the score via `_handleTargetTap`
- Magnifier clamped to stay within 300×300 Stack bounds

## Decisions
- `useSixRingFace` → renamed to `isTripleFace` throughout
- Triple face = 40cm + recurve/barebow/longbow (NOT compound)
- Compound indoor = 40cm/60cm + BowType.compound → inner10 scoring
- Line tolerance = 0.01R (round UP at boundaries)
- Arrow score X = stored as 11, pointValue = 10, displayed as "X"
- Compound 10-ring zone → stored as 9 (not 11/X, not 10)
