import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../models/training_session.dart';
import '../../models/ai_coach/ai_coach_result.dart';
import '../logger_service.dart';
import '../../utils/ai_config.dart';
import 'cache_service.dart';

/// Coze AI 服务 - 扣子智能体 API 集成（简化版）
class CozeAIService {
  final Dio _dio;
  final CacheService _cache;
  final LoggerService _logger;
  final Uuid _uuid = const Uuid();

  CozeAIService({
    required Dio dio,
    required CacheService cache,
    required LoggerService logger,
  })  : _dio = dio,
        _cache = cache,
        _logger = logger {
    _configureDio();
  }

  /// 配置 Dio 客户端
  void _configureDio() {
    _dio.options.baseUrl = AIConfig.baseUrl;
    _dio.options.connectTimeout = AIConfig.connectionTimeout;
    _dio.options.receiveTimeout = AIConfig.receiveTimeout;
    _dio.options.headers = {
      'Authorization': 'Bearer ${AIConfig.apiToken}',
      'Content-Type': 'application/json',
    };

    // 日志拦截器（仅在开发模式）
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.log('Dio: $obj', level: LogLevel.debug),
    ));

    // 重试拦截器（网络错误自动重试）
    _dio.interceptors.add(_RetryInterceptor(
      dio: _dio,
      retries: AIConfig.maxRetries,
      logger: _logger,
    ));
  }

  /// 分析单次训练
  Future<AICoachResult> analyzeSession(
    TrainingSession session,
    String language,
  ) async {
    _logger.log('开始分析单次训练: ${session.id}', level: LogLevel.info);

    // 检查 API 配置
    if (!AIConfig.isConfigured()) {
      throw CozeAPIException('API 配置未完成，请填写 API Token');
    }

    // 检查缓存
    final cacheKey = 'session_${session.id}_$language';
    final cached = await _cache.get<AICoachResult>(cacheKey);
    if (cached != null) {
      _logger.log('使用缓存结果', level: LogLevel.info);
      return cached;
    }

    try {
      // 1. 构建训练数据提示词
      final promptText = _buildSessionPrompt(session, language);

      // 2. 调用 Coze API
      final aiResponse = await _callCozeAPI(promptText);

      // 3. 解析 AI 建议为结构化结果
      final result = _parseAIAdvice(aiResponse, language);

      // 4. 缓存结果（24小时）
      await _cache.set(
        cacheKey,
        result,
        duration: AIConfig.sessionCacheDuration,
      );

      _logger.log('分析完成', level: LogLevel.info);
      return result;
    } catch (e) {
      _logger.log('Coze API 调用失败', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  /// 分析周期表现
  Future<AICoachResult> analyzePeriod(
    dynamic stats,
    List<TrainingSession> recentSessions,
    String language,
  ) async {
    _logger.log('开始分析周期表现', level: LogLevel.info);

    // 检查 API 配置
    if (!AIConfig.isConfigured()) {
      throw CozeAPIException('API 配置未完成，请填写 API Token');
    }

    final cacheKey = 'period_${DateTime.now().day}_$language';
    final cached = await _cache.get<AICoachResult>(cacheKey);
    if (cached != null) return cached;

    try {
      final promptText = _buildPeriodPrompt(stats, recentSessions, language);
      final aiResponse = await _callCozeAPI(promptText);
      final result = _parseAIAdvice(aiResponse, language);

      await _cache.set(
        cacheKey,
        result,
        duration: AIConfig.periodCacheDuration,
      );

      return result;
    } catch (e) {
      _logger.log('Coze API 周期分析失败', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  // ========== 核心 API 调用方法 ==========

  /// 调用 Coze API
  Future<String> _callCozeAPI(String promptText) async {
    try {
      // 生成唯一的 session_id
      final sessionId = _uuid.v4().replaceAll('-', '');

      final response = await _dio.post(
        '/stream_run',
        data: {
          'content': {
            'query': {
              'prompt': [
                {
                  'type': 'text',
                  'content': {
                    'text': promptText,
                  },
                },
              ],
            },
          },
          'type': 'query',
          'session_id': sessionId,
          'project_id': AIConfig.projectId,
        },
      );

      // 处理响应
      if (response.statusCode == 200) {
        // 如果返回的是流式数据，需要特殊处理
        // 这里假设返回的是完整的JSON响应
        final responseData = response.data;

        // 根据实际API返回格式提取文本
        // 可能需要根据实际返回调整
        if (responseData is Map) {
          // 尝试多种可能的响应格式
          final text = responseData['text'] ??
                      responseData['content'] ??
                      responseData['response'] ??
                      responseData.toString();
          return text;
        } else if (responseData is String) {
          return responseData;
        } else {
          return responseData.toString();
        }
      } else {
        throw CozeAPIException(
          'API 响应错误：${response.statusCode}',
          code: 'BAD_RESPONSE',
        );
      }
    } on DioException catch (e) {
      throw CozeAPIException.fromDioError(e);
    }
  }

  // ========== 提示词构建方法 ==========

  /// 构建单次训练提示词
  String _buildSessionPrompt(TrainingSession session, String language) {
    final data = {
      '分析类型': '单次训练分析',
      '训练日期': session.date.toString().split(' ')[0],
      '距离': '${session.distance}米',
      '靶面': '${session.targetFaceSize}厘米',
      '总分': session.totalScore,
      '最高分': session.maxScore,
      '箭数': session.arrowCount,
      '平均分': session.averageArrowScore.toStringAsFixed(2),
      '稳定性': '${session.consistency.toStringAsFixed(1)}%',
      '10环率': '${session.tenRingRate.toStringAsFixed(1)}%',
      '得分率': '${session.scorePercentage.toStringAsFixed(1)}%',
    };

    if (language == 'zh') {
      return '''
作为专业射箭教练，请分析以下训练数据：

${_formatDataAsString(data)}

请提供：
1. 核心诊断（2-3句话总结表现）
2. 3个优势点
3. 3个待改进点
4. 3-5条具体改进建议（每条包含类别、标题、描述、优先级1-5、行动步骤）
5. 一句鼓励的话

请以JSON格式返回，格式如下：
{
  "诊断": "核心诊断内容",
  "优势": ["优势1", "优势2", "优势3"],
  "弱点": ["弱点1", "弱点2", "弱点3"],
  "建议": [
    {
      "类别": "technique/physical/mental/equipment",
      "标题": "建议标题",
      "描述": "详细描述",
      "优先级": 4,
      "行动步骤": ["步骤1", "步骤2", "步骤3"]
    }
  ],
  "鼓励": "鼓励的话"
}
''';
    } else {
      return '''
As a professional archery coach, please analyze the following training data:

${_formatDataAsString(data)}

Please provide:
1. Core diagnosis (2-3 sentences summary)
2. 3 strengths
3. 3 areas for improvement
4. 3-5 specific suggestions (each with category, title, description, priority 1-5, action steps)
5. An encouraging message

Please return in JSON format as follows:
{
  "diagnosis": "Core diagnosis content",
  "strengths": ["Strength 1", "Strength 2", "Strength 3"],
  "weaknesses": ["Weakness 1", "Weakness 2", "Weakness 3"],
  "suggestions": [
    {
      "category": "technique/physical/mental/equipment",
      "title": "Suggestion title",
      "description": "Detailed description",
      "priority": 4,
      "actionSteps": ["Step 1", "Step 2", "Step 3"]
    }
  ],
  "encouragement": "Encouraging message"
}
''';
    }
  }

  /// 构建周期提示词
  String _buildPeriodPrompt(
    dynamic stats,
    List<TrainingSession> recentSessions,
    String language,
  ) {
    final sessionCount = recentSessions.length;
    final totalArrows = recentSessions.fold<int>(
        0, (sum, s) => sum + s.arrowCount);
    final avgScore = _calculateAverage(recentSessions);

    if (language == 'zh') {
      return '''
作为专业射箭教练，请分析以下周期训练数据：

训练次数：$sessionCount 次
总箭数：$totalArrows 支
平均分：${avgScore.toStringAsFixed(2)}

最近5次训练：
${_formatRecentSessions(recentSessions.take(5).toList())}

请提供：
1. 周期诊断（整体表现评估）
2. 优势点分析
3. 待改进点分析
4. 改进建议
5. 4周训练计划（包含2-3个阶段，每个阶段包含训练项目、箭数、频率）

请以JSON格式返回。
''';
    } else {
      return '''
As a professional archery coach, please analyze the following period training data:

Sessions: $sessionCount
Total Arrows: $totalArrows
Average Score: ${avgScore.toStringAsFixed(2)}

Recent 5 sessions:
${_formatRecentSessions(recentSessions.take(5).toList())}

Please provide:
1. Period diagnosis (overall performance assessment)
2. Strengths analysis
3. Areas for improvement
4. Suggestions
5. 4-week training plan (2-3 phases, each with drills, arrows, frequency)

Please return in JSON format.
''';
    }
  }

  /// 格式化数据为字符串
  String _formatDataAsString(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}：${e.value}').join('\n');
  }

  /// 格式化最近训练列表
  String _formatRecentSessions(List<TrainingSession> sessions) {
    return sessions.map((s) {
      return '${s.date.toString().split(' ')[0]} - 总分：${s.totalScore}，平均分：${s.averageArrowScore.toStringAsFixed(2)}，稳定性：${s.consistency.toStringAsFixed(1)}%';
    }).join('\n');
  }

  /// 计算平均分
  double _calculateAverage(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0.0;
    final total = sessions.fold<double>(
        0.0, (sum, s) => sum + s.averageArrowScore);
    return total / sessions.length;
  }

  /// 解析 AI 建议
  AICoachResult _parseAIAdvice(String aiAdvice, String language) {
    _logger.log(
      '解析 AI 回复: ${aiAdvice.length > 100 ? aiAdvice.substring(0, 100) : aiAdvice}...',
      level: LogLevel.debug,
    );

    try {
      // 尝试提取JSON（AI可能返回包含markdown的文本）
      String jsonStr = aiAdvice;

      // 如果包含markdown代码块，提取JSON部分
      if (aiAdvice.contains('```json')) {
        final jsonMatch = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```').firstMatch(aiAdvice);
        if (jsonMatch != null) {
          jsonStr = jsonMatch.group(1) ?? aiAdvice;
        }
      } else if (aiAdvice.contains('```')) {
        final jsonMatch = RegExp(r'```\s*(\{[\s\S]*?\})\s*```').firstMatch(aiAdvice);
        if (jsonMatch != null) {
          jsonStr = jsonMatch.group(1) ?? aiAdvice;
        }
      }

      // 如果整个字符串看起来像JSON，直接解析
      jsonStr = jsonStr.trim();
      if (jsonStr.startsWith('{')) {
        final jsonData = jsonDecode(jsonStr);
        return AICoachResult.fromCozeJson(jsonData, 'coze');
      }

      // 如果解析失败，返回基于文本的简化结果
      throw FormatException('无法解析为JSON');
    } catch (e) {
      _logger.log('AI 回复不是标准 JSON 格式，使用文本解析', level: LogLevel.warning, error: e);

      // 返回基于原始文本的结果
      return AICoachResult(
        diagnosis: aiAdvice.length > 200 ? aiAdvice.substring(0, 200) + '...' : aiAdvice,
        strengths: [],
        weaknesses: [],
        suggestions: [
          CoachingSuggestion(
            category: 'general',
            title: 'AI 建议',
            description: aiAdvice,
            priority: 3,
            actionSteps: [],
          ),
        ],
        trainingPlan: null,
        encouragement: null,
        source: 'coze',
        timestamp: DateTime.now(),
        rawResponse: aiAdvice,
      );
    }
  }
}

// ========== 异常类 ==========

/// Coze API 异常
class CozeAPIException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  CozeAPIException(this.message, {this.code, this.originalError});

  factory CozeAPIException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return CozeAPIException(
          '网络超时，请检查网络连接',
          code: 'TIMEOUT',
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 429) {
          return CozeAPIException(
            'API 调用频率过高，请稍后再试',
            code: 'RATE_LIMIT',
            originalError: error,
          );
        } else if (statusCode == 401) {
          return CozeAPIException(
            'API Token 无效或已过期',
            code: 'UNAUTHORIZED',
            originalError: error,
          );
        }
        return CozeAPIException(
          'API 响应错误：$statusCode',
          code: 'BAD_RESPONSE',
          originalError: error,
        );
      default:
        return CozeAPIException(
          '未知错误：${error.message}',
          code: 'UNKNOWN',
          originalError: error,
        );
    }
  }

  @override
  String toString() => 'CozeAPIException($code): $message';
}

// ========== 重试拦截器 ==========

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final LoggerService logger;

  _RetryInterceptor({
    required this.dio,
    required this.retries,
    required this.logger,
  });

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) &&
        (err.requestOptions.extra['retryCount'] ?? 0) < retries) {
      err.requestOptions.extra['retryCount'] =
          (err.requestOptions.extra['retryCount'] ?? 0) + 1;

      final retryCount = err.requestOptions.extra['retryCount'] as int;
      final delay = AIConfig.retryDelaySeconds * retryCount;

      logger.log('重试请求 ($retryCount/$retries)，延迟 ${delay}s',
          level: LogLevel.warning);

      await Future.delayed(Duration(seconds: delay));

      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode ?? 0) >= 500;
  }
}
