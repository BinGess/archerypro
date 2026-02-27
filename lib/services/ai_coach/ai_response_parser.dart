import 'dart:convert';

import '../../models/ai_coach/ai_coach_result.dart';
import '../logger_service.dart';
import 'coze_api_exception.dart';

/// 智能体响应解析器：SSE 提取 + JSON 抽取/修复 + 字段归一化
class AiResponseParser {
  final LoggerService _logger;

  const AiResponseParser({required LoggerService logger}) : _logger = logger;

  /// 从 SSE 文本中提取最终答案
  String extractAnswerFromSse(String streamText) {
    _logger.log('🔄 开始解析SSE响应，长度: ${streamText.length}', level: LogLevel.debug);

    final lines = streamText.split(RegExp(r'\r?\n'));
    String currentEvent = 'unknown';
    final currentDataLines = <String>[];
    final deltaBuffer = StringBuffer();
    String? completedAnswer;
    int eventCount = 0;
    int textEventCount = 0;
    final eventTypeStats = <String, int>{};

    void flushCurrentEvent() {
      if (currentDataLines.isEmpty) return;
      final payloadText = currentDataLines.join('\n').trim();
      currentDataLines.clear();
      if (payloadText.isEmpty || payloadText == '[DONE]') return;

      eventCount++;

      Map<String, dynamic> jsonData;
      try {
        final decoded = jsonDecode(payloadText);
        if (decoded is! Map<String, dynamic>) return;
        jsonData = decoded;
      } catch (e) {
        _logger.log('SSE单条解析失败，已忽略: $e', level: LogLevel.debug);
        return;
      }

      final jsonType = (jsonData['type'] ?? '').toString().trim();
      final eventType = jsonType.isNotEmpty ? jsonType : currentEvent;
      eventTypeStats[eventType] = (eventTypeStats[eventType] ?? 0) + 1;

      _throwIfSseEventHasError(
        data: jsonData,
        sseEvent: currentEvent,
        jsonType: jsonType,
      );

      if (!_isTextBearingEvent(
        sseEvent: currentEvent,
        jsonType: jsonType,
        payload: jsonData,
      )) {
        return;
      }

      final answer = _tryExtractAnswer(jsonData);
      if (answer == null || answer.isEmpty) return;

      textEventCount++;

      if (_isCompletionEvent(currentEvent, jsonType)) {
        completedAnswer = answer;
      } else {
        deltaBuffer.write(answer);
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flushCurrentEvent();
        continue;
      }

      if (line.startsWith('event:')) {
        flushCurrentEvent();
        currentEvent = line.substring(6).trim();
        continue;
      }

      if (line.startsWith('data:')) {
        currentDataLines.add(line.substring(5).trim());
      }
    }

    flushCurrentEvent();

    final answer = completedAnswer ?? deltaBuffer.toString();
    _logger.log(
      '✅ SSE解析完成: $eventCount个事件, $textEventCount个文本事件, 提取${answer.length}字符, 事件分布: $eventTypeStats',
      level: LogLevel.info,
    );

    return answer;
  }

  /// 将 AI 原始输出解析并归一化为统一领域对象
  AICoachResult parseCoachResult({
    required String rawText,
    String source = 'coze',
  }) {
    _logger.log('📝 收到AI回复，长度: ${rawText.length}字符', level: LogLevel.debug);

    final extracted = _extractJsonFromText(rawText);
    if (extracted == null || extracted.isEmpty) {
      _logger.log('⚠️ 未提取到JSON，回退纯文本结果', level: LogLevel.warning);
      return _buildTextFallbackResult(rawText, source);
    }

    _logger.log(
      'JSON提取长度: 原始=${rawText.length}, 提取后=${extracted.length}',
      level: LogLevel.debug,
    );

    final decoded = _decodeWithRepairs(extracted);
    if (decoded == null) {
      _logger.log('⚠️ JSON修复失败，回退纯文本结果', level: LogLevel.warning);
      return _buildTextFallbackResult(rawText, source);
    }

    return _mapToResult(decoded, source, rawText);
  }

  String? _extractJsonFromText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final jsonBlock = RegExp(
      r'```json\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (jsonBlock != null) {
      return jsonBlock.group(1)?.trim();
    }

    final codeBlock = RegExp(r'```\s*([\s\S]*?)\s*```').firstMatch(trimmed);
    if (codeBlock != null) {
      return codeBlock.group(1)?.trim();
    }

    final object = _extractFirstCompleteJsonObject(trimmed);
    if (object != null && object.isNotEmpty) {
      return object;
    }

