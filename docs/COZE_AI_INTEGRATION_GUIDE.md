# 豆包智能体（Coze AI）接入指南

## 📋 目录

1. [概述](#概述)
2. [前置准备](#前置准备)
3. [API接入配置](#api接入配置)
4. [SSE流式响应处理](#sse流式响应处理)
5. [JSON解析策略](#json解析策略)
6. [状态管理](#状态管理)
7. [UI集成](#ui集成)
8. [错误处理](#错误处理)
9. [最佳实践](#最佳实践)
10. [常见问题排查](#常见问题排查)

---

## 概述

本指南总结了Flutter应用接入豆包智能体（Coze AI）的完整流程，包括API调用、流式响应解析、JSON数据处理和UI展示。适用于需要集成智能体对话、分析等AI功能的业务场景。

### 技术栈
- **Flutter/Dart**: 客户端框架
- **Dio**: HTTP客户端（支持流式响应）
- **Riverpod**: 状态管理
- **flutter_dotenv**: 环境变量管理
- **Coze AI**: 豆包智能体平台

### 核心特性
- ✅ SSE（Server-Sent Events）流式响应处理
- ✅ 灵活的JSON格式解析（支持多种字段名和嵌套结构）
- ✅ 独立的分析结果管理（单次分析 vs 周期分析）
- ✅ 智能降级（在线API → 本地AI → 降级策略）
- ✅ 缓存机制（减少重复请求）

---

## 前置准备

### 1. 获取API凭证

前往 [Coze平台](https://www.coze.cn) 创建智能体并获取：
- **API Token**: 认证令牌
- **Project ID**: 项目ID
- **Base URL**: API端点（如 `https://ypcqkgr32q.coze.site`）

### 2. 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  dio: ^5.4.0                    # HTTP客户端
  flutter_riverpod: ^2.4.0       # 状态管理
  flutter_dotenv: ^5.1.0         # 环境变量
  shared_preferences: ^2.2.0     # 缓存
  connectivity_plus: ^5.0.0      # 网络检测
  uuid: ^4.0.0                   # 生成唯一ID

flutter:
  assets:
    - .env
```

### 3. 环境变量配置

创建 `.env` 文件（不要提交到Git）：

```env
COZE_API_TOKEN=your_api_token_here
COZE_BASE_URL=https://ypcqkgr32q.coze.site
COZE_PROJECT_ID=7598068277797060634
```

创建 `.env.example`（提交到Git作为模板）：

```env
COZE_API_TOKEN=your_api_token_here
# COZE_BASE_URL=https://ypcqkgr32q.coze.site
# COZE_PROJECT_ID=your_project_id
```

更新 `.gitignore`：

```
# Environment variables
.env
.env.local
```

---

## API接入配置

### 1. 配置类（AIConfig）

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIConfig {
  // 从环境变量读取配置
  static String get apiToken => dotenv.get('COZE_API_TOKEN', fallback: '');
  static String get baseUrl => dotenv.get('COZE_BASE_URL',
    fallback: 'https://ypcqkgr32q.coze.site');
  static String get projectId => dotenv.get('COZE_PROJECT_ID',
    fallback: '');

  // 超时配置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // 缓存配置
  static const Duration sessionCacheDuration = Duration(hours: 24);
  static const Duration periodCacheDuration = Duration(hours: 6);

  // 重试配置
  static const int maxRetries = 3;
  static const int retryDelaySeconds = 2;

  // 验证配置是否完整
  static bool isConfigured() => apiToken.isNotEmpty && projectId.isNotEmpty;
}
```

### 2. 初始化（main.dart）

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  try {
    await dotenv.load(fileName: '.env');
    print('✅ Environment variables loaded');
  } catch (e) {
    print('⚠️ Failed to load .env file: $e');
  }

  runApp(MyApp());
}
```

### 3. Dio配置（CozeAIService）

```dart
class CozeAIService {
  final Dio _dio;

  CozeAIService({required Dio dio}) : _dio = dio {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.baseUrl = AIConfig.baseUrl;
    _dio.options.connectTimeout = AIConfig.connectionTimeout;
    _dio.options.receiveTimeout = AIConfig.receiveTimeout;
    _dio.options.headers = {
      'Authorization': 'Bearer ${AIConfig.apiToken}',
      'Content-Type': 'application/json',
    };

    // 添加日志拦截器（仅开发环境）
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: false, // SSE响应太大，不记录
      logPrint: (obj) => print('Dio: $obj'),
    ));

    // 添加重试拦截器
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      retries: AIConfig.maxRetries,
    ));
  }
}
```

---

## SSE流式响应处理

### 核心概念

Coze AI 使用 **Server-Sent Events (SSE)** 协议返回流式响应：
- Content-Type: `text/event-stream`
- 格式: `data: {...}\n\n`
- 事件类型: `message_start`, `answer`, `message_end`

### 1. 发起请求（使用ResponseType.stream）

```dart
Future<String> _callCozeAPI(String promptText) async {
  // 生成唯一的session_id
  final sessionId = Uuid().v4().replaceAll('-', '');

  final response = await _dio.post(
    '/stream_run',
    data: {
      'content': {
        'query': {
          'prompt': [
            {
              'type': 'text',
              'content': {'text': promptText},
            },
          ],
        },
      },
      'type': 'query',
      'session_id': sessionId,
      'project_id': AIConfig.projectId,
    },
    // 关键：使用流式响应
    options: Options(responseType: ResponseType.stream),
  );

  if (response.statusCode == 200 && response.data is ResponseBody) {
    // 解析SSE流
    final streamText = await utf8.decoder.bind(response.data.stream).join();
    final answer = _extractAnswerFromSse(streamText);
    return answer.isNotEmpty ? answer : streamText;
  }

  throw Exception('Invalid response');
}
```

### 2. SSE解析实现

```dart
String _extractAnswerFromSse(String streamText) {
  final buffer = StringBuffer();
  final lines = streamText.split(RegExp(r'\r?\n'));

  int eventCount = 0;
  int answerEventCount = 0;

  for (final line in lines) {
    final trimmed = line.trim();

    // 只处理 "data:" 开头的行
    if (!trimmed.startsWith('data:')) continue;

    final data = trimmed.substring(5).trim();
    if (data.isEmpty || data == '[DONE]') continue;

    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      eventCount++;

      final eventType = jsonData['type'] ?? 'unknown';

      // 只有answer类型的事件才包含实际内容
      if (eventType == 'answer') {
        answerEventCount++;
        final answer = _tryExtractAnswer(jsonData);

        if (answer != null && answer.isNotEmpty) {
          buffer.write(answer);
        }
      }
    } catch (e) {
      // 静默处理解析错误
      continue;
    }
  }

  final result = buffer.toString();
  print('✅ SSE解析完成: $eventCount个事件, ${answerEventCount}个answer事件, 提取${result.length}字符');

  return result;
}
```

### 3. 从事件中提取答案

```dart
String? _tryExtractAnswer(Map<String, dynamic> jsonData) {
  // 检查 type == 'answer' 时的 content.answer
  if (jsonData['type'] == 'answer') {
    final content = jsonData['content'];
    if (content is Map) {
      final answer = content['answer'];
      if (answer is String && answer.isNotEmpty) {
        return answer;
      }
    }
  }

  // 尝试其他可能的字段
  final content = jsonData['content'];
  if (content is Map) {
    return content['answer'] ?? content['text'] ?? content['message'];
  }

  return null;
}
```

---

## JSON解析策略

### 核心挑战

智能体返回的JSON格式可能多样化：
- 字段名不统一：`诊断` vs `周期诊断` vs `diagnosis`
- 嵌套结构：`{"周期诊断": {"整体表现": "...", "水平评估": "..."}}`
- 类型不一致：有时是String，有时是Map

### 1. 灵活解析框架

```dart
AICoachResult _parseFlexibleJson(Map<String, dynamic> json) {
  // 诊断：支持多种字段名和嵌套结构
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
  if (json['优势'] is List) {
    strengths = List<String>.from(json['优势']);
  } else if (json['优势分析'] != null) {
    strengths = _extractListFromField(json['优势分析']);
  }

  // 弱点：支持多种字段名
  List<String> weaknesses = [];
  if (json['弱点'] is List) {
    weaknesses = List<String>.from(json['弱点']);
  } else if (json['待改进点'] != null) {
    weaknesses = _extractListFromField(json['待改进点']);
  }

  // 建议：处理List、Map等多种格式
  List<CoachingSuggestion> suggestions = [];
  final suggestionsField = json['建议'] ?? json['改进建议'];

  if (suggestionsField is List) {
    for (var item in suggestionsField) {
      try {
        suggestions.add(CoachingSuggestion.fromJson(item));
      } catch (e) {
        // 解析失败时创建简化版建议
        suggestions.add(_createSimplifiedSuggestion(item));
      }
    }
  } else if (suggestionsField is Map) {
    // Map格式：每个key-value转为一个建议
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

  return AICoachResult(
    diagnosis: diagnosis,
    strengths: strengths,
    weaknesses: weaknesses,
    suggestions: suggestions,
    source: 'coze',
    timestamp: DateTime.now(),
  );
}
```

### 2. 格式化嵌套对象

```dart
/// 提取诊断文本（格式化Map为易读文本）
String _extractDiagnosisText(dynamic diagnosisField) {
  if (diagnosisField is String) {
    return diagnosisField;
  } else if (diagnosisField is Map) {
    // 将Map格式化为：【标题】内容
    final buffer = StringBuffer();
    diagnosisField.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        buffer.write('【$key】$value\n');
      }
    });
    return buffer.toString().trim();
  }
  return diagnosisField.toString();
}

/// 从字段中提取列表（处理List/Map/String）
List<String> _extractListFromField(dynamic field) {
  if (field is List) {
    return field.map((e) => e.toString()).toList();
  } else if (field is Map) {
    // Map转为 "标题：内容" 格式
    final result = <String>[];
    field.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        result.add('$key：$value');
      }
    });
    return result;
  } else if (field is String) {
    return [field];
  }
  return [];
}
```

### 3. 降级处理

```dart
/// 创建简化版建议（当标准解析失败时）
CoachingSuggestion _createSimplifiedSuggestion(Map<String, dynamic> data) {
  final title = data['标题']?.toString() ??
                data['title']?.toString() ??
                '训练建议';

  final description = data['描述']?.toString() ??
                      data['description']?.toString() ??
                      data.values.firstOrNull?.toString() ??
                      '';

  final category = data['类别']?.toString() ??
                   data['category']?.toString() ??
                   'general';

  final priority = data['优先级'] as int? ??
                   data['priority'] as int? ??
                   3;

  return CoachingSuggestion(
    category: category,
    title: title,
    description: description,
    priority: priority,
    actionSteps: [],
  );
}
```

---

## 状态管理

### 1. 状态设计（分离单次和周期分析）

```dart
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
  final String? currentAnalysisId;

  const AICoachState({
    this.sessionResults = const {},
    this.periodResults = const {},
    this.isLoading = false,
    this.error,
    this.loadingMessage,
    this.currentAnalysisType,
    this.currentAnalysisId,
  });

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
```

### 2. 状态更新逻辑

```dart
class AICoachNotifier extends StateNotifier<AICoachState> {
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
      final result = await _smartAIService.analyzeSession(...);

