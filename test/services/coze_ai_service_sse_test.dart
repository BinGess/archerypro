import 'package:archery_tracker/services/ai_coach/cache_service.dart';
import 'package:archery_tracker/services/ai_coach/coze_ai_service.dart';
import 'package:archery_tracker/services/logger_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CozeAIService service;

  setUpAll(() {
    dotenv.testLoad(fileInput: '''
COZE_BASE_URL=https://example.com
COZE_PROJECT_ID=test-project-id
COZE_API_TOKEN=test-token
''');
  });

  setUp(() {
    service = CozeAIService(
      dio: Dio(),
      cache: CacheService(),
      logger: LoggerService(),
    );
  });

  test('extracts final message text from message_start/message_end workflow',
      () {
    const sse = '''
event: message
data: {"type":"message_start","content":{"role":"assistant"}}

event: message
data: {"type":"message_end","content":{"text":"{\\"诊断\\":\\"测试成功\\"}"}}
''';

    final text = service.extractAnswerFromSseForTest(sse);
    expect(text, '{"诊断":"测试成功"}');
  });

  test(
      'prefers completion payload over delta accumulation to avoid duplication',
      () {
    const sse = '''
event: message
data: {"type":"conversation.message.delta","content":"{\\"diagnosis\\":\\"ok"}

event: message
data: {"type":"conversation.message.completed","content":{"text":"{\\"diagnosis\\":\\"ok\\"}"}}
''';

    final text = service.extractAnswerFromSseForTest(sse);
    expect(text, '{"diagnosis":"ok"}');
  });

  test('supports multi-line data payload in one SSE event', () {
    const sse = '''
event: message
data: {"type":"message_end",
data: "content":{"text":"hello"}}

''';

    final text = service.extractAnswerFromSseForTest(sse);
    expect(text, 'hello');
  });
}
