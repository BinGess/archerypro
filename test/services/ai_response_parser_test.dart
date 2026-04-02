import 'package:archery_tracker/services/ai_coach/ai_response_parser.dart';
import 'package:archery_tracker/services/ai_coach/coze_api_exception.dart';
import 'package:archery_tracker/services/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AiResponseParser parser;

  setUp(() {
    parser = AiResponseParser(logger: LoggerService());
  });

  test('SSE normal flow: completion payload wins over deltas', () {
    const sse = '''
event: message
data: {"type":"conversation.message.delta","content":"{\\"diagnosis\\":\\"partial\\""}

event: message
data: {"type":"conversation.message.completed","content":{"text":"{\\"diagnosis\\":\\"final\\"}"}}
''';

    final answer = parser.extractAnswerFromSse(sse);
    expect(answer, '{"diagnosis":"final"}');
  });

  test('SSE error event: throws CozeAPIException on message_end error code',
      () {
    const sse = '''
event: message
data: {"type":"message_end","code":500,"message":"internal error"}
''';

    expect(
      () => parser.extractAnswerFromSse(sse),
      throwsA(
        isA<CozeAPIException>()
            .having((e) => e.code, 'code', '500')
            .having((e) => e.isRecoverable, 'isRecoverable', isTrue),
      ),
    );
  });

  test('parse JSON from markdown json block', () {
    const text = '''
analysis:
```json
{
  "诊断": "状态不错",
  "优势": ["稳定", "节奏"],
  "弱点": ["撒放偏急"],
  "建议": [{"类别":"technique","标题":"放松手指","描述":"减少抢放","优先级":4,"行动步骤":["慢拉","稳靠位"]}]
}
```
''';

    final result = parser.parseCoachResult(rawText: text, source: 'coze');
    expect(result.diagnosis, '状态不错');
    expect(result.strengths, containsAll(['稳定', '节奏']));
    expect(result.weaknesses, contains('撒放偏急'));
    expect(result.suggestions, isNotEmpty);
  });

  test('repair malformed JSON with trailing commas', () {
    const text = '''
{
  "诊断": "可继续提升",
  "优势": ["稳定",],
  "弱点": "节奏、收弓",
  "建议": [{"标题":"节奏控制","描述":"更平稳","优先级":"4","行动步骤":"1. 慢拉；2. 稳定"},],
}
''';

    final result = parser.parseCoachResult(rawText: text, source: 'coze');
    expect(result.diagnosis, '可继续提升');
    expect(result.weaknesses, containsAll(['节奏', '收弓']));
    expect(result.suggestions.first.priority, 4);
    expect(result.suggestions.first.actionSteps, containsAll(['慢拉', '稳定']));
  });

  test('normalize synonyms and multi-shape fields', () {
    const text = '''
{
  "diagnosis": {"summary": "good", "focus": "release"},
  "strengths": "稳定、节奏,专注",
  "待改进点分析": {"1": "肩线", "2": "跟弓"},
  "改进建议": {
    "动作": "控制起弓节奏",
    "心理": "保持呼吸稳定"
  },
  "encouragement": "继续加油"
}
''';

    final result = parser.parseCoachResult(rawText: text, source: 'coze');
    expect(result.diagnosis, contains('summary：good'));
    expect(result.strengths, containsAll(['稳定', '节奏', '专注']));
    expect(result.weaknesses, containsAll(['肩线', '跟弓']));
    expect(result.suggestions.length, 2);
    expect(result.encouragement, '继续加油');
  });
}
