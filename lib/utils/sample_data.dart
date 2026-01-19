import 'package:flutter/material.dart';
import '../models/arrow.dart';
import '../models/end.dart';
import '../models/equipment.dart';
import '../models/training_session.dart';
import '../services/session_service.dart';
import '../services/scoring_service.dart';

/// Generate sample data for testing and demonstration
class SampleDataGenerator {
  final SessionService _sessionService;
  final ScoringService _scoringService;

  SampleDataGenerator(this._sessionService, this._scoringService);

  /// Generate and save sample training sessions
  Future<void> generateSampleSessions() async {
    // Check if we already have data
    final existing = await _sessionService.getAllSessions();
    if (existing.isNotEmpty) {
      return; // Don't overwrite existing data
    }

    // Generate 5 sample sessions
    final sessions = [
      _createSession(
        date: DateTime.now().subtract(const Duration(days: 2)),
        scores: [10, 10, 9, 10, 9, 10, 9, 9, 10, 10, 9, 9, 10, 9, 9, 10, 10, 9, 10, 10, 9, 10, 9, 9, 10, 9, 10, 9, 10, 10],
        bowType: BowType.compound,
        distance: 18.0,
      ),
      _createSession(
        date: DateTime.now().subtract(const Duration(days: 5)),
        scores: [9, 8, 9, 10, 9, 8, 9, 9, 8, 10, 8, 9, 9, 8, 9, 8, 9, 9, 10, 8, 9, 8, 9, 9, 8, 8, 9, 8, 9, 10],
        bowType: BowType.compound,
        distance: 18.0,
      ),
      _createSession(
        date: DateTime.now().subtract(const Duration(days: 10)),
        scores: [10, 9, 10, 9, 10, 9, 9, 10, 9, 10, 9, 9, 10, 9, 10, 9, 10, 9, 9, 10, 9, 10, 9, 10, 9, 9, 10, 9, 10, 9],
        bowType: BowType.compound,
        distance: 18.0,
      ),
      _createSession(
        date: DateTime.now().subtract(const Duration(days: 15)),
        scores: [8, 9, 8, 9, 8, 9, 8, 9, 8, 9, 8, 9, 9, 8, 9, 8, 9, 8, 9, 8, 9, 8, 9, 8, 9, 8, 9, 9, 8, 9],
        bowType: BowType.recurve,
        distance: 18.0,
      ),
      _createSession(
        date: DateTime.now().subtract(const Duration(days: 20)),
        scores: [9, 9, 10, 9, 9, 10, 9, 9, 10, 9, 9, 10, 9, 9, 10, 9, 9, 10, 9, 9, 10, 9, 9, 10, 9, 9, 10, 9, 9, 10],
        bowType: BowType.compound,
        distance: 18.0,
      ),
    ];

    // Save all sessions
    for (final session in sessions) {
      await _sessionService.saveSession(session);
    }
  }

  TrainingSession _createSession({
    required DateTime date,
    required List<int> scores,
    required BowType bowType,
    required double distance,
  }) {
    final equipment = Equipment(
      bowType: bowType,
      bowName: bowType == BowType.compound ? 'Hoyt Carbon RX-8' : 'Win&Win WIAWIS',
      arrowType: 'Easton X10',
    );

    // Create session
    var session = _sessionService.createSession(
      equipment: equipment,
      distance: distance,
      targetFaceSize: 40,
      environment: EnvironmentType.indoor,
    );

    // Group scores into ends (6 arrows each)
    final ends = <End>[];
    for (int i = 0; i < scores.length; i += 6) {
      final endScores = scores.skip(i).take(6).toList();
      var end = _scoringService.createEnd(ends.length + 1, maxArrows: 6);

      // Add arrows to this end
      for (final score in endScores) {
        final arrow = _scoringService.createArrow(score);
        end = _scoringService.addArrowToEnd(end, arrow);
      }

      end = _scoringService.completeEnd(end);
      ends.add(end);
    }

    // Add ends to session
    session = session.copyWith(
      ends: ends,
      startTime: date,
      endTime: date.add(const Duration(hours: 1, minutes: 15)),
    );

    return _sessionService.completeSession(session);
  }
}
