import 'package:archery_tracker/models/equipment.dart';
import 'package:archery_tracker/models/training_session.dart';
import 'package:archery_tracker/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingSession _sessionOn(DateTime date, String id) {
  return TrainingSession(
    id: id,
    date: date,
    equipment: const Equipment(bowType: BowType.recurve),
    distance: 18,
    targetFaceSize: 40,
  );
}

void main() {
  test('recentSessions returns all sessions sorted by date desc', () {
    final now = DateTime(2026, 2, 27);
    final sessions = List.generate(
      12,
      (i) => _sessionOn(now.subtract(Duration(days: i)), 'id-$i'),
    );

    final state = SessionState(sessions: sessions.reversed.toList());
    final sorted = state.recentSessions;

    expect(sorted.length, 12);
    expect(sorted.first.date, now);
    expect(sorted.last.date, now.subtract(const Duration(days: 11)));
  });
}
