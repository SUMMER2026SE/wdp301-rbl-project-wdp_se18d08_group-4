import 'package:flutter/foundation.dart';

/// URL Node API.
///
/// **Điện thoại thật (Vysor/USB):** [useLanHost] = true + [lanHost] = IP Wi‑Fi PC (`ipconfig`).
/// Hoặc chạy: `adb reverse tcp:3000 tcp:3000` rồi đặt [useAdbReverse] = true.
///
/// **Android emulator:** [useLanHost] = false → `10.0.2.2`
abstract final class ApiConfig {
  /// May that qua Wi-Fi cung mang voi PC.
  static const useLanHost = false;

  /// IP PC (Wi-Fi) — chi khi useLanHost = true.
  static const lanHost = '192.168.29.1';

  /// USB + `adb reverse tcp:3000 tcp:3000` (cach 2 — dang dung).
  static const useAdbReverse = false;

  static String get baseUrl {
    if (useAdbReverse) return 'http://127.0.0.1:3000';

    if (useLanHost && lanHost.isNotEmpty) {
      return 'http://$lanHost:3000';
    }

    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) return 'http://localhost:3000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      default:
        return 'http://localhost:3000';
    }
  }

  static const apiPrefix = '/api';
  static String get displayUrl => '$baseUrl$apiPrefix';

  /// Google OAuth Web Client ID — truyền qua
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` để verify id_token ở backend.
  static const googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static bool get isGoogleConfigured => googleServerClientId.isNotEmpty;
}
