/// AI 教练配置类
/// 存储 Coze API 相关配置信息
class AIConfig {
  // Coze API 配置
  // 从环境变量或配置文件读取
  // ⚠️ 用户需要填写从扣子平台获取的 API Key 和 Bot ID
  static const String apiKey = String.fromEnvironment(
    'COZE_API_KEY',
    defaultValue: '', // 用户稍后填写 API Key
  );

  static const String botId = String.fromEnvironment(
    'COZE_BOT_ID',
    defaultValue: '', // 用户稍后填写 Bot ID
  );

  static const String baseUrl = 'https://api.coze.cn/v1';

  // 匿名用户标识（用于 Coze API 调用）
  static const String userId = 'anonymous_archery_user';

  // 缓存配置
  static const Duration sessionCacheDuration = Duration(hours: 24);
  static const Duration periodCacheDuration = Duration(hours: 12);

  // HTTP 配置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // 重试配置
  static const int maxRetries = 2;
  static const int retryDelaySeconds = 2;

  /// 检查 API 配置是否有效
  static bool isConfigured() {
    return apiKey.isNotEmpty && botId.isNotEmpty;
  }

  /// 获取用户元数据（用于 Coze API）
  static Map<String, String> getUserMetadata() {
    return {
      'platform': 'archery_app',
      'app_version': '1.0.0',
    };
  }
}
