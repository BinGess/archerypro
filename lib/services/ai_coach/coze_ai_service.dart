import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/training_session.dart';
import '../../models/ai_coach/ai_coach_result.dart';
import '../logger_service.dart';
import '../../utils/ai_config.dart';
import 'cache_service.dart';

/// Coze AI 服务 - 扣子智能体 API 集成
class CozeAIService {
  final Dio _dio;
  final CacheService _cache;
  final LoggerService _logger;

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
      'Authorization': 'Bearer ${AIConfig.apiKey}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 日志拦截器
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
      throw CozeAPIException('API 配置未完成，请填写 API Key 和 Bot ID');
    }

    // 检查缓存
    final cacheKey = 'session_${session.id}_$language';
    final cached = await _cache.get<AICoachResult>(cacheKey);
    if (cached != null) {
      _logger.log('使用缓存结果', level: LogLevel.info);
      return cached;
    }

    String? conversationId;
    try {
      // 1. 创建会话
      conversationId = await _createConversation();
      if (conversationId == null) {
        throw CozeAPIException('创建会话失败', code: 'CREATE_CONV_FAILED');
      }

      // 2. 构建训练数据 JSON
      final trainingData = _buildSessionDataJson(session, language);

      // 3. 发送消息并获取建议
      final aiAdvice = await _sendMessage(
        conversationId,
        trainingData,
        stream: false,
      );

      // 4. 解析 AI 建议为结构化结果
      final result = _parseAIAdvice(aiAdvice, language);

      // 5. 缓存结果（24小时）
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
    } finally {
      // 6. 关闭会话（释放资源）
      if (conversationId != null) {
        await _closeConversation(conversationId).catchError((_) {});
      }
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
      throw CozeAPIException('API 配置未完成，请填写 API Key 和 Bot ID');
    }

    final cacheKey = 'period_${DateTime.now().day}_$language';
    final cached = await _cache.get<AICoachResult>(cacheKey);
    if (cached != null) return cached;

    String? conversationId;
    try {
      conversationId = await _createConversation();
      if (conversationId == null) throw CozeAPIException('创建会话失败');

      final periodData = _buildPeriodDataJson(stats, recentSessions, language);
      final aiAdvice = await _sendMessage(conversationId, periodData);
      final result = _parseAIAdvice(aiAdvice, language);

      await _cache.set(
        cacheKey,
        result,
        duration: AIConfig.periodCacheDuration,
      );

      return result;
    } finally {
      if (conversationId != null) {
        await _closeConversation(conversationId).catchError((_) {});
      }
    }
  }

  // ========== 核心 API 调用方法 ==========

  /// 创建会话
  Future<String?> _createConversation() async {
    try {
      final response = await _dio.post(
        '/conversation/create',
        data: {
          'bot_id': AIConfig.botId,
          'user_id': AIConfig.userId,
          'conversation_id': '', // 空值表示新建
          'meta_data': AIConfig.getUserMetadata(),
        },
      );

      if (response.data['code'] == 0) {
        return response.data['data']['conversation_id'];
      } else {
        _logger.log(
          'Coze API 返回错误',
          level: LogLevel.error,
          error: response.data['msg'],
        );
        return null;
      }
    } on DioException catch (e) {
      throw CozeAPIException.fromDioError(e);
    }
  }

  /// 发送消息
  Future<String> _sendMessage(
    String conversationId,
    Map<String, dynamic> data, {
    bool stream = false,
  }) async {
    try {
      final response = await _dio.post(
        '/conversation/message/create',
        data: {
          'conversation_id': conversationId,
          'bot_id': AIConfig.botId,
          'user_id': AIConfig.userId,
          'content': jsonEncode(data), // 转为 JSON 字符串
          'content_type': 'text',
          'stream': stream,
        },
      );

      if (response.data['code'] == 0) {
        final messages = response.data['data']['messages'] as List;
        if (messages.isNotEmpty) {
          return messages[0]['content'] as String;
        }
        throw CozeAPIException('未收到 AI 回复');
      } else {
        throw CozeAPIException(
          response.data['msg'],
          code: response.data['code'].toString(),
        );
      }
    } on DioException catch (e) {
      throw CozeAPIException.fromDioError(e);
    }
  }

  /// 关闭会话
  Future<bool> _closeConversation(String conversationId) async {
    try {
      final response = await _dio.post(
        '/conversation/close',
        data: {
          'conversation_id': conversationId,
          'bot_id': AIConfig.botId,
          'user_id': AIConfig.userId,
        },
      );

      return response.data['code'] == 0 &&
          response.data['data']['success'] == true;
    } catch (e) {
      _logger.log('关闭会话失败', level: LogLevel.error, error: e);
      return false;
    }
  }

  // ========== 数据构建方法 ==========

  /// 构建单次训练数据 JSON
  Map<String, dynamic> _buildSessionDataJson(
    TrainingSession session,
    String language,
  ) {
    return {
      '分析类型': '单次训练分析',
      '语言要求': language == 'zh' ? '请用中文回复' : 'Please respond in English',
      '训练信息': {
        '日期': session.date.toString().split(' ')[0],
        '距离': '${session.distance}米',
        '靶面': '${session.targetFaceSize}厘米',
      },
      '表现数据': {
        '总分': session.totalScore,
        '最高分': session.maxScore,
        '箭数': session.arrowCount,
        '平均分': session.averageArrowScore.toStringAsFixed(2),
        '稳定性': '${session.consistency.toStringAsFixed(1)}%',
        '10环率': '${session.tenRingRate.toStringAsFixed(1)}%',
        '得分率': '${session.scorePercentage.toStringAsFixed(1)}%',
      },
      '高级指标': {
        '分数分布': session.scoreDistribution,
        '象限分布': session.quadrantDistribution,
        '前三分之一平均': session.firstThirdAverage?.toStringAsFixed(2),
        '后三分之一平均': session.lastThirdAverage?.toStringAsFixed(2),
      },
      '分析需求': language == 'zh'
          ? '请详细分析这次训练的表现，包括：1) 核心诊断（2-3句话）；2) 3个优势点；3) 3个待改进点；4) 3-5条具体改进建议（每条包含类别、标题、描述、优先级、行动步骤）；5) 一句鼓励的话'
          : 'Please analyze this training session in detail, including: 1) Core diagnosis (2-3 sentences); 2) 3 strengths; 3) 3 areas for improvement; 4) 3-5 specific suggestions (each with category, title, description, priority, action steps); 5) An encouraging message',
    };
  }

  /// 构建周期数据 JSON
  Map<String, dynamic> _buildPeriodDataJson(
    dynamic stats,
    List<TrainingSession> recentSessions,
    String language,
  ) {
    return {
      '分析类型': '周期表现分析',
      '语言要求': language == 'zh' ? '请用中文回复' : 'Please respond in English',
      '周期信息': {
        '总训练次数': recentSessions.length,
        '总箭数': recentSessions.fold<int>(
            0, (sum, s) => sum + s.arrowCount),
      },
      '整体表现': {
        '平均分': _calculateAverage(recentSessions).toStringAsFixed(2),
        '趋势': _calculateTrend(recentSessions) > 0 ? '上升' : '下降',
      },
      '最近训练': recentSessions.take(5).map((s) {
        return {
          '日期': s.date.toString().split(' ')[0],
          '总分': s.totalScore,
          '平均分': s.averageArrowScore.toStringAsFixed(2),
          '稳定性': '${s.consistency.toStringAsFixed(1)}%',
        };
      }).toList(),
      '分析需求': language == 'zh'
          ? '请分析这段时间的整体表现趋势，给出诊断、优势、待改进点和具体建议，并生成一个4周的训练计划（包含2-3个阶段，每个阶段包含具体的训练项目、箭数、频率）'
          : 'Please analyze the overall performance trend, provide diagnosis, strengths, areas for improvement, specific suggestions, and generate a 4-week training plan (2-3 phases, each with specific drills, arrows, frequency)',
    };
  }

  /// 计算平均分
  double _calculateAverage(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0.0;
    final total = sessions.fold<double>(
        0.0, (sum, s) => sum + s.averageArrowScore);
    return total / sessions.length;
  }

  /// 计算趋势
  double _calculateTrend(List<TrainingSession> sessions) {
    if (sessions.length < 2) return 0.0;
    final first = sessions.last.averageArrowScore;
    final last = sessions.first.averageArrowScore;
    return last - first;
  }

  /// 解析 AI 建议
  AICoachResult _parseAIAdvice(String aiAdvice, String language) {
    _logger.log('解析 AI 回复: ${aiAdvice.substring(0, aiAdvice.length > 100 ? 100 : aiAdvice.length)}...', level: LogLevel.debug);

    try {
      // 尝试解析为 JSON
      final jsonData = jsonDecode(aiAdvice);
      return AICoachResult.fromCozeJson(jsonData, 'coze');
    } catch (e) {
      // 如果不是 JSON 格式，创建基于文本的简化结果
      _logger.log('AI 回复不是 JSON 格式，使用文本解析', level: LogLevel.warning);
      return AICoachResult(
        diagnosis: aiAdvice,
        strengths: [],
        weaknesses: [],
        suggestions: [],
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
