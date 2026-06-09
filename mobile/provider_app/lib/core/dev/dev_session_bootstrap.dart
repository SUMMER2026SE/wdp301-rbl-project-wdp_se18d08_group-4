import '../../features/documents/data/provider_documents_repository.dart';
import '../auth/auth_token_storage.dart';
import '../config/dev_config.dart';
import '../mock/mock_auth_session.dart';
import '../network/api_client.dart';

/// Khi debug: JWT cũ/hết hạn → tự chuyển phiên demo để app không kẹt lỗi token.
abstract final class DevSessionBootstrap {
  static Future<void> apply() async {
    if (!DevConfig.useMockAuth) return;

    final storage = AuthTokenStorage.instance;
    final token = await storage.loadToken();
    if (token == null || token.isEmpty) return;
    if (await storage.isMockSession()) {
      ApiClient.instance.setAccessToken(AuthTokenStorage.mockToken);
      await ProviderDocumentsRepository().seedVerifiedDemoProvider();
      return;
    }

    await MockAuthSession.signIn();
    ApiClient.instance.setAccessToken(AuthTokenStorage.mockToken);
  }
}