      // 更新该会话的分析结果
      final updatedResults = Map<String, AICoachResult>.from(
        state.sessionResults
      );
      updatedResults[session.id] = result;

      state = state.copyWith(
        sessionResults: updatedResults,
        isLoading: false,
        currentAnalysisType: null,
        currentAnalysisId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
      final result = await _smartAIService.analyzePeriod(...);

      // 更新该周期的分析结果
      final updatedResults = Map<String, AICoachResult>.from(
        state.periodResults
      );
      updatedResults[period] = result;

      state = state.copyWith(
        periodResults: updatedResults,
        isLoading: false,
        currentAnalysisType: null,
        currentAnalysisId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
```

### 3. 缓存策略

```dart
class CacheService {
  static const String _cachePrefix = 'ai_coach_cache_';

  /// 获取缓存
  Future<AICoachResult?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cachePrefix + key;

    final cachedData = prefs.getString(cacheKey);
    if (cachedData == null) return null;

    // 检查是否过期
    final timestamp = prefs.getInt(cacheKey + '_timestamp');
    if (timestamp == null) {
      await _remove(key);
      return null;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > timestamp) {
      await _remove(key);
      return null;
    }

    // 解析并返回
    final jsonData = jsonDecode(cachedData);
    return AICoachResult.fromJson(jsonData);
  }

  /// 设置缓存
  Future<bool> set(String key, AICoachResult value, {
    Duration duration = const Duration(hours: 24),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cachePrefix + key;

    // 计算过期时间
    final expiryTime = DateTime.now()
        .add(duration)
        .millisecondsSinceEpoch;

    // 保存数据和时间戳
    await prefs.setString(cacheKey, jsonEncode(value.toJson()));
    await prefs.setInt(cacheKey + '_timestamp', expiryTime);

    return true;
  }
}
```

**缓存键设计：**
- 单次训练：`session_${sessionId}_${language}`
- 周期分析：`period_${period}_${language}`

---

## UI集成

### 1. 详情页（单次训练分析）

```dart
Widget _buildAICoachDeepAnalysis(TrainingSession session, WidgetRef ref) {
  final aiCoachState = ref.watch(aiCoachProvider);

  // 获取当前会话的分析结果
  final sessionResult = aiCoachState.getSessionResult(session.id);
  final isAnalyzing = aiCoachState.isAnalyzingSession(session.id);

  return Container(
    child: Column(
      children: [
        // Header with analyze button
        Row(
          children: [
            Text('AI 教练深度分析'),
            if (!isAnalyzing && sessionResult == null)
              ElevatedButton(
                onPressed: () {
                  ref.read(aiCoachProvider.notifier)
                     .analyzeSession(session);
                },
                child: Text('深度分析'),
              ),
          ],
        ),

        // Content area
        if (isAnalyzing)
          AILoadingWidget(message: aiCoachState.loadingMessage)
        else if (sessionResult != null)
          AIResultCard(
            result: sessionResult,
            onDismiss: () {
              ref.read(aiCoachProvider.notifier)
                 .clearSessionResult(session.id);
            },
          )
        else
          Text('点击"深度分析"获取专业建议'),
      ],
    ),
  );
}
```

### 2. 统计页（周期分析）

```dart
Widget _buildAICoachSection(WidgetRef ref, String selectedPeriod) {
  final aiCoachState = ref.watch(aiCoachProvider);

  // 获取当前周期的分析结果
  final periodResult = aiCoachState.getPeriodResult(selectedPeriod);
  final isAnalyzing = aiCoachState.isAnalyzingPeriod(selectedPeriod);

  return ArcheryCard(
    child: Column(
      children: [
        // Header
        Row(
          children: [
            Text('AI 教练周期分析'),
            if (!isAnalyzing && periodResult == null)
              ElevatedButton(
                onPressed: () {
                  ref.read(aiCoachProvider.notifier)
                     .analyzePeriod(selectedPeriod);
                },
                child: Text('分析'),
              ),
          ],
        ),

        // Content
        if (isAnalyzing)
          AILoadingWidget(message: aiCoachState.loadingMessage)
        else if (periodResult != null)
          Column(
            children: [
              AIResultCard(result: periodResult),
              ElevatedButton(
                onPressed: () {
                  ref.read(aiCoachProvider.notifier)
                     .analyzePeriod(selectedPeriod);
                },
                child: Text('重新分析'),
              ),
            ],
          ),
      ],
    ),
  );
}
```

### 3. 结果展示组件（AIResultCard）

```dart
class AIResultCard extends StatelessWidget {
  final AICoachResult result;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // 核心诊断
          _buildDiagnosisSection(result.diagnosis),

          // 优势点
          if (result.strengths.isNotEmpty)
            _buildStrengthsSection(result.strengths),

          // 待改进点
          if (result.weaknesses.isNotEmpty)
            _buildWeaknessesSection(result.weaknesses),

          // 改进建议
          if (result.suggestions.isNotEmpty)
            _buildSuggestionsSection(result.suggestions),

          // 鼓励语
          if (result.encouragement != null)
            Text(result.encouragement!, style: encouragementStyle),
        ],
      ),
    );
  }
}
```

---

## 错误处理

### 1. 异常定义

```dart
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
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return CozeAPIException(
            'API Token 无效或已过期',
            code: 'UNAUTHORIZED',
          );
        } else if (statusCode == 429) {
          return CozeAPIException(
            'API 调用频率过高，请稍后再试',
            code: 'RATE_LIMIT',
          );
        }
        return CozeAPIException(
          'API 响应错误：$statusCode',
          code: 'BAD_RESPONSE',
        );

      default:
        return CozeAPIException(
          '未知错误：${error.message}',
          code: 'UNKNOWN',
        );
    }
  }

  @override
  String toString() => 'CozeAPIException($code): $message';
}
```

### 2. 重试机制

```dart
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) &&
        (err.requestOptions.extra['retryCount'] ?? 0) < retries) {

      final retryCount = (err.requestOptions.extra['retryCount'] ?? 0) + 1;
      err.requestOptions.extra['retryCount'] = retryCount;

      final delay = AIConfig.retryDelaySeconds * retryCount;
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
           (err.response?.statusCode ?? 0) >= 500;
  }
}
```

### 3. 智能降级

```dart
class SmartAIService {
  /// 优先使用在线AI，失败时自动降级到本地AI
  Future<AICoachResult> analyzeSession(
    TrainingSession session,
    List<TrainingSession> historicalSessions,
    String language,
  ) async {
    // 检查网络状态
    final isOnline = await _networkService.isNetworkAvailable();

    if (isOnline) {
      try {
        // 尝试使用在线 Coze AI
        return await _cozeService.analyzeSession(session, language);
      } catch (e) {
        // 在线分析失败，降级到本地
        return await _localService.analyzeSession(
          session,
          historicalSessions
        );
      }
    } else {
      // 网络不可用，直接使用本地 AI
      return await _localService.analyzeSession(
        session,
        historicalSessions
      );
    }
  }
}
```

---

## 最佳实践

### 1. 日志管理

**开发环境：详细日志**
```dart
_logger.log('🔄 开始解析SSE响应，长度: ${streamText.length}',
  level: LogLevel.debug);
