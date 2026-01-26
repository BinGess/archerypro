import 'package:flutter/material.dart';
import '../models/arrow.dart';
import '../models/end.dart';
import '../models/equipment.dart';
import '../models/training_session.dart';
import '../services/session_service.dart';
import '../services/scoring_service.dart';
import 'dart:math' as math;

/// Generate sample data for testing and demonstration
class SampleDataGenerator {
  final SessionService _sessionService;
  final ScoringService _scoringService;
  final math.Random _random = math.Random();

  SampleDataGenerator(this._sessionService, this._scoringService);

  /// Generate and save comprehensive sample training sessions
  /// Replaces existing data with a 30-day progression history
  Future<void> generateSampleSessions() async {
    // Check if we should generate sample data
    // Only generate if NO data exists to avoid overwriting user data
    final existing = await _sessionService.getAllSessions();
    if (existing.isNotEmpty) {
      return;
    }
    
    // Only proceed if empty
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final sessions = <TrainingSession>[];

    // Generate ~20 sessions over 30 days
    for (int i = 0; i < 20; i++) {
      // Calculate date: spread out over 30 days
      final date = startDate.add(Duration(days: (i * 1.5).round()));
      if (date.isAfter(now)) break;

      // Determine phase based on progress (0.0 to 1.0)
      final progress = i / 19.0;
      
      // Phase characteristics
      late double avgScoreTarget;
      late double consistencySigma; // Lower is better (tighter grouping)
      late Offset centerBias;

      if (progress < 0.3) {
        // Phase 1: Beginner/Rust (Days 1-10)
        // Lower scores, high scatter, systematic bias (e.g., low-left)
        avgScoreTarget = 7.5;
        consistencySigma = 0.25; // Large scatter (radius 0.25 covers ~2.5 rings)
        centerBias = const Offset(-0.15, 0.15); // Biased Low-Left
      } else if (progress < 0.7) {
        // Phase 2: Improving (Days 11-20)
        // Better scores, improving scatter, bias correcting
        avgScoreTarget = 8.5;
        consistencySigma = 0.18;
        centerBias = const Offset(-0.05, 0.05); // Slight bias
      } else {
        // Phase 3: Advanced/Peak (Days 21-30)
        // High scores, tight groups, centered
        avgScoreTarget = 9.2;
        consistencySigma = 0.12; // Tight scatter
        centerBias = const Offset(0.02, -0.01); // Almost centered
      }

      // Add some random daily fluctuation
      final dailyFluctuation = (_random.nextDouble() - 0.5) * 0.05; // +/- 0.05 sigma
      consistencySigma += dailyFluctuation;
      if (consistencySigma < 0.05) consistencySigma = 0.05;

      sessions.add(_createSimulatedSession(
        date: date,
        bowType: i % 5 == 0 ? BowType.recurve : BowType.compound, // Mostly compound, occasional recurve
        distance: 18.0,
        sigma: consistencySigma,
        bias: centerBias,
      ));
    }

    // Save all sessions in batch (much faster than individual saves)
    await _sessionService.saveSessions(sessions);
  }

  TrainingSession _createSimulatedSession({
    required DateTime date,
    required BowType bowType,
    required double distance,
    required double sigma,
    required Offset bias,
  }) {
    final equipment = Equipment(
      bowType: bowType,
      bowName: bowType == BowType.compound ? '我的复合弓' : '我的反曲弓',
      arrowType: 'Easton X10',
    );

    // Create session
    var session = _sessionService.createSession(
      equipment: equipment,
      distance: distance,
      targetFaceSize: 40,
      environment: EnvironmentType.indoor,
    );

    // Override date (createSession uses DateTime.now())
    session = session.copyWith(date: date, startTime: date);

    // Generate 10 ends of 3 arrows (30 arrows total) - Standard indoor round half
    // Or 5 ends of 6 arrows
    final ends = <End>[];
    const endsCount = 10;
    const arrowsPerEnd = 3;

    for (int endNum = 1; endNum <= endsCount; endNum++) {
      var end = _scoringService.createEnd(endNum, maxArrows: arrowsPerEnd);

      for (int arrowNum = 0; arrowNum < arrowsPerEnd; arrowNum++) {
        // Generate shot
        final shot = _generateShot(bias, sigma);
        final score = _calculateScore(shot);
        
        // Create arrow with calculated score and exact position
        final arrow = _scoringService.createArrow(score, position: shot);
        end = _scoringService.addArrowToEnd(end, arrow);
      }

      end = _scoringService.completeEnd(end);
      ends.add(end);
    }

    // Add ends to session and complete
    session = session.copyWith(
      ends: ends,
      endTime: date.add(const Duration(minutes: 45)), // 45 mins session
    );

    return _sessionService.completeSession(session);
  }

  /// Generate a shot position using normal distribution (Box-Muller transform)
  Offset _generateShot(Offset mean, double sigma) {
    // Box-Muller transform
    double u = _random.nextDouble();
    double v = _random.nextDouble();
    
    // Avoid log(0)
    if (u == 0) u = 0.0000001;

    double z1 = math.sqrt(-2.0 * math.log(u)) * math.cos(2.0 * math.pi * v);
    double z2 = math.sqrt(-2.0 * math.log(u)) * math.sin(2.0 * math.pi * v);

    // Apply mean and standard deviation
    // Note: sigma is radius-based. 1.0 = target radius.
    double x = mean.dx + z1 * sigma;
    double y = mean.dy + z2 * sigma;
    
    // Clamp to reasonable bounds (e.g. 1.5x target radius) to avoid extreme outliers
    if (x.abs() > 1.5) x = 1.5 * (x.sign);
    if (y.abs() > 1.5) y = 1.5 * (y.sign);

    return Offset(x, y);
  }

  /// Calculate score based on distance from center (0,0)
  /// Assumes standard target face where rings are evenly spaced
  /// 10 ring radius = 0.1, 9 ring = 0.2, ... 1 ring = 1.0
  int _calculateScore(Offset position) {
    final distance = position.distance;
    
    if (distance > 1.0) return 0; // Miss

    // Calculate ring index (0 for 10/X, 1 for 9, ..., 9 for 1)
    // distance 0.05 -> index 0 (10)
    // distance 0.15 -> index 1 (9)
    final ringIndex = (distance * 10).floor();
    
    int score = 10 - ringIndex;
    
    // Handle X ring (typically half the size of 10 ring, so < 0.05)
    if (score == 10 && distance < 0.05) {
      return 11; // 11 represents X
    }
    
    return score.clamp(0, 10);
  }
}
