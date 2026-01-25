import '../../models/training_session.dart';
import '../../models/ai_coach/ai_coach_result.dart';
import '../logger_service.dart';
import 'coze_ai_service.dart';
import 'local_ai_service.dart';
import 'network_service.dart';

/// 智能 AI 服务 - 智能路由（在线/离线）
/// 优先使用在线 Coze AI，网络不可用或出错时自动降级到本地 AI
class SmartAIService {
  final CozeAIService _cozeService;
  final LocalAIService _localService;
  final NetworkService _networkService;
  final LoggerService _logger;

  SmartAIService({
    required CozeAIService cozeService,
    required LocalAIService localService,
    required NetworkService networkService,
    required LoggerService logger,
  })  : _cozeService = cozeService,
        _localService = localService,
        _networkService = networkService,
        _logger = logger;

  /// 分析单次训练
  /// 优先使用在线 AI，失败时自动降级到本地 AI
  Future<AICoachResult> analyzeSession(
    TrainingSession session,
    List<TrainingSession> historicalSessions,
    String language,
  ) async {
    _logger.log('SmartAIService: 开始分析单次训练', level: LogLevel.info);

    // 检查网络状态
    final isOnline = await _networkService.isNetworkAvailable();
    _logger.log('网络状态: ${isOnline ? "在线" : "离线"}', level: LogLevel.info);

    if (isOnline) {
      try {
        // 尝试使用在线 Coze AI
        _logger.log('尝试使用 Coze AI 在线分析', level: LogLevel.info);
        final response = await _cozeService.analyzeSession(session, language);
        _logger.log('Coze AI 分析成功', level: LogLevel.info);
        return response;
      } catch (e) {
        // 在线分析失败，降级到本地
        _logger.log(
          'Coze AI 分析失败，降级到本地 AI',
          level: LogLevel.warning,
          error: e,
        );
        return await _analyzeSessionLocally(session, historicalSessions);
      }
    } else {
      // 网络不可用，直接使用本地 AI
      _logger.log('网络不可用，使用本地 AI 分析', level: LogLevel.info);
      return await _analyzeSessionLocally(session, historicalSessions);
    }
  }

  /// 分析周期表现
  /// 优先使用在线 AI，失败时自动降级到本地 AI
  Future<AICoachResult> analyzePeriod(
    String period,
    dynamic stats,
    List<TrainingSession> allSessions,
    String language,
  ) async {
    _logger.log('SmartAIService: 开始分析周期表现 ($period)', level: LogLevel.info);

    // 检查网络状态
    final isOnline = await _networkService.isNetworkAvailable();

    if (isOnline) {
      try {
        // 尝试使用在线 Coze AI
        _logger.log('尝试使用 Coze AI 在线分析周期', level: LogLevel.info);
        final recentSessions = _getRecentSessions(allSessions, 10);
        final response = await _cozeService.analyzePeriod(
          period, // 传递period参数
          stats,
          recentSessions,
          language,
        );
        _logger.log('Coze AI 周期分析成功', level: LogLevel.info);
        return response;
      } catch (e) {
        // 在线分析失败，降级到本地
        _logger.log(
          'Coze AI 周期分析失败，降级到本地 AI',
          level: LogLevel.warning,
          error: e,
        );
        return await _analyzePeriodLocally(period, allSessions);
      }
    } else {
      // 网络不可用，直接使用本地 AI
      _logger.log('网络不可用，使用本地 AI 分析周期', level: LogLevel.info);
      return await _analyzePeriodLocally(period, allSessions);
    }
  }

  /// 本地分析单次训练
  Future<AICoachResult> _analyzeSessionLocally(
    TrainingSession session,
    List<TrainingSession> historicalSessions,
  ) async {
    try {
      final localResult = await _localService.analyzeSession(
        session,
        historicalSessions,
      );
      _logger.log('本地 AI 分析完成', level: LogLevel.info);
      return localResult;
    } catch (e) {
      _logger.log('本地 AI 分析失败', level: LogLevel.error, error: e);
      // 返回降级的默认结果
      return _createFallbackResult();
    }
  }

  /// 本地分析周期表现
  Future<AICoachResult> _analyzePeriodLocally(
    String period,
    List<TrainingSession> allSessions,
  ) async {
    try {
      final localResult = await _localService.analyzePeriod(
        period,
        allSessions,
      );
      _logger.log('本地 AI 周期分析完成', level: LogLevel.info);
      return localResult;
    } catch (e) {
      _logger.log('本地 AI 周期分析失败', level: LogLevel.error, error: e);
      // 返回降级的默认结果
      return _createFallbackResult();
    }
  }

  /// 获取最近的 N 次训练
  List<TrainingSession> _getRecentSessions(
    List<TrainingSession> sessions,
    int count,
  ) {
    if (sessions.isEmpty) return [];

    // 按日期排序（最新在前）
    final sorted = List<TrainingSession>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return sorted.take(count).toList();
  }

  /// 创建降级的默认结果（当所有分析都失败时）
  AICoachResult _createFallbackResult() {
    return AICoachResult(
      diagnosis: '暂时无法生成分析报告，请检查网络连接或稍后再试。',
      strengths: ['继续保持训练', '规律训练是进步的基础'],
      weaknesses: [],
      suggestions: [
        CoachingSuggestion(
          category: 'general',
          title: '保持训练节奏',
          description: '暂时无法获取详细分析，建议保持当前的训练节奏和频率。',
          priority: 3,
          actionSteps: [
            '维持规律训练',
            '关注动作一致性',
            '记录训练数据',
          ],
        ),
      ],
      trainingPlan: null,
      encouragement: '坚持就是胜利！继续努力！',
      source: 'fallback',
      timestamp: DateTime.now(),
    );
  }

  /// 检查服务状态
  Future<Map<String, dynamic>> checkServiceStatus() async {
    final isOnline = await _networkService.isNetworkAvailable();
    final connectivityType = await _networkService.getConnectivityType();

    return {
      'network_available': isOnline,
      'connectivity_type': connectivityType.toString(),
      'preferred_service': isOnline ? 'coze' : 'local',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
