import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/statistics.dart';
import '../models/ai_insight.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'session_provider.dart';
import 'scoring_provider.dart';

// Analytics service provider
final analyticsServiceProvider = Provider((ref) => AnalyticsService());

// Selected period provider
final selectedPeriodProvider = StateProvider<String>((ref) => kPeriod1Month);

// Analytics provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(
    ref.watch(analyticsServiceProvider),
    ref.watch(storageServiceProvider),
    ref,
  );
});

/// State for analytics
class AnalyticsState {
  final Statistics statistics;
  final Statistics allTimeStatistics;  // Added for dashboard - always shows all-time data
  final List<AIInsight> insights;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    Statistics? statistics,
    Statistics? allTimeStatistics,
    this.insights = const [],
    this.isLoading = false,
    this.error,
  }) : statistics = statistics ?? const Statistics(
    period: kPeriod1Month,
    totalSessions: 0,
    totalArrows: 0,
    totalScore: 0,
    maxPossibleScore: 0,
    avgArrowScore: 0.0,
    avgEndScore: 0.0,
    bestScore: 0,
    bestMaxScore: 0,
    trend: 0.0,
    avgConsistency: 0.0,
    heatmapData: [],
    scoreTrendData: {},
    currentMonthArrows: 0,
  ),
  allTimeStatistics = allTimeStatistics ?? const Statistics(
    period: kPeriodAll,
    totalSessions: 0,
    totalArrows: 0,
    totalScore: 0,
    maxPossibleScore: 0,
    avgArrowScore: 0.0,
    avgEndScore: 0.0,
    bestScore: 0,
    bestMaxScore: 0,
    trend: 0.0,
    avgConsistency: 0.0,
    heatmapData: [],
    scoreTrendData: {},
    currentMonthArrows: 0,
  );

  AnalyticsState copyWith({
    Statistics? statistics,
    Statistics? allTimeStatistics,
    List<AIInsight>? insights,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      statistics: statistics ?? this.statistics,
      allTimeStatistics: allTimeStatistics ?? this.allTimeStatistics,
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for analytics
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsService _analyticsService;
  final StorageService _storageService;
  final Ref _ref;

  // Cache for calculated statistics
  final Map<String, _CachedStatistics> _cache = {};

  AnalyticsNotifier(this._analyticsService, this._storageService, this._ref)
      : super(const AnalyticsState()) {
    refreshAnalytics();
  }

  /// Refresh analytics based on current period
  Future<void> refreshAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current period
      final period = _ref.read(selectedPeriodProvider);

      // Get sessions from session provider
      final sessionState = _ref.read(sessionProvider);
      final sessions = sessionState.sessions;

      if (sessions.isEmpty) {
        state = state.copyWith(
          statistics: Statistics.empty(period: period),
          allTimeStatistics: Statistics.empty(period: kPeriodAll),
          insights: [],
          isLoading: false,
        );
        return;
      }

      // Generate cache key based on period and session data
      final cacheKey = _generateCacheKey(period, sessions.length, sessions.first.id);

      // Check if we have cached result
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        state = state.copyWith(
          statistics: cached.statistics,
          allTimeStatistics: cached.allTimeStatistics,
          insights: cached.insights,
          isLoading: false,
        );
        return;
      }

      // Get monthly goal
      final monthlyGoal = _storageService.getMonthlyGoal();

      // Calculate statistics for current period
      final statistics = _analyticsService.calculateStatistics(
        sessions: sessions,
        period: period,
        monthlyGoal: monthlyGoal,
      );

      // Calculate all-time statistics for dashboard
      final allTimeStatistics = _analyticsService.calculateStatistics(
        sessions: sessions,
        period: kPeriodAll,
        monthlyGoal: monthlyGoal,
      );

      // Generate AI insights
      final recentSessions = sessions.take(5).toList();
      final insights = _analyticsService.generateInsights(
        stats: statistics,
        recentSessions: recentSessions,
      );

      // Cache the result
      _cache[cacheKey] = _CachedStatistics(
        statistics: statistics,
        allTimeStatistics: allTimeStatistics,
        insights: insights,
        timestamp: DateTime.now(),
      );

      // Keep cache size manageable (max 10 entries)
      if (_cache.length > 10) {
        final oldestKey = _cache.keys.first;
        _cache.remove(oldestKey);
      }

      state = state.copyWith(
        statistics: statistics,
        allTimeStatistics: allTimeStatistics,
        insights: insights,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Generate cache key based on period and session data
  String _generateCacheKey(String period, int sessionCount, String firstSessionId) {
    return '$period-$sessionCount-$firstSessionId';
  }

  /// Clear cache (useful when sessions are modified)
  void clearCache() {
    _cache.clear();
  }

  /// Change period and refresh
  Future<void> changePeriod(String newPeriod) async {
    _ref.read(selectedPeriodProvider.notifier).state = newPeriod;
    await refreshAnalytics();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Cache entry for statistics
class _CachedStatistics {
  final Statistics statistics;
  final Statistics allTimeStatistics;
  final List<AIInsight> insights;
  final DateTime timestamp;

  const _CachedStatistics({
    required this.statistics,
    required this.allTimeStatistics,
    required this.insights,
    required this.timestamp,
  });
}
