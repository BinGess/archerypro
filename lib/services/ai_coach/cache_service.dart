import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/ai_coach/ai_coach_result.dart';

/// AI 分析结果缓存服务
class CacheService {
  static const String _cachePrefix = 'ai_coach_cache_';
  static const String _timestampSuffix = '_timestamp';

  /// 获取缓存的 AI 分析结果
  Future<AICoachResult?> get<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      // 检查缓存是否存在
      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) {
        return null;
      }

      // 检查缓存是否过期
      final timestamp = prefs.getInt(cacheKey + _timestampSuffix);
      if (timestamp == null) {
        // 没有时间戳，删除无效缓存
        await _remove(key);
        return null;
      }

      // 解析并返回缓存结果
      final Map<String, dynamic> jsonData = json.decode(cachedData);
      return AICoachResult.fromJson(jsonData);
    } catch (e) {
      // 解析失败，删除缓存
      await _remove(key);
      return null;
    }
  }

  /// 设置缓存
  Future<bool> set(
    String key,
    AICoachResult value, {
    Duration duration = const Duration(hours: 24),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      // 计算过期时间
      final expiryTime = DateTime.now().add(duration).millisecondsSinceEpoch;

      // 保存数据和时间戳
      final jsonData = json.encode(value.toJson());
      await prefs.setString(cacheKey, jsonData);
      await prefs.setInt(cacheKey + _timestampSuffix, expiryTime);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 检查缓存是否存在且未过期
  Future<bool> has(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      // 检查数据是否存在
      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) {
        return false;
      }

      // 检查是否过期
      final timestamp = prefs.getInt(cacheKey + _timestampSuffix);
      if (timestamp == null) {
        await _remove(key);
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > timestamp) {
        // 已过期，删除缓存
        await _remove(key);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除指定缓存
  Future<bool> remove(String key) async {
    return await _remove(key);
  }

  Future<bool> _remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      await prefs.remove(cacheKey);
      await prefs.remove(cacheKey + _timestampSuffix);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清除所有 AI 教练相关缓存
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
