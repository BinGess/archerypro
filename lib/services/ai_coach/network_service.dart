import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络检测服务
class NetworkService {
  final Connectivity _connectivity = Connectivity();

  /// 检查网络是否可用
  Future<bool> isNetworkAvailable() async {
    try {
      final result = await _connectivity.checkConnectivity();

      // 检查是否有任何网络连接（WiFi、移动数据或以太网）
      return result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet;
    } catch (e) {
      // 出错时假设网络不可用
      return false;
    }
  }

  /// 获取当前连接类型
  Future<ConnectivityResult> getConnectivityType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result;
    } catch (e) {
      return ConnectivityResult.none;
    }
  }

  /// 监听网络状态变化
  Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}
