import 'package:archery_tracker/models/arrow.dart';
import 'package:archery_tracker/models/end.dart';
import 'package:archery_tracker/models/equipment.dart';
import 'package:archery_tracker/models/training_session.dart';
import 'package:archery_tracker/services/analytics_service.dart';
import 'package:archery_tracker/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

Arrow _arrow(int score, double dx, double dy, String id) {
  return Arrow.fromScore(
    id: id,
    score: score,
    position: Offset(dx, dy),
  );
}

End _end(int number, List<Arrow> arrows) {
  return End(
    id: 'end-$number-${arrows.length}',
    endNumber: number,
    maxArrows: 6,
    arrows: arrows,
  );
}

TrainingSession _session({
  required String id,
  required DateTime date,
  required List<End> ends,
}) {
  return TrainingSession(
    id: id,
    date: date,
    equipment: const Equipment(bowType: BowType.recurve),
    distance: 70,
    targetFaceSize: 122,
    environment: EnvironmentType.outdoor,
    ends: ends,
  );
}

void main() {
  test('calculates competition readiness and band bias metrics', () {
    final service = AnalyticsService();
    final date = DateTime(2026, 3, 1, 10);

    final sessionA = _session(
      id: 's-a',
      date: date,
      ends: [
        _end(
          1,
          [
            _arrow(11, -0.10, -0.10, 'a1'),
            _arrow(10, -0.12, -0.08, 'a2'),
            _arrow(9, -0.15, -0.09, 'a3'),
            _arrow(8, 0.10, -0.10, 'a4'),
            _arrow(7, 0.12, -0.08, 'a5'),
            _arrow(6, 0.08, 0.11, 'a6'),
          ],
        ),
      ],
    );

    final sessionB = _session(
      id: 's-b',
      date: date.add(const Duration(hours: 3)),
      ends: [
        _end(
          1,
          [
            _arrow(10, -0.09, -0.08, 'b1'),
            _arrow(9, -0.11, -0.10, 'b2'),
            _arrow(8, 0.10, -0.11, 'b3'),
            _arrow(7, 0.11, -0.09, 'b4'),
            _arrow(6, 0.09, 0.10, 'b5'),
            _arrow(0, 0.12, 0.12, 'b6'),
          ],
        ),
      ],
    );

    final stats = service.calculateStatistics(
      sessions: [sessionA, sessionB],
      period: kPeriodAll,
    );

    expect(stats.competitionProfileKey, 'recurveOutdoor70');
    expect(stats.projectedQualificationScore,
        closeTo(stats.avgArrowScore * 72, 0.001));

    expect(stats.tenRingRate, closeTo(3 / 12 * 100, 0.001));
    expect(stats.xRate, closeTo(1 / 12 * 100, 0.001));
    expect(stats.highValueRate, closeTo(5 / 12 * 100, 0.001));
    expect(stats.missRate, closeTo(1 / 12 * 100, 0.001));

    final day = DateTime(2026, 3, 1);
    expect(stats.dailyArrowVolumeData[day], 12);

    final highBand = stats.biasByScoreBand['high']!;
    final midBand = stats.biasByScoreBand['mid']!;
    final lowBand = stats.biasByScoreBand['low']!;

    expect(highBand['top-left'], 5);
    expect(midBand['top-right'], 4);
    expect(lowBand['bottom-right'], 3);
  });
}
