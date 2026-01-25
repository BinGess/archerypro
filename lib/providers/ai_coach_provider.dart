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
import 'scoring_provider.dart';

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
  // 单次训练分析结果（按 session ID 存储）
  final Map<String, AICoachResult> sessionResults;

  // 周期分析结果（按 period 存储）
  final Map<String, AICoachResult> periodResults;

  final bool isLoading;
  final String? error;
  final String? loadingMessage;

  // 当前正在分析的类型和ID（用于UI显示）
  final String? currentAnalysisType; // 'session' or 'period'
  final String? currentAnalysisId; // sessionId or period

  const AICoachState({
    this.sessionResults = const {},
    this.periodResults = const {},
    this.isLoading = false,
    this.error,
    this.loadingMessage,
    this.currentAnalysisType,
    this.currentAnalysisId,
  });

  AICoachState copyWith({
    Map<String, AICoachResult>? sessionResults,
    Map<String, AICoachResult>? periodResults,
    bool? isLoading,
    String? error,
    String? loadingMessage,
    String? currentAnalysisType,
    String? currentAnalysisId,
  }) {
    return AICoachState(
      sessionResults: sessionResults ?? this.sessionResults,
      periodResults: periodResults ?? this.periodResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      currentAnalysisType: currentAnalysisType ?? this.currentAnalysisType,
      currentAnalysisId: currentAnalysisId ?? this.currentAnalysisId,
    );
  }

  /// 获取特定训练会话的分析结果
  AICoachResult? getSessionResult(String sessionId) {
    return sessionResults[sessionId];
  }

  /// 获取特定周期的分析结果
  AICoachResult? getPeriodResult(String period) {
    return periodResults[period];
  }

  /// 检查是否正在分析特定会话
  bool isAnalyzingSession(String sessionId) {
    return isLoading &&
           currentAnalysisType == 'session' &&
           currentAnalysisId == sessionId;
  }

  /// 检查是否正在分析特定周期
  bool isAnalyzingPeriod(String period) {
    return isLoading &&
           currentAnalysisType == 'period' &&
           currentAnalysisId == period;
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
    // 获取最新的训练会话
    final sessionState = _ref.read(sessionProvider);
    final session = sessionState.sessions.firstOrNull;

    if (session == null) {
      state = state.copyWith(
        error: '没有可分析的训练数据',
      );
      return;
    }

    await analyzeSession(session);
  }

  /// 分析指定的训练会话
  Future<void> analyzeSession(TrainingSession session) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: '正在分析训练数据...',
      error: null,
      currentAnalysisType: 'session',
      currentAnalysisId: session.id,
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

      // 更新该会话的分析结果
      final updatedSessionResults = Map<String, AICoachResult>.from(state.sessionResults);
      updatedSessionResults[session.id] = result;

      state = state.copyWith(
        sessionResults: updatedSessionResults,
        isLoading: false,
        loadingMessage: null,
        currentAnalysisType: null,
        currentAnalysisId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        loadingMessage: null,
        currentAnalysisType: null,
        currentAnalysisId: null,
      );
    }
  }

  /// 分析周期表现
  Future<void> analyzePeriod(String period) async {
    state = state.copyWith(
      isLoading: true,
      loadingMessage: '正在分析周期表现...',
      error: null,
      currentAnalysisType: 'period',
      currentAnalysisId: period,
    );

    try {
      // 获取所有训练会话
      final sessionState = _ref.read(sessionProvider);
      final allSessions = sessionState.sessions;

      if (allSessions.isEmpty) {
        throw Exception('没有可分析的训练数据');
      }

      // 获取统计数据
      final analyticsService = _ref.read(analyticsServiceProvider);
      final storageService = _ref.read(storageServiceProvider);
      final stats = analyticsService.calculateStatistics(
        sessions: allSessions,
        period: period,
        monthlyGoal: storageService.getMonthlyGoal(),
      );

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

      // 更新该周期的分析结果
      final updatedPeriodResults = Map<String, AICoachResult>.from(state.periodResults);
      updatedPeriodResults[period] = result;

      state = state.copyWith(
        periodResults: updatedPeriodResults,
        isLoading: false,
        loadingMessage: null,
        currentAnalysisType: null,
        currentAnalysisId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        loadingMessage: null,
        currentAnalysisType: null,
        currentAnalysisId: null,
      );
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 清除特定会话的分析结果
  void clearSessionResult(String sessionId) {
    final updatedResults = Map<String, AICoachResult>.from(state.sessionResults);
    updatedResults.remove(sessionId);
    state = state.copyWith(sessionResults: updatedResults);
  }

  /// 清除特定周期的分析结果
  void clearPeriodResult(String period) {
    final updatedResults = Map<String, AICoachResult>.from(state.periodResults);
    updatedResults.remove(period);
    state = state.copyWith(periodResults: updatedResults);
  }

  /// 清除所有结果
  void clearAllResults() {
    state = const AICoachState();
  }

  /// 检查服务状态
  Future<Map<String, dynamic>> checkServiceStatus() async {
    return await _smartAIService.checkServiceStatus();
  }
}
