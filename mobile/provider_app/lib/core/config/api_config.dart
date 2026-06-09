import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const useLanHost = true;   // WiFi: đổi thành true + điền IP máy tính bên dưới
  static const lanHost = '192.168.1.29'; // ← thay bằng IPv4 của máy tính (ipconfig)
  static const useAdbReverse = false; // USB ADB: đổi thành true, useLanHost = false

  static String get baseUrl {
    if (useAdbReverse) return 'http://127.0.0.1:5000';
    if (useLanHost && lanHost.isNotEmpty) return 'http://$lanHost:5000';
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  static const apiPrefix = '/api';
  static String get displayUrl => '$baseUrl$apiPrefix';
}
