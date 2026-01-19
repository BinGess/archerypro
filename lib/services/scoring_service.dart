import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/arrow.dart';
import '../models/end.dart';
import '../utils/constants.dart';
import 'dart:math' as math;

/// Service for handling scoring logic
class ScoringService {
  final _uuid = const Uuid();

  /// Validate if a score is valid
  bool isValidScore(int score) {
    return score >= kMinScore && score <= kXRingScore;
  }

  /// Create an arrow from score input
  /// score: 0 (Miss), 1-10 (regular), 11 (X)
  Arrow createArrow(int score, {Offset? position}) {
    if (!isValidScore(score)) {
      throw ArgumentError('Invalid score: $score. Must be between $kMinScore and $kXRingScore');
    }

    return Arrow.fromScore(
      id: _uuid.v4(),
      score: score,
      position: position ?? _generateRandomPosition(score),
    );
  }

  /// Generate a random position based on score (for simulation)
  /// Higher scores are closer to center (0, 0)
  Offset _generateRandomPosition(int score) {
    final random = math.Random();
    final effectiveScore = score == kXRingScore ? 10 : score;

    // Calculate max radius based on score
    // Score 10/X: radius 0.0-0.1 (very close to center)
    // Score 9: radius 0.1-0.2
    // Score 8: radius 0.2-0.3
    // ... and so on
    // Score 0 (miss): off target
    if (effectiveScore == 0) {
      // Miss - outside target
      return Offset(
        1.2 + random.nextDouble() * 0.3,
        1.2 + random.nextDouble() * 0.3,
      );
    }

    final maxRadius = (10 - effectiveScore) / 10.0;
    final minRadius = maxRadius - 0.1;

    final radius = minRadius + random.nextDouble() * (maxRadius - minRadius);
    final angle = random.nextDouble() * 2 * math.pi;

    return Offset(
      radius * math.cos(angle),
      radius * math.sin(angle),
    );
  }

  /// Create a new end
  End createEnd(int endNumber, {int maxArrows = kDefaultArrowsPerEnd}) {
    return End(
      id: _uuid.v4(),
      endNumber: endNumber,
      maxArrows: maxArrows,
    );
  }

  /// Add an arrow to an end
  End addArrowToEnd(End end, Arrow arrow) {
    if (!end.canAddArrow) {
      throw StateError('End ${end.endNumber} is full (${end.arrows.length}/${end.maxArrows})');
    }
    return end.addArrow(arrow);
  }

  /// Remove the last arrow from an end
  End removeLastArrowFromEnd(End end) {
    if (end.arrows.isEmpty) {
      throw StateError('End ${end.endNumber} has no arrows to remove');
    }
    return end.removeLastArrow();
  }

  /// Complete an end
  End completeEnd(End end) {
    return end.complete();
  }

  /// Calculate total score for multiple ends
  int calculateTotalScore(List<End> ends) {
    return ends.fold(0, (sum, end) => sum + end.totalScore);
  }

  /// Calculate max possible score for multiple ends
  int calculateMaxScore(List<End> ends) {
    return ends.fold(0, (sum, end) => sum + end.maxScore);
  }

  /// Get score input options for keypad
  List<ScoreOption> getScoreOptions() {
    return [
      ScoreOption(label: 'X', value: kXRingScore, color: Colors.orange),
      ScoreOption(label: '10', value: 10, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '9', value: 9, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '8', value: 8, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '7', value: 7, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '6', value: 6, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '5', value: 5, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '4', value: 4, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '3', value: 3, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '2', value: 2, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: '1', value: 1, color: const Color(0xFF1A1A1A)),
      ScoreOption(label: 'M', value: 0, color: Colors.red),
    ];
  }

  /// Calculate score percentage
  double calculateScorePercentage(int score, int maxScore) {
    if (maxScore == 0) return 0.0;
    return (score / maxScore) * 100;
  }

  /// Get color for score (based on target rings)
  Color getScoreColor(int score) {
    final effectiveScore = score == kXRingScore ? 10 : score;

    if (effectiveScore >= 9) return const Color(0xFFFFD700); // Gold
    if (effectiveScore >= 7) return const Color(0xFFE13131); // Red
    if (effectiveScore >= 5) return const Color(0xFF0092FF); // Blue
    if (effectiveScore >= 3) return const Color(0xFF1A1A1A); // Black
    if (effectiveScore >= 1) return const Color(0xFFF8F8F8); // White
    return Colors.grey; // Miss
  }

  /// Get text color for score display (for readability)
  Color getScoreTextColor(int score) {
    final effectiveScore = score == kXRingScore ? 10 : score;

    if (effectiveScore >= 9 || effectiveScore >= 7 || effectiveScore >= 3) {
      return Colors.black; // Dark text on gold, red, black
    }
    if (effectiveScore >= 5 || effectiveScore >= 1) {
      return Colors.white; // White text on blue, white
    }
    return Colors.white; // Miss
  }
}

/// Score option for UI display
class ScoreOption {
  final String label;
  final int value;
  final Color color;

  const ScoreOption({
    required this.label,
    required this.value,
    required this.color,
  });
}
