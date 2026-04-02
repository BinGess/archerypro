import 'package:archery_tracker/models/equipment.dart';
import 'package:archery_tracker/providers/scoring_provider.dart';
import 'package:archery_tracker/services/scoring_service.dart';
import 'package:archery_tracker/services/session_service.dart';
import 'package:archery_tracker/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ScoringNotifier notifier;

  setUp(() {
    notifier = ScoringNotifier(
      ScoringService(),
      SessionService(StorageService()),
    );
    notifier.startNewSession(
      equipment: const Equipment(
        bowType: BowType.compound,
        bowName: 'Test Bow',
      ),
      distance: 18,
      targetFaceSize: 40,
      maxEnds: 3,
      arrowsPerEnd: 3,
    );
  });

  test('moves focus to next end when current end is completed', () async {
    await notifier.addArrow(10);
    await notifier.addArrow(9);
    await notifier.addArrow(8);

    expect(notifier.state.focusedEndIndex, 1);
    expect(notifier.state.focusedArrowIndex, 0);
    expect(notifier.state.currentEndNumber, 2);
  });

  test('keeps focus on terminal end after final arrow is recorded', () async {
    for (var i = 0; i < 8; i++) {
      await notifier.addArrow(10);
    }

    expect(notifier.state.focusedEndIndex, 2);
    expect(notifier.state.focusedArrowIndex, 2);
    expect(notifier.state.currentEndNumber, 3);

    await notifier.addArrow(10);

    expect(notifier.state.focusedEndIndex, 2);
    expect(notifier.state.focusedArrowIndex, 2);
    expect(notifier.state.currentEndNumber, 3);
    expect(notifier.state.currentSession?.ends.length, 3);
    expect(notifier.state.currentSession?.ends.last.arrows.length, 3);
  });
}
