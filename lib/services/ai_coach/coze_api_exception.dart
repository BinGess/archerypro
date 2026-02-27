import 'package:dio/dio.dart';

/// Coze API 异常
class CozeAPIException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final bool isRecoverable;

  CozeAPIException(
    this.message, {
    this.code,
    this.originalError,
    bool? isRecoverable,
  }) : isRecoverable = isRecoverable ?? _defaultRecoverable(code);

  static bool _defaultRecoverable(String? code) {
    switch (code) {
      case 'CONFIG_ERROR':
      case 'UNAUTHORIZED':
      case 'BAD_REQUEST':
        return false;
      default:
        return true;
    }
  }

  factory CozeAPIException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return CozeAPIException(
          '网络超时，请检查网络连接',
          code: 'TIMEOUT',
          originalError: error,
          isRecoverable: true,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 429) {
          return CozeAPIException(
            'API 调用频率过高，请稍后再试',
            code: 'RATE_LIMIT',
            originalError: error,
            isRecoverable: true,
          );
        } else if (statusCode == 401 || statusCode == 403) {
          return CozeAPIException(
            'API Token 无效或已过期',
            code: 'UNAUTHORIZED',
            originalError: error,
            isRecoverable: false,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return CozeAPIException(
            '服务暂时不可用：$statusCode',
            code: 'SERVICE_UNAVAILABLE',
            originalError: error,
            isRecoverable: true,
          );
        } else {
          return CozeAPIException(
            '请求参数或权限错误：$statusCode',
            code: 'BAD_REQUEST',
            originalError: error,
            isRecoverable: false,
          );
        }
      default:
        return CozeAPIException(
          '未知错误：${error.message}',
          code: 'UNKNOWN',
          originalError: error,
          isRecoverable: true,
        );
    }
  }

  @override
  String toString() =>
      'CozeAPIException($code, recoverable=$isRecoverable): $message';
}
