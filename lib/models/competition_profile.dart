import 'training_session.dart';
import 'equipment.dart';

/// Competition profile for qualification-style analysis.
class CompetitionProfile {
  final String key;
  final String nameZh;
  final String nameEn;
  final String nameJa;
  final int projectionArrows;
  final List<TierThreshold> _tierThresholds;

  const CompetitionProfile({
    required this.key,
    required this.nameZh,
    required this.nameEn,
    required this.nameJa,
    required this.projectionArrows,
    required List<TierThreshold> tierThresholds,
  }) : _tierThresholds = tierThresholds;

  static const CompetitionProfile recurveOutdoor70 = CompetitionProfile(
    key: 'recurveOutdoor70',
    nameZh: '反曲弓 70m（72箭）',
    nameEn: 'Recurve 70m (72 arrows)',
    nameJa: 'リカーブ 70m（72射）',
    projectionArrows: 72,
    tierThresholds: [
      TierThreshold('Purple', 680),
      TierThreshold('Gold', 640),
      TierThreshold('Red', 600),
      TierThreshold('Blue', 560),
      TierThreshold('Black', 520),
      TierThreshold('White', 0),
    ],
  );

  static const CompetitionProfile compoundOutdoor50 = CompetitionProfile(
    key: 'compoundOutdoor50',
    nameZh: '复合弓 50m（72箭）',
    nameEn: 'Compound 50m (72 arrows)',
    nameJa: 'コンパウンド 50m（72射）',
    projectionArrows: 72,
    tierThresholds: [
      TierThreshold('Purple', 705),
      TierThreshold('Gold', 690),
      TierThreshold('Red', 670),
      TierThreshold('Blue', 640),
      TierThreshold('Black', 600),
      TierThreshold('White', 0),
    ],
  );

  static const CompetitionProfile indoor18 = CompetitionProfile(
    key: 'indoor18',
    nameZh: '室内 18m（60箭）',
    nameEn: 'Indoor 18m (60 arrows)',
    nameJa: 'インドア 18m（60射）',
    projectionArrows: 60,
    tierThresholds: [
      TierThreshold('Purple', 570),
      TierThreshold('Gold', 550),
      TierThreshold('Red', 525),
      TierThreshold('Blue', 495),
      TierThreshold('Black', 450),
      TierThreshold('White', 0),
    ],
  );

  static const CompetitionProfile generic = CompetitionProfile(
    key: 'generic',
    nameZh: '通用资格赛投影（72箭）',
    nameEn: 'Generic Qualification Projection (72 arrows)',
    nameJa: '標準予選換算（72射）',
    projectionArrows: 72,
    tierThresholds: [
      TierThreshold('Purple', 680),
      TierThreshold('Gold', 640),
      TierThreshold('Red', 600),
      TierThreshold('Blue', 560),
      TierThreshold('Black', 520),
      TierThreshold('White', 0),
    ],
  );

  static const List<CompetitionProfile> values = [
    recurveOutdoor70,
    compoundOutdoor50,
    indoor18,
    generic,
  ];

  String displayName(String languageCode) =>
      switch (languageCode) {
        'zh' => nameZh,
        'ja' => nameJa,
        _ => nameEn,
      };

  String tierForProjection(double projectedScore) {
    for (final threshold in _tierThresholds) {
      if (projectedScore >= threshold.minScore) {
        return threshold.tier;
      }
    }
    return 'White';
  }

  static CompetitionProfile fromSession(TrainingSession session) {
    final distance = session.distance;
    final isIndoor = session.environment == EnvironmentType.indoor;
    final bowType = session.equipment.bowType;

    if (isIndoor && distance <= 20) {
      return indoor18;
    }

    if (!isIndoor && bowType == BowType.recurve && distance >= 65) {
      return recurveOutdoor70;
    }

    if (!isIndoor && bowType == BowType.compound && distance >= 45) {
      return compoundOutdoor50;
    }

    return generic;
  }

  static CompetitionProfile fromSessions(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return generic;

    final counts = <String, int>{};
    for (final session in sessions) {
      final key = fromSession(session).key;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final dominantKey =
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return values.firstWhere(
      (profile) => profile.key == dominantKey,
      orElse: () => generic,
    );
  }
}

class TierThreshold {
  final String tier;
  final double minScore;

  const TierThreshold(this.tier, this.minScore);
}
