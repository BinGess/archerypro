/// AI 教练配置类
/// 存储 Coze API 相关配置信息
class AIConfig {
  // Coze API 配置（简化版 - 仅需 API Token）
  // ⚠️ 用户需要填写从扣子平台获取的 API Token
  static const String apiToken = String.fromEnvironment(
    'COZE_API_TOKEN',
    defaultValue: '', // 用户填写：例如 'yJh********'
  );

  // Coze 自定义部署的 Base URL
  static const String baseUrl = 'https://ypcqkgr32q.coze.site';

  // Project ID（从API示例中获取）
  static const String projectId = '7598068277797060634';

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