_logger.log('✅ JSON解析成功，顶层字段: ${jsonData.keys.toList()}',
  level: LogLevel.debug);
```

**生产环境：精简日志**
```dart
_logger.log('✅ SSE解析完成: $eventCount个事件, 提取${result.length}字符',
  level: LogLevel.info);
```

**不要输出敏感信息：**
```dart
// ❌ 错误：输出完整AI回复
_logger.log('完整AI回复:\n$aiAdvice', level: LogLevel.debug);

// ✅ 正确：只输出长度
_logger.log('收到AI回复，长度: ${aiAdvice.length}字符', level: LogLevel.debug);
```

### 2. 性能优化

**缓存策略：**
- 单次训练分析：24小时缓存
- 周期分析：6小时缓存
- 使用独立的缓存键（session ID + language）

**网络优化：**
- 使用流式响应（ResponseType.stream）
- 合理设置超时时间（连接30s，接收60s）
- 实现重试机制（最多3次，指数退避）

**UI优化：**
- 按需加载（点击分析按钮时才调用API）
- 独立状态管理（避免不同页面结果互相覆盖）
- 加载状态提示（AILoadingWidget）

### 3. 安全性

**API密钥管理：**
```dart
// ✅ 正确：使用环境变量
static String get apiToken => dotenv.get('COZE_API_TOKEN');

