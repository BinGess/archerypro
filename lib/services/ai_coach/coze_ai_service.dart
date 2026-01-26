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
    String period,
    dynamic stats,
    List<TrainingSession> recentSessions,
    String language,
  ) async {
    _logger.log('开始分析周期表现: $period', level: LogLevel.info);

    // 检查 API 配置
    if (!AIConfig.isConfigured()) {
      throw CozeAPIException('API 配置未完成，请填写 API Token');
    }

    // 使用period和语言作为缓存键，确保不同周期有独立缓存
    final cacheKey = 'period_${period}_$language';
    final cached = await _cache.get<AICoachResult>(cacheKey);
    if (cached != null) {
      _logger.log('使用缓存的周期分析结果', level: LogLevel.info);
      return cached;
    }

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
        options: Options(responseType: ResponseType.stream),
      );

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is ResponseBody) {
          final streamText = await utf8.decoder.bind(responseData.stream).join();
          final answer = _extractAnswerFromSse(streamText);

          // 如果无法提取answer，抛出异常而不是返回原始响应
          if (answer.isEmpty) {
            _logger.log('❌ 无法从SSE响应中提取有效内容', level: LogLevel.error);
            throw CozeAPIException(
              'AI 响应格式异常，无法解析内容',
              code: 'INVALID_RESPONSE_FORMAT',
            );
          }

          return answer;
        }

        if (responseData is Map) {
          final text = responseData['text'] ??
              responseData['content'] ??
              responseData['response'] ??
              '';

          if (text.isEmpty) {
            throw CozeAPIException(
              'AI 响应内容为空',
              code: 'EMPTY_RESPONSE',
            );
          }

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

  String _extractAnswerFromSse(String streamText) {
    _logger.log('🔄 开始解析SSE响应，长度: ${streamText.length}', level: LogLevel.debug);

    final buffer = StringBuffer();
    final lines = streamText.split(RegExp(r'\r?\n'));

    int eventCount = 0;
    int answerEventCount = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) {
        continue;
      }

      final data = trimmed.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') {
        continue;
      }

      try {
        final jsonData = jsonDecode(data);
        if (jsonData is! Map<String, dynamic>) {
          continue;
        }

        eventCount++;
        final eventType = jsonData['type'] ?? 'unknown';

        // 只有answer类型的事件才尝试提取内容
        if (eventType == 'answer') {
          answerEventCount++;
          final String? answer = _tryExtractAnswer(jsonData);

          if (answer != null && answer.isNotEmpty) {
            buffer.write(answer);
          }
        }
      } catch (e) {
        // 静默处理解析错误，避免日志干扰
        continue;
      }
    }

    final result = buffer.toString();
    _logger.log('✅ SSE解析完成: $eventCount个事件, ${answerEventCount}个answer事件, 提取${result.length}字符', level: LogLevel.info);

    // 如果没有提取到内容，输出警告但不显示原始数据
    if (result.isEmpty && streamText.isNotEmpty) {
      _logger.log('⚠️ 未从SSE响应中提取到内容，请检查API返回格式', level: LogLevel.warning);
    }

    return result;
  }

  /// 尝试从多个可能的位置提取 answer
  String? _tryExtractAnswer(Map<String, dynamic> jsonData) {
    // 方法1: 检查 type == 'answer'
    if (jsonData['type'] == 'answer') {
      final content = jsonData['content'];
      if (content is Map) {
        final answer = content['answer'];
        if (answer is String && answer.isNotEmpty) {
          return answer;
        }
      }
    }

    // 方法2: 检查 content.answer
    final content = jsonData['content'];
    if (content is Map) {
      final answer = content['answer'];
      if (answer is String && answer.isNotEmpty) {
        return answer;
      }

      // 方法3: 检查 content.text
      final text = content['text'];
      if (text is String && text.isNotEmpty) {
        return text;
      }

      // 方法4: 检查 content.message
      final message = content['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    // 方法5: 直接检查 answer 字段
    final answer = jsonData['answer'];
    if (answer is String && answer.isNotEmpty) {
      return answer;
    }

    // 方法6: 检查 text 字段
    final text = jsonData['text'];
    if (text is String && text.isNotEmpty) {
      return text;
    }

    // 方法7: 检查 message 字段
    final message = jsonData['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return null;
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
    // 输出AI回复长度（不输出完整内容避免干扰）
    _logger.log('📝 收到AI回复，长度: ${aiAdvice.length}字符', level: LogLevel.debug);

    try {
      // 尝试提取JSON（AI可能返回包含markdown的文本）
      String jsonStr = aiAdvice;

      // 如果包含markdown代码块，提取JSON部分
      if (aiAdvice.contains('```json')) {
        final jsonMatch = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```').firstMatch(aiAdvice);
        if (jsonMatch != null) {
          jsonStr = jsonMatch.group(1) ?? aiAdvice;
          _logger.log('✅ 从markdown代码块中提取JSON', level: LogLevel.debug);
        }
      } else if (aiAdvice.contains('```')) {
        final jsonMatch = RegExp(r'```\s*(\{[\s\S]*?\})\s*```').firstMatch(aiAdvice);
        if (jsonMatch != null) {
          jsonStr = jsonMatch.group(1) ?? aiAdvice;
          _logger.log('✅ 从代码块中提取JSON', level: LogLevel.debug);
        }
      }

      // 如果整个字符串看起来像JSON，直接解析
      jsonStr = jsonStr.trim();
      if (jsonStr.startsWith('{')) {
        final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
        _logger.log('✅ JSON解析成功，顶层字段: ${jsonData.keys.toList()}', level: LogLevel.debug);

        // 尝试标准格式解析
        final result = _parseFlexibleJson(jsonData);
        _logger.log('✅ AI建议解析完成: 诊断=${result.diagnosis.isNotEmpty}, 优势=${result.strengths.length}, 弱点=${result.weaknesses.length}, 建议=${result.suggestions.length}', level: LogLevel.info);
        return result;
      }

      // 如果解析失败，返回基于文本的简化结果
      throw FormatException('无法解析为JSON');
    } catch (e, stackTrace) {
      _logger.log('❌ AI回复解析失败', level: LogLevel.warning, error: e);
      // 只在debug级别输出堆栈信息
      if (e is FormatException) {
        _logger.log('JSON格式错误: ${e.message}', level: LogLevel.debug);
      }

      // 检查是否是原始SSE响应（包含event/data格式）
      final isRawSseResponse = aiAdvice.contains('event:') &&
          aiAdvice.contains('data:') &&
          aiAdvice.contains('session_id');

      // 如果是原始SSE响应，说明提取失败，应该抛出异常而不是显示原始内容
      if (isRawSseResponse) {
        _logger.log('⚠️ 检测到未处理的SSE原始响应，抛出异常', level: LogLevel.warning);
        throw CozeAPIException(
          'AI 响应解析失败，请稍后重试',
          code: 'PARSE_ERROR',
        );
      }

      // 对于其他情况，尝试提取可能的有用文本
      String friendlyDiagnosis = 'AI 分析暂时无法完成，请稍后重试';

      // 如果文本不太长且不包含大量JSON特征，可以展示
      if (aiAdvice.length < 500 &&
          !aiAdvice.contains('{') &&
          !aiAdvice.contains('[')) {
        friendlyDiagnosis = aiAdvice.trim();
      } else if (aiAdvice.contains('诊断') || aiAdvice.contains('diagnosis')) {
        // 尝试提取可能的文本描述
        final lines = aiAdvice.split('\n');
        for (var line in lines) {
          if (line.trim().isNotEmpty &&
              !line.trim().startsWith('{') &&
              !line.trim().startsWith('[') &&
              line.length < 200) {
            friendlyDiagnosis = line.trim();
            break;
          }
        }
      }

      // 返回友好的错误结果
      return AICoachResult(
        diagnosis: friendlyDiagnosis,
        strengths: [],
        weaknesses: [],
        suggestions: [
          CoachingSuggestion(
            category: 'general',
            title: '温馨提示',
            description: '本次AI分析未能成功解析响应内容，建议重新分析或稍后再试',
            priority: 3,
            actionSteps: ['点击"重新分析"按钮', '检查网络连接', '稍后再次尝试'],
          ),
        ],
        trainingPlan: null,
        encouragement: '继续保持训练，数据积累后分析会更准确',
        source: 'coze',
        timestamp: DateTime.now(),
        rawResponse: aiAdvice,
      );
    }
  }

  /// 灵活解析JSON，兼容多种格式
  AICoachResult _parseFlexibleJson(Map<String, dynamic> json) {
    // 诊断：支持多种字段名
    String diagnosis = '';
    if (json['诊断'] != null) {
      diagnosis = _extractDiagnosisText(json['诊断']);
    } else if (json['diagnosis'] != null) {
      diagnosis = _extractDiagnosisText(json['diagnosis']);
    } else if (json['周期诊断'] != null) {
      diagnosis = _extractDiagnosisText(json['周期诊断']);
    } else if (json['单次诊断'] != null) {
      diagnosis = _extractDiagnosisText(json['单次诊断']);
    }

    // 优势：支持多种字段名
    List<String> strengths = [];
    if (json['优势'] != null && json['优势'] is List) {
      strengths = List<String>.from(json['优势']);
    } else if (json['strengths'] != null && json['strengths'] is List) {
      strengths = List<String>.from(json['strengths']);
    } else if (json['优势分析'] != null) {
      strengths = _extractListFromField(json['优势分析']);
    } else if (json['优势点分析'] != null) {
      strengths = _extractListFromField(json['优势点分析']);
    }

    // 弱点：支持多种字段名
    List<String> weaknesses = [];
    if (json['弱点'] != null && json['弱点'] is List) {
      weaknesses = List<String>.from(json['弱点']);
    } else if (json['weaknesses'] != null && json['weaknesses'] is List) {
      weaknesses = List<String>.from(json['weaknesses']);
    } else if (json['待改进点'] != null) {
      weaknesses = _extractListFromField(json['待改进点']);
    } else if (json['改进点'] != null) {
      weaknesses = _extractListFromField(json['改进点']);
    } else if (json['待改进点分析'] != null) {
      weaknesses = _extractListFromField(json['待改进点分析']);
    }

    // 建议：支持多种字段名
    List<CoachingSuggestion> suggestions = [];

    // 尝试从多个可能的字段提取建议
    dynamic suggestionsField = json['建议'] ?? json['suggestions'] ?? json['改进建议'];

    if (suggestionsField != null) {
      if (suggestionsField is List) {
        for (var item in suggestionsField) {
          try {
            suggestions.add(CoachingSuggestion.fromJson(item));
          } catch (e) {
            _logger.log('⚠️ 建议项解析失败: $e', level: LogLevel.debug);
            // 如果解析失败，尝试创建简化版建议
            if (item is Map<String, dynamic>) {
              suggestions.add(_createSimplifiedSuggestion(item));
            }
          }
        }
      } else if (suggestionsField is Map) {
        // 如果建议是Map格式，将每个key-value转为一个建议
        suggestionsField.forEach((key, value) {
          suggestions.add(CoachingSuggestion(
            category: 'general',
            title: key.toString(),
            description: value.toString(),
            priority: 3,
            actionSteps: [],
          ));
        });
      }
    }

    // 如果没有找到建议，但有优势和弱点，至少要有一个通用建议
    if (suggestions.isEmpty && (strengths.isNotEmpty || weaknesses.isNotEmpty)) {
      suggestions.add(CoachingSuggestion(
        category: 'general',
        title: '继续训练',
        description: '保持当前训练节奏，关注数据反馈，持续改进',
        priority: 3,
        actionSteps: ['保持规律训练', '关注弱点改进', '巩固优势表现'],
      ));
    }

    // 训练计划
    TrainingPlan? trainingPlan;
    final planField = json['训练计划'] ?? json['trainingPlan'] ?? json['4周训练计划'];

    if (planField != null) {
      try {
        trainingPlan = TrainingPlan.fromJson(planField);
      } catch (e) {
        _logger.log('⚠️ 训练计划解析失败: $e', level: LogLevel.debug);
        // 训练计划解析失败时不创建默认计划，保持为null
      }
    }

    // 鼓励语
    String? encouragement = json['鼓励'] ?? json['encouragement'] ?? json['鼓励语'];

    return AICoachResult(
      diagnosis: diagnosis,
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: suggestions,
      trainingPlan: trainingPlan,
      encouragement: encouragement,
      source: 'coze',
      timestamp: DateTime.now(),
      rawResponse: json.toString(),
    );
  }

  /// 提取诊断文本（格式化嵌套对象）
  String _extractDiagnosisText(dynamic diagnosisField) {
    if (diagnosisField is String) {
      return diagnosisField;
    } else if (diagnosisField is Map) {
      // 将Map格式化为易读文本
      final buffer = StringBuffer();
      diagnosisField.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          // 格式：【标题】内容
          buffer.write('【$key】$value\n');
        }
      });
      return buffer.toString().trim();
    }
    return diagnosisField.toString();
  }

  /// 创建简化版建议（当标准解析失败时）
  CoachingSuggestion _createSimplifiedSuggestion(Map<String, dynamic> data) {
    // 尝试提取可能的字段
    final title = data['标题']?.toString() ??
                  data['title']?.toString() ??
                  data['名称']?.toString() ??
                  '训练建议';

    final description = data['描述']?.toString() ??
                        data['description']?.toString() ??
                        data['内容']?.toString() ??
                        data.values.firstOrNull?.toString() ??
                        '';

    final category = data['类别']?.toString() ??
                     data['category']?.toString() ??
                     'general';

    final priority = data['优先级'] as int? ??
                     data['priority'] as int? ??
                     3;

    List<String> actionSteps = [];
    final stepsField = data['行动步骤'] ?? data['actionSteps'] ?? data['步骤'];
    if (stepsField is List) {
      actionSteps = stepsField.map((e) => e.toString()).toList();
    }

    return CoachingSuggestion(
      category: category,
      title: title,
      description: description,
      priority: priority,
      actionSteps: actionSteps,
    );
  }

  /// 从字段中提取列表（处理嵌套对象或数组）
  List<String> _extractListFromField(dynamic field) {
    if (field is List) {
      return field.map((e) => e.toString()).toList();
    } else if (field is Map) {
      // 将Map的key-value转换为格式化字符串
      final result = <String>[];
      field.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          // 格式：标题：内容
          result.add('$key：$value');
        }
      });
      return result;
    } else if (field is String) {
      return [field];
    }
    return [];
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
