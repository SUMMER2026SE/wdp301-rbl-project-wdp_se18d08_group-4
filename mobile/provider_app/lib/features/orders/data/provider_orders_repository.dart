import '../../../core/auth/auth_token_storage.dart';
import '../../../core/config/dev_config.dart';
import '../../../core/mock/mock_auth_session.dart';
import '../../../core/mock/mock_provider_data.dart';
import '../../../core/network/api_client.dart';
import '../domain/provider_order.dart';

class ProviderOrdersRepository {
  ProviderOrdersRepository(this._api);

  final ApiClient _api;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<ProviderOrder>> fetchOrders() async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return List<ProviderOrder>.from(MockProviderData.orders);
    }
    try {
      final envelope = await _api.guard(() => _api.get('/orders'));
      final rows = envelope['data'] as List<dynamic>? ?? [];
      return rows.map((e) => ProviderOrder.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && DevConfig.useMockAuth) {
        await MockAuthSession.signIn();
        return List<ProviderOrder>.from(MockProviderData.orders);
      }
      rethrow;
    }
  }

  Future<ProviderOrder> fetchById(String id) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final order = MockProviderData.orderById(id);
      if (order != null) return order;
      throw ApiException('Không tìm thấy đơn');
    }
    final envelope = await _api.guard(() => _api.get('/orders/$id'));
    return ProviderOrder.fromJson(envelope['data'] as Map<String, dynamic>);
  }

  // ── Order actions ─────────────────────────────────────────────────────────

  /// Accept a pending order.
  /// API: POST /orders/:id/respond  { response: 'accepted' }
  Future<void> accept(String orderId) => respond(orderId: orderId, response: 'accepted');

  /// Decline a pending order.
  /// API: POST /orders/:id/respond  { response: 'declined', decline_reason? }
  Future<void> decline(String orderId, {String? reason}) =>
      respond(orderId: orderId, response: 'declined', declineReason: reason);

  /// Mark order as 'picking_up' (provider arrived at pickup point).
  /// API: PATCH /orders/:id/status  { status: 'picking_up' }
  Future<void> startPickup(String orderId) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      MockProviderData.updateStatus(orderId, 'picking_up');
      return;
    }
    await _api.guard(
      () => _api.patch('/orders/$orderId/status', body: {'status': 'picking_up'}),
    );
  }

  /// Mark order as 'in_progress' (items loaded, en route to delivery).
  /// API: PATCH /orders/:id/status  { status: 'in_progress' }
  Future<void> startDelivery(String orderId) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      MockProviderData.updateStatus(orderId, 'in_progress');
      return;
    }
    await _api.guard(
      () => _api.patch('/orders/$orderId/status', body: {'status': 'in_progress'}),
    );
  }

  /// Mark order as 'completed'.
  /// API: PATCH /orders/:id/complete
  Future<void> complete(String orderId) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      MockProviderData.updateStatus(orderId, 'completed');
      return;
    }
    await _api.guard(() => _api.patch('/orders/$orderId/complete'));
  }

  /// Cancel an order.
  /// API: PATCH /orders/:id/cancel  { reason? }
  Future<void> cancel(String orderId, {String? reason}) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      MockProviderData.updateStatus(orderId, 'cancelled');
      return;
    }
    await _api.guard(
      () => _api.patch('/orders/$orderId/cancel', body: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      }),
    );
  }

  // ── Legacy respond (accept | decline) ─────────────────────────────────────

  Future<void> respond({
    required String orderId,
    required String response,
    String? declineReason,
  }) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      MockProviderData.updateStatus(
        orderId,
        response == 'accepted' ? 'accepted' : 'declined',
      );
      return;
    }
    await _api.guard(
      () => _api.post(
        '/orders/$orderId/respond',
        body: {
          'response': response,
          if (declineReason != null && declineReason.isNotEmpty)
            'decline_reason': declineReason,
        },
      ),
    );
  }
}