// ❌ 错误：硬编码
static const String apiToken = 'your_token_here';
```

**输入验证：**
```dart
if (!AIConfig.isConfigured()) {
  throw CozeAPIException('API 配置未完成，请填写 API Token');
}
```

**错误提示用户友好：**
```dart
// ❌ 错误：直接显示技术错误
Text('DioException: SocketException: Connection refused');

// ✅ 正确：友好提示
Text('网络连接失败，请检查网络设置');
```

---

## 常见问题排查

### 问题1：UI显示原始JSON结构

**症状：**
```
"{\"周期诊断\": {\"整体表现\": \"中级水平\"}, ...}"
```

**原因：** Map对象直接toString()

**解决：** 使用格式化方法
```dart
String _extractDiagnosisText(dynamic field) {
  if (field is Map) {
    final buffer = StringBuffer();
    field.forEach((key, value) {
      buffer.write('【$key】$value\n');
    });
    return buffer.toString().trim();
  }
  return field.toString();
}
```

### 问题2：SSE解析提取0字符

**症状：**
```
SSE解析完成，共2个事件，提取内容长度: 0
```

**原因：** 事件类型不匹配（只解析`answer`类型）

**解决：**
```dart
// 检查事件类型
if (eventType == 'answer') {
  final answer = _tryExtractAnswer(jsonData);
  if (answer != null) {
    buffer.write(answer);
  }
}
```

### 问题3：不同页面分析结果互相覆盖

**症状：** 详情页显示周期分析结果

**原因：** 共用同一个`latestResult`字段

**解决：** 分离状态存储
```dart
class AICoachState {
  final Map<String, AICoachResult> sessionResults;  // 单次分析
  final Map<String, AICoachResult> periodResults;   // 周期分析
}
```

### 问题4：缓存导致数据不更新

**症状：** 重新分析仍显示旧数据

**原因：** 缓存键设计不合理

**解决：**
```dart
// ❌ 错误：使用日期作为缓存键（同一天共享）
final cacheKey = 'period_${DateTime.now().day}_$language';

