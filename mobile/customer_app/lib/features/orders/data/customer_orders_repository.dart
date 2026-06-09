import '../../../core/auth/auth_token_storage.dart';
import '../../../core/config/dev_config.dart';
import '../../../core/mock/mock_auth_session.dart';
import '../../../core/mock/mock_orders_data.dart';
import '../../booking/data/quote_runtime_store.dart';
import '../../../core/network/api_client.dart';
import '../../booking/domain/booking_models.dart';
import '../../booking/presentation/cubit/booking_flow_state.dart';
import '../domain/order_models.dart';
import 'order_api_mapper.dart';

class CustomerOrdersRepository {
  CustomerOrdersRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<bool> _useMockData() async {
    if (DevConfig.useMockAuth && await MockAuthSession.isSignedIn()) return true;
    return !(await AuthTokenStorage.instance.hasSession());
  }

  Future<List<CustomerOrder>> fetchOrders({bool activeOnly = false, bool completedOnly = false}) async {
    if (await _useMockData()) {
      return _mockFilter(activeOnly: activeOnly, completedOnly: completedOnly);
    }

    final envelope = await _api.guard(() => _api.get('/orders'));
    final raw = envelope['data'];

    var list = raw is List
        ? raw
            .map((e) => OrderApiMapper.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <CustomerOrder>[];

    // Demo fallback: tài khoản thật chưa có đơn nào → hiển thị dữ liệu mẫu
    // để màn "Hoạt động" không trống khi demo.
    if (list.isEmpty) {
      return _mockFilter(activeOnly: activeOnly, completedOnly: completedOnly);
    }

    list = _mergeRuntimeOrders(list);

    if (activeOnly) {
      list = list.where((o) => o.status.isActive).toList();
    }
    if (completedOnly) {
      list = list
          .where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.cancelled)
          .toList();
    }
    return list;
  }

  Future<CustomerOrder?> fetchById(String id) async {
    final runtime = QuoteRuntimeStore.instance.orderById(id);
    if (runtime != null) return runtime;

    if (await _useMockData()) {
      try {
        return MockOrdersData.orders.firstWhere((o) => o.id == id);
      } catch (_) {
        return null;
      }
    }

    try {
      final envelope = await _api.guard(() => _api.get('/orders/$id'));
      final data = envelope['data'];
      if (data is! Map) return _mockById(id);
      return OrderApiMapper.fromJson(Map<String, dynamic>.from(data));
    } on ApiException {
      return _mockById(id);
    }
  }

  CustomerOrder? _mockById(String id) {
    try {
      return MockOrdersData.orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TrackingSnapshot> fetchTracking(String orderId) async {
    final order = await fetchById(orderId);
    if (order == null) {
      if (await _useMockData()) {
        return MockOrdersData.trackingFor(orderId);
      }
      throw ApiException('Không tìm thấy đơn hàng');
    }
    return OrderApiMapper.trackingFromOrder(order);
  }

  /// Tạo đơn từ luồng booking + đặt cọc qua API.
  Future<String> createFromBooking(BookingFlowState state) async {
    if (await _useMockData()) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return MockOrdersData.activeOrderId;
    }

    final user = await AuthTokenStorage.instance.loadUser();
    final contactName = user?['full_name'] as String? ?? 'Khách UniMove';
    final contactPhone = user?['phone'] as String? ?? '+84900000000';

    final pickup = _splitAddress(state.pickup);
    final delivery = _splitAddress(
      state.destination.isEmpty ? '152 Nguyễn Văn Cừ, Quận 5' : state.destination,
    );

    final tier = state.selectedTier;
    final vehicleSize = switch (tier) {
      ServiceTier.economy => 'small_truck',
      ServiceTier.premium => 'large_truck',
      _ => 'medium_truck',
    };
    final serviceType = switch (tier) {
      ServiceTier.premium => 'premium',
      ServiceTier.economy => 'standard',
      _ => 'standard',
    };

    final basePrice = state.movePackagePrice + state.comboExtraLaborFee;
    final total = state.total;

    final envelope = await _api.guard(
      () => _api.post('/orders', body: {
        'vehicle_size': vehicleSize,
        'service_type': serviceType,
        'pickup_address': pickup.address,
        'pickup_city': pickup.city,
        'pickup_district': pickup.district,
        'pickup_contact_name': contactName,
        'pickup_contact_phone': contactPhone,
        'delivery_address': delivery.address,
        'delivery_city': delivery.city,
        'delivery_district': delivery.district,
        'delivery_contact_name': contactName,
        'delivery_contact_phone': contactPhone,
        'base_price': basePrice,
        'distance_price': 0,
        'floor_price': state.floorFee,
        'service_fee': state.serviceFee,
        'total_price': total,
        'number_of_rooms': 1,
        if (state.isLaborService) 'scheduled_pickup_time': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      }),
    );

    final orderJson = Map<String, dynamic>.from(envelope['data'] as Map);
    final orderId = orderJson['id'] as String;

    final deposit = (total * 0.3).round();
    if (deposit > 0 && !state.isLaborAddon) {
      await _api.guard(
        () => _api.post('/payments/deposit', body: {
          'order_id': orderId,
          'amount': deposit,
          'payment_method': state.paymentMethod == PaymentMethod.momo ? 'momo' : 'payos',
        }),
      );
    }

    return orderId;
  }

  List<CustomerOrder> _mergeRuntimeOrders(List<CustomerOrder> list) {
    final runtime = QuoteRuntimeStore.instance.orders;
    if (runtime.isEmpty) return list;
    final ids = list.map((o) => o.id).toSet();
    return [...runtime.where((o) => !ids.contains(o.id)), ...list];
  }

  List<CustomerOrder> _mockFilter({required bool activeOnly, required bool completedOnly}) {
    var list = _mergeRuntimeOrders([...MockOrdersData.orders]);
    if (activeOnly) {
      list = list.where((o) => o.status.isActive).toList();
    }
    if (completedOnly) {
      list = list
          .where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.cancelled)
          .toList();
    }
    return list;
  }
}

class _ParsedAddress {
  const _ParsedAddress({required this.address, required this.city, required this.district});
  final String address;
  final String city;
  final String district;
}

_ParsedAddress _splitAddress(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const _ParsedAddress(address: 'Chưa nhập địa chỉ', city: 'TP.HCM', district: 'Quận 1');
  }
  return _ParsedAddress(address: trimmed, city: 'TP.HCM', district: 'Quận 1');
}