    if (trimmed.startsWith('{') && trimmed.contains('}')) {
      return _truncateToLastCompleteBrace(trimmed);
    }

    return null;
  }

  Map<String, dynamic>? _decodeWithRepairs(String jsonText) {
    final candidates = <String>{
      jsonText.trim(),
      _repairJson(jsonText),
      _truncateToLastCompleteBrace(jsonText),
      _repairJson(_truncateToLastCompleteBrace(jsonText)),
    };

    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // try next candidate
      }
    }

    return null;
  }

  String _repairJson(String input) {
    var out = input.trim();
    if (out.isEmpty) return out;

    out = out
        .replaceAll('\u201c', '"')
        .replaceAll('\u201d', '"')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\ufeff', '');

    // Remove trailing commas before object/array closing.
    out = out.replaceAllMapped(
      RegExp(r',\s*([}\]])'),
      (m) => m.group(1) ?? '',
    );

    // Repair single-quoted keys: {'key': ...} -> {"key": ...}
    out = out.replaceAllMapped(
      RegExp(r"([{,]\s*)'([^']+?)'\s*:"),
      (m) => '${m.group(1)}"${m.group(2)}":',
    );

    // Repair simple single-quoted string values: : 'value'
    out = out.replaceAllMapped(
      RegExp(r":\s*'([^']*?)'(\s*[,}])"),
      (m) => ': "${m.group(1)}"${m.group(2)}',
    );

    return out;
  }

  String? _extractFirstCompleteJsonObject(String text) {
    int depth = 0;
    int start = -1;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];

      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (ch == r'\') {
          escaped = true;
          continue;
        }
        if (ch == '"') {
          inString = false;
        }
        continue;
      }

      if (ch == '"') {
        inString = true;
        continue;
      }

      if (ch == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (ch == '}') {
        if (depth > 0) depth--;
        if (depth == 0 && start >= 0) {
          return text.substring(start, i + 1);
        }
      }
    }

    return null;
  }

  String _truncateToLastCompleteBrace(String text) {
    final object = _extractFirstCompleteJsonObject(text);
    if (object != null) return object;

    final lastBrace = text.lastIndexOf('}');
    if (lastBrace > 0) {
      return text.substring(0, lastBrace + 1);
    }
    return text.trim();
  }

  AICoachResult _mapToResult(
    Map<String, dynamic> json,
    String source,
    String rawText,
  ) {
    final diagnosis = _extractDiagnosisText(
      _pickFirstNonNull(json, [
        '诊断',
        'diagnosis',
        '周期诊断',
        '单次诊断',
        '结论',
      ]),
    );

    final strengths = _normalizeStringList(
      _pickFirstNonNull(json, ['优势', 'strengths', '优势分析', '优势点分析']),
    );

    final weaknesses = _normalizeStringList(
      _pickFirstNonNull(json, [
        '弱点',
        'weaknesses',
        '待改进点',
        '改进点',
        '待改进点分析',
      ]),
    );

    final suggestions = _normalizeSuggestions(
      _pickFirstNonNull(json, ['建议', 'suggestions', '改进建议']),
    );

    final encouragement = _pickFirstString(
      json,
      ['鼓励', 'encouragement', '鼓励语'],
    );

    TrainingPlan? trainingPlan;
    final planField = _pickFirstNonNull(
      json,
      ['训练计划', 'trainingPlan', '4周训练计划'],
    );
    if (planField is Map<String, dynamic>) {
      try {
        trainingPlan = TrainingPlan.fromJson(planField);
      } catch (e) {
        _logger.log('⚠️ 训练计划解析失败: $e', level: LogLevel.debug);
      }
    }

    final finalDiagnosis = diagnosis.isNotEmpty
        ? diagnosis
        : _extractFallbackDiagnosis(rawText) ?? 'AI 分析暂时无法完成，请稍后重试';

    final finalSuggestions = suggestions.isNotEmpty
        ? suggestions
        : [
            CoachingSuggestion(
              category: 'general',
              title: '训练建议',
              description: '本次AI结果缺少可执行建议，请重新分析或稍后重试。',
              priority: 3,
              actionSteps: const ['重新分析', '检查网络', '稍后重试'],
            ),
          ];

    return AICoachResult(
      diagnosis: finalDiagnosis,
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: finalSuggestions,
      trainingPlan: trainingPlan,
      encouragement: encouragement,
      source: source,
      timestamp: DateTime.now(),
      rawResponse: rawText,
    );
  }

  AICoachResult _buildTextFallbackResult(String rawText, String source) {
    final diagnosis = _extractFallbackDiagnosis(rawText) ?? 'AI 分析暂时无法完成，请稍后重试';
    return AICoachResult(
      diagnosis: diagnosis,
      strengths: const [],
      weaknesses: const [],
      suggestions: [
        CoachingSuggestion(
          category: 'general',
          title: '温馨提示',
          description: '本次AI分析未能成功解析响应内容，建议重新分析或稍后再试',
          priority: 3,
          actionSteps: const ['点击"重新分析"按钮', '检查网络连接', '稍后再次尝试'],
        ),
      ],
      trainingPlan: null,
      encouragement: '继续保持训练，数据积累后分析会更准确',
      source: source,
      timestamp: DateTime.now(),
      rawResponse: rawText,
    );
  }

  String? _pickFirstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  dynamic _pickFirstNonNull(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }
    return null;
  }

  String _extractDiagnosisText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is Map) {
      final buffer = StringBuffer();
      value.forEach((k, v) {
        final line = '$k：$v'.trim();
        if (line.isNotEmpty) {
          buffer.writeln(line);
        }
      });
      return buffer.toString().trim();
    }
    return value.toString().trim();
  }

  String? _extractFallbackDiagnosis(String rawText) {
    final cleaned = rawText
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return null;
    return cleaned.first.length > 200
        ? cleaned.first.substring(0, 200)
        : cleaned.first;
  }

  List<String> _normalizeStringList(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      final result = <String>[];
      for (final item in value) {
        if (item == null) continue;
        if (item is String) {
          result.addAll(_splitAndClean(item));
        } else if (item is Map) {
          result.addAll(
            item.values
                .map((e) => e.toString())
                .expand(_splitAndClean)
                .toList(),
          );
        } else {
          result.addAll(_splitAndClean(item.toString()));
        }
      }
      return _dedupeKeepOrder(result);
    }

    if (value is Map) {
      return _dedupeKeepOrder(
        value.values.map((e) => e.toString()).expand(_splitAndClean).toList(),
      );
    }

    return _dedupeKeepOrder(_splitAndClean(value.toString()));
  }

  List<CoachingSuggestion> _normalizeSuggestions(dynamic value) {
    final list = <CoachingSuggestion>[];
    if (value == null) return list;

    if (value is List) {
      for (final item in value) {
        if (item is Map<String, dynamic>) {
          list.add(_mapSuggestion(item));
        } else if (item != null) {
          final texts = _splitAndClean(item.toString());
          for (final text in texts) {
            list.add(
              CoachingSuggestion(
                category: 'general',
                title: '建议',
                description: text,
                priority: 3,
                actionSteps: const [],
              ),
            );
          }
        }
      }
      return list;
    }

    if (value is Map) {
      value.forEach((k, v) {
        list.add(
          CoachingSuggestion(
            category: 'general',
            title: k.toString(),
            description: v.toString(),
            priority: 3,
            actionSteps: const [],
          ),
        );
      });
      return list;
    }

    final texts = _splitAndClean(value.toString());
    for (final text in texts) {
      list.add(
        CoachingSuggestion(
          category: 'general',
          title: '建议',
          description: text,
          priority: 3,
          actionSteps: const [],
        ),
      );
    }
    return list;
  }

  CoachingSuggestion _mapSuggestion(Map<String, dynamic> item) {
    final category = (item['类别'] ?? item['category'] ?? 'general').toString();
    final title = (item['标题'] ?? item['title'] ?? '训练建议').toString();
    final description =
        (item['描述'] ?? item['description'] ?? item['内容'] ?? '').toString();

    final rawPriority = item['优先级'] ?? item['priority'] ?? 3;
    final priority = rawPriority is int
        ? rawPriority
        : int.tryParse(rawPriority.toString()) ?? 3;

    final actionSteps = _normalizeStringList(
      item['行动步骤'] ?? item['actionSteps'] ?? item['步骤'],
    );

    return CoachingSuggestion(
      category: category,
      title: title,
      description: description,
      priority: priority.clamp(1, 5),
      actionSteps: actionSteps,
    );
  }

  List<String> _splitAndClean(String text) {
    final segments = text
        .split(RegExp(r'[、,，;；/\|\n]+'))
        .map((s) => s.trim())
        .map((s) => s.replaceFirst(RegExp(r'^\d+[\).、.\-:\s]+'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
    return segments;
  }

  List<String> _dedupeKeepOrder(List<String> input) {
    final seen = <String>{};
    final result = <String>[];
    for (final item in input) {
      if (seen.add(item)) {
        result.add(item);
      }
    }
    return result;
  }

  bool _isTextBearingEvent({
    required String sseEvent,
    required String jsonType,
    required Map<String, dynamic> payload,
  }) {
    final merged = '$sseEvent $jsonType'.toLowerCase();
    if (merged.contains('message') ||
        merged.contains('answer') ||
        merged.contains('delta') ||
        merged.contains('content') ||
        merged.contains('completed') ||
        merged.contains('end')) {
      return true;
    }
    return payload.containsKey('content') ||
        payload.containsKey('answer') ||
        payload.containsKey('text') ||
        payload.containsKey('message');
  }

  bool _isCompletionEvent(String sseEvent, String jsonType) {
    final merged = '$sseEvent $jsonType'.toLowerCase();
    return merged.contains('completed') ||
        merged.contains('message_end') ||
        merged.endsWith('_end');
  }

  void _throwIfSseEventHasError({
    required Map<String, dynamic> data,
    required String sseEvent,
    required String jsonType,
  }) {
    bool isErrorStatus(dynamic value) {
      if (value is bool) return !value;
      if (value is num) return value != 0 && value != 200;
      final text = value?.toString().toLowerCase() ?? '';
      return text == 'error' || text == 'failed' || text == 'fail';
    }

    dynamic findFirst(List<String> keys) {
      for (final key in keys) {
        if (data.containsKey(key) && data[key] != null) {
          return data[key];
        }
      }
      return null;
    }

    final codeLike =
        findFirst(['code', 'error_code', 'err_code', 'status_code']);
    final statusLike = findFirst(['status', 'state', 'success']);
    final hasError = isErrorStatus(codeLike) || isErrorStatus(statusLike);

    if (!hasError) return;

    final message = (findFirst([
              'message',
              'msg',
              'error',
              'error_message',
              'detail',
            ]) ??
            '服务端返回错误事件')
        .toString();

    final codeText = (codeLike ?? statusLike ?? 'SSE_EVENT_ERROR').toString();
    final merged = '$sseEvent $jsonType'.toLowerCase();
    final recoverable = !merged.contains('unauthorized') &&
        !merged.contains('forbidden') &&
        !merged.contains('config');

    throw CozeAPIException(
      'SSE结束事件返回错误: $message',
      code: codeText,
      isRecoverable: recoverable,
      originalError: data,
    );
  }

  String? _tryExtractAnswer(Map<String, dynamic> jsonData) {
    final content = jsonData['content'];
    if (content is Map) {
      final keys = [
        'answer',
        'text',
        'message',
        'output',
        'output_text',
        'result',
      ];
      for (final key in keys) {
        final value = content[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    } else if (content is String && content.isNotEmpty) {
      return content;
    }

    for (final key in ['answer', 'text', 'message', 'output', 'result']) {
      final value = jsonData[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    final deepValue = _deepFindTextByPreferredKeys(jsonData);
    if (deepValue != null && deepValue.isNotEmpty) {
      return deepValue;
    }

    return null;
  }

  String? _deepFindTextByPreferredKeys(dynamic node, {int depth = 0}) {
    if (depth > 8 || node == null) return null;

    if (node is String) {
      final value = node.trim();
      if (_isLikelyAnswerText(value)) {
        return value;
      }
      return null;
    }

    if (node is Map) {
      final preferredKeys = [
        'answer',
        'text',
        'content',
        'message',
        'output',
        'output_text',
        'result',
        'final_answer',
        'delta',
      ];

      for (final key in preferredKeys) {
        if (node.containsKey(key)) {
          final found =
              _deepFindTextByPreferredKeys(node[key], depth: depth + 1);
          if (found != null && found.isNotEmpty) {
            return found;
          }
        }
      }

      for (final value in node.values) {
        final found = _deepFindTextByPreferredKeys(value, depth: depth + 1);
        if (found != null && found.isNotEmpty) {
          return found;
        }
      }
      return null;
    }

    if (node is List) {
      for (final item in node) {
        final found = _deepFindTextByPreferredKeys(item, depth: depth + 1);
        if (found != null && found.isNotEmpty) {
          return found;
        }
      }
      return null;
    }

    return null;
  }

  bool _isLikelyAnswerText(String value) {
    if (value.isEmpty) return false;
    final lower = value.toLowerCase();
    if (lower == 'message_start' ||
        lower == 'message_end' ||
        lower == 'answer' ||
        lower == 'message') {
      return false;
    }
    if (RegExp(r'^[0-9a-f]{8}-[0-9a-f-]{27}$', caseSensitive: false)
        .hasMatch(value)) {
      return false;
    }
    return true;
  }
}
