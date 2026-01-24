import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_session.dart';
import '../models/ai_coach/ai_coach_result.dart';
import '../services/ai_coach/smart_ai_service.dart';
import '../services/ai_coach/coze_ai_service.dart';
import '../services/ai_coach/local_ai_service.dart';
import '../services/ai_coach/network_service.dart';
import '../services/ai_coach/cache_service.dart';
import '../services/logger_service.dart';
import '../services/analytics_service.dart';
import '../services/session_analysis_service.dart';
import 'session_provider.dart';
import 'analytics_provider.dart';
import 'locale_provider.dart';

// ========== Service Providers ==========

/// Dio 客户端 Provider
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

/// 日志服务 Provider
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

/// 网络服务 Provider
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

/// 缓存服务 Provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// 分析服务 Provider (已存在)
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// 会话分析服务 Provider
final sessionAnalysisServiceProvider = Provider<SessionAnalysisService>((ref) {
  return SessionAnalysisService();
});

/// 本地 AI 服务 Provider
final localAIServiceProvider = Provider<LocalAIService>((ref) {
  return LocalAIService(
    sessionAnalysisService: ref.watch(sessionAnalysisServiceProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

/// Coze AI 服务 Provider
final cozeAIServiceProvider = Provider<CozeAIService>((ref) {
  return CozeAIService(
    dio: ref.watch(dioProvider),
    cache: ref.watch(cacheServiceProvider),
    logger: ref.watch(loggerServiceProvider),
  );
});

/// 智能 AI 服务 Provider
final smartAIServiceProvider = Provider<SmartAIService>((ref) {
  return SmartAIService(
    cozeService: ref.watch(cozeAIServiceProvider),
    localService: ref.watch(localAIServiceProvider),
    networkService: ref.watch(networkServiceProvider),
    logger: ref.watch(loggerServiceProvider),
  );
});

// ========== AI Coach Provider ==========

/// AI 教练状态管理 Provider
final aiCoachProvider =
    StateNotifierProvider<AICoachNotifier, AICoachState>((ref) {
  return AICoachNotifier(
    smartAIService: ref.watch(smartAIServiceProvider),
    sessionProvider: ref,
    analyticsProvider: ref,
    localeProvider: ref,
  );
});

/// AI 教练状态
class AICoachState {
  final AICoachResult? latestResult;
  final bool isLoading;
  final String? error;
  final String? loadingMessage;

  const AICoachState({
    this.latestResult,
    this.isLoading = false,
    this.error,
    this.loadingMessage,
  });

  AICoachState copyWith({
    AICoachResult? latestResult,
    bool? isLoading,
    String? error,
    String? loadingMessage,
  }) {
    return AICoachState(
      latestResult: latestResult ?? this.latestResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

/// AI 教练状态管理
class AICoachNotifier extends StateNotifier<AICoachState> {
  final SmartAIService _smartAIService;
  final Ref _ref;

  AICoachNotifier({
    required SmartAIService smartAIService,
    required Ref sessionProvider,
    required Ref analyticsProvider,
    required Ref localeProvider,
  })  : _smartAIService = smartAIService,
        _ref = sessionProvider,
        super(const AICoachState());

  /// 分析最新训练
  Future<void> analyzeLatestSession() async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: '正在分析训练数据...',
      error: null,
    );

    try {
      // 获取最新的训练会话
      final sessionState = _ref.read(sessionProvider);
      final session = sessionState.sessions.firstOrNull;

      if (session == null) {
        throw Exception('没有可分析的训练数据');
      }

      // 获取历史会话用于对比
      final historicalSessions = sessionState.sessions
          .where((s) => s.id != session.id)
          .take(10)
          .toList();

      // 获取当前语言
      final locale = _ref.read(localeProvider);
      final language = locale.languageCode;

      // 调用智能 AI 服务分析
      final result = await _smartAIService.analyzeSession(
        session,
        historicalSessions,
        language,
      );

      state = state.copyWith(
        latestResult: result,
        isLoading: false,
        loadingMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        loadingMessage: null,
      );
    }
  }

  /// 分析指定的训练会话
  Future<void> analyzeSession(TrainingSession session) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: '正在分析训练数据...',
      error: null,
    );

    try {
      // 获取历史会话
      final sessionState = _ref.read(sessionProvider);
      final historicalSessions = sessionState.sessions
          .where((s) => s.id != session.id)
          .take(10)
          .toList();

      // 获取当前语言
      final locale = _ref.read(localeProvider);
      final language = locale.languageCode;

      // 调用智能 AI 服务分析
      final result = await _smartAIService.analyzeSession(
        session,
        historicalSessions,
        language,
      );

      state = state.copyWith(
        latestResult: result,
        isLoading: false,
        loadingMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        loadingMessage: null,
      );
    }
  }

  /// 分析周期表现
  Future<void> analyzePeriod(String period) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: '正在分析周期表现...',
      error: null,
    );

    try {
      // 获取所有训练会话
      final sessionState = _ref.read(sessionProvider);
      final allSessions = sessionState.sessions;

      if (allSessions.isEmpty) {
        throw Exception('没有可分析的训练数据');
      }

      // 获取统计数据
      final analyticsState = _ref.read(analyticsProvider);
      final stats = analyticsState.stats[period];

      if (stats == null) {
        throw Exception('无法获取统计数据');
      }

      // 获取当前语言
      final locale = _ref.read(localeProvider);
      final language = locale.languageCode;

      // 调用智能 AI 服务分析周期
      final result = await _smartAIService.analyzePeriod(
        period,
        stats,
        allSessions,
        language,
      );

      state = state.copyWith(
        latestResult: result,
        isLoading: false,
        loadingMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        loadingMessage: null,
      );
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 清除结果
  void clearResult() {
    state = const AICoachState();
  }

  /// 检查服务状态
  Future<Map<String, dynamic>> checkServiceStatus() async {
    return await _smartAIService.checkServiceStatus();
  }
}
