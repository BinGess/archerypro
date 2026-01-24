import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI 教练配置类
/// 存储 Coze API 相关配置信息
/// 配置从 .env 文件读取
class AIConfig {
  // Coze API Token（从 .env 读取）
  static String get apiToken => dotenv.get('COZE_API_TOKEN', fallback: '');

  // Coze 自定义部署的 Base URL（可从 .env 覆盖）
  static String get baseUrl => dotenv.get(
        'COZE_BASE_URL',
        fallback: 'https://ypcqkgr32q.coze.site',
      );

  // Project ID（可从 .env 覆盖）
  static String get projectId => dotenv.get(
        'COZE_PROJECT_ID',
        fallback: '7598068277797060634',
      );

  // 缓存配置
  static const Duration sessionCacheDuration = Duration(hours: 24);
  static const Duration periodCacheDuration = Duration(hours: 12);

  // HTTP 配置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // 重试配置
  static const int maxRetries = 2;
  static const int retryDelaySeconds = 2;

  /// 检查 API 配置是否有效
  static bool isConfigured() {
    return apiToken.isNotEmpty;
  }
}