// ✅ 正确：使用period作为缓存键（不同周期独立）
final cacheKey = 'period_${period}_$language';
```

### 问题5：API调用401错误

**症状：** `API Token 无效或已过期`

**检查清单：**
1. `.env` 文件是否存在且加载成功
2. `COZE_API_TOKEN` 是否填写正确
3. Token是否已过期（前往Coze平台检查）
4. Base URL是否正确

---

## 总结

### 关键技术点

1. **SSE流式响应处理**
   - 使用 `ResponseType.stream`
   - UTF-8解码流数据
   - 按行解析 `data:` 开头的事件
   - 只提取 `type: answer` 的事件内容

2. **灵活的JSON解析**
   - 支持多种字段名（中文/英文）
   - 处理嵌套对象（Map → 格式化文本）
   - 降级处理（解析失败时创建简化版）

3. **独立的状态管理**
   - 分离单次分析和周期分析
   - 使用Map存储多个分析结果
   - 跟踪当前分析任务（type + id）

4. **智能降级策略**
   - 在线API → 本地AI → 降级默认
   - 网络检测 + 异常捕获
   - 用户友好的错误提示

### 快速接入步骤

1. ✅ 配置环境变量（.env文件）
2. ✅ 添加依赖（dio, riverpod, dotenv）
3. ✅ 创建CozeAIService（SSE解析 + JSON解析）
4. ✅ 实现状态管理（AICoachProvider）
5. ✅ 集成UI组件（加载/结果/错误）
6. ✅ 测试和优化（日志、缓存、降级）

### 参考资料

- Coze平台: https://www.coze.cn
- SSE规范: https://html.spec.whatwg.org/multipage/server-sent-events.html
- Dio文档: https://pub.dev/packages/dio
- Riverpod文档: https://riverpod.dev

---

**最后更新：** 2026-01-25
**版本：** v1.0
**作者：** ArcheryPro Team
