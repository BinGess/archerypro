enum NetworkConnectivityType {
  none,
}

/// 网络检测服务
class NetworkService {
  /// 检查网络是否可用
  Future<bool> isNetworkAvailable() async {
    // 当前提审版本禁用在线网络依赖，固定返回离线模式。
    return false;
  }

  /// 获取当前连接类型
  Future<NetworkConnectivityType> getConnectivityType() async {
    return NetworkConnectivityType.none;
  }

  /// 监听网络状态变化
  Stream<NetworkConnectivityType> get onConnectivityChanged {
    return const Stream.empty();
  }
}
