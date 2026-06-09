import '../../features/auth/domain/provider_profile.dart';
import '../../features/messages/domain/chat_models.dart';
import '../../features/orders/domain/provider_order.dart';
/// Dữ liệu mẫu cho phiên đăng nhập demo của đối tác (provider).
abstract final class MockProviderData {
  static const providerId = 'p1000000-0000-4000-8000-000000000001';

  /// User JSON lưu vào storage khi đăng nhập demo (khớp schema `profiles`).
  static const Map<String, dynamic> userJson = {
    'id': providerId,
    'email': 'partner@unimove.vn',
    'full_name': 'Minh Quân',
    'role': 'provider',
    'business_name': 'Nhà xe Minh Quân',
    'phone': '0905 123 456',
    'vehicle_type': 'medium_truck',
    'service_area': ['Quận Ngũ Hành Sơn', 'Quận Hải Châu', 'Quận Thanh Khê'],
    'is_verified': true,
    'is_available': true,
    'rating': 4.9,
    'total_reviews': 87,
    'total_orders': 143,
    'completed_orders': 138,
    'base_price': 150000,
    'price_per_km': 12000,
  };

  static final ProviderProfile profile = ProviderProfile.fromJson(userJson);

  /// Tên khách theo id (hiển thị ở chi tiết đơn / tin nhắn).
  static const Map<String, String> customerNames = {
    'c1000000-0000-4000-8000-000000000001': 'Lê Nhật Nam',
    'c1000000-0000-4000-8000-000000000002': 'Trần Thu Hà',
    'c1000000-0000-4000-8000-000000000003': 'Phạm Minh Đức',
  };

  /// Danh sách đơn — **mutable** để demo nhận/từ chối cập nhật trực tiếp.
  static final List<ProviderOrder> orders = [
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000001',
      status: 'pending',
      orderNumber: 'UM-29304',
      pickupAddress: 'Ký túc xá khu B, ĐHQG Thủ Đức',
      deliveryAddress: '152 Nguyễn Văn Cừ, Quận 5',
      totalPrice: 450000,
      serviceType: 'standard',
      vehicleSize: 'medium_truck',
      customerId: 'c1000000-0000-4000-8000-000000000001',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      distanceKm: 8,
      etaMinutes: 25,
      itemSummary: '3 thùng carton, 1 tủ lạnh nhỏ',
    ),
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000005',
      status: 'pending',
      orderNumber: 'UM-29312',
      pickupAddress: 'Chung cư mini Tô Hiến Thành, Quận 10',
      deliveryAddress: 'KTX khu A, ĐHQG Thủ Đức',
      totalPrice: 320000,
      serviceType: 'standard',
      vehicleSize: 'small_truck',
      customerId: 'c1000000-0000-4000-8000-000000000003',
      createdAt: DateTime.now().subtract(const Duration(minutes: 21)),
      distanceKm: 5.2,
      etaMinutes: 18,
      itemSummary: '5 thùng đồ, 1 kệ sách',
    ),
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000002',
      status: 'accepted',
      orderNumber: 'UM-29280',
      pickupAddress: 'Chung cư Sài Gòn Gateway, TP. Thủ Đức',
      deliveryAddress: 'Landmark 81, Bình Thạnh',
      totalPrice: 620000,
      serviceType: 'premium',
      vehicleSize: 'large_truck',
      customerId: 'c1000000-0000-4000-8000-000000000002',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000003',
      status: 'in_progress',
      orderNumber: 'UM-29251',
      pickupAddress: 'KTX khu A, ĐHQG',
      deliveryAddress: 'Phường Linh Trung, TP. Thủ Đức',
      totalPrice: 280000,
      serviceType: 'standard',
      vehicleSize: 'small_truck',
      customerId: 'c1000000-0000-4000-8000-000000000003',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000004',
      status: 'completed',
      orderNumber: 'UM-28801',
      pickupAddress: 'Ký túc xá Khu B, ĐHQG',
      deliveryAddress: 'Căn hộ Landmark 81, Bình Thạnh',
      totalPrice: 450000,
      serviceType: 'standard',
      vehicleSize: 'medium_truck',
      customerId: 'c1000000-0000-4000-8000-000000000001',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000006',
      status: 'completed',
      orderNumber: 'UM-28790',
      pickupAddress: 'Quận Bình Thạnh',
      deliveryAddress: 'Quận 7, TP.HCM',
      totalPrice: 540000,
      serviceType: 'premium',
      vehicleSize: 'large_truck',
      customerId: 'c1000000-0000-4000-8000-000000000002',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000007',
      status: 'completed',
      orderNumber: 'UM-28705',
      pickupAddress: 'Làng đại học, Dĩ An',
      deliveryAddress: 'Quận 1, TP.HCM',
      totalPrice: 310000,
      serviceType: 'standard',
      vehicleSize: 'small_truck',
      customerId: 'c1000000-0000-4000-8000-000000000003',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000008',
      status: 'declined',
      orderNumber: 'UM-28640',
      pickupAddress: 'Quận 12, TP.HCM',
      deliveryAddress: 'Quận 9, TP.HCM',
      totalPrice: 390000,
      serviceType: 'standard',
      vehicleSize: 'medium_truck',
      customerId: 'c1000000-0000-4000-8000-000000000001',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      cancellationReason: 'Không còn slot trong khung giờ',
    ),
    ProviderOrder(
      id: 'a1000000-0000-4000-8000-000000000009',
      status: 'cancelled',
      orderNumber: 'UM-28588',
      pickupAddress: 'KTX Khu C, Thủ Đức',
      deliveryAddress: 'Quận 3, TP.HCM',
      totalPrice: 260000,
      serviceType: 'standard',
      vehicleSize: 'small_truck',
      customerId: 'c1000000-0000-4000-8000-000000000002',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      cancellationReason: 'Khách hủy đơn',
      cancelledAt: DateTime.now().subtract(const Duration(days: 7, hours: 20)),
    ),
  ];

  static String customerNameOf(String? id) => customerNames[id] ?? 'Khách UniMove';

  static ProviderOrder? orderById(String id) {
    try {
      final order = orders.firstWhere((o) => o.id == id);
      return enrichOrderDetails(order);
    } catch (_) {
      return null;
    }
  }

  /// Bổ sung field chi tiết theo schema `orders` (demo khi API chưa trả đủ).
  static ProviderOrder enrichOrderDetails(ProviderOrder o) {
    if (o.pickup != null) return o;

    final customerName = customerNameOf(o.customerId);
    final phones = {
      'c1000000-0000-4000-8000-000000000001': '0987 654 321',
      'c1000000-0000-4000-8000-000000000002': '0909 112 334',
      'c1000000-0000-4000-8000-000000000003': '0911 220 455',
    };
    final phone = phones[o.customerId] ?? '0901 000 000';

    final base = ((o.totalPrice * 0.55) / 1000).round() * 1000;
    final dist = ((o.totalPrice * 0.25) / 1000).round() * 1000;
    final floor = o.totalPrice - base - dist > 0 ? o.totalPrice - base - dist : 0;

    final lineItems = o.itemSummary != null
        ? o.itemSummary!
            .split(',')
            .map((s) => OrderLineItem(name: s.trim(), qty: 1))
            .toList()
        : <OrderLineItem>[
            const OrderLineItem(name: 'Đồ dùng chuyển phòng', qty: 1, weightKg: 120, fragile: false),
          ];

    return ProviderOrder(
      id: o.id,
      status: o.status,
      pickupAddress: o.pickupAddress,
      deliveryAddress: o.deliveryAddress,
      totalPrice: o.totalPrice,
      orderNumber: o.orderNumber,
      serviceType: o.serviceType,
      vehicleSize: o.vehicleSize,
      customerId: o.customerId,
      createdAt: o.createdAt,
      distanceKm: o.distanceKm ?? 8,
      etaMinutes: o.etaMinutes ?? 25,
      itemSummary: o.itemSummary,
      pickup: OrderLocationPoint(
        address: o.pickupAddress,
        city: 'TP. Hồ Chí Minh',
        district: 'Thành phố Thủ Đức',
        ward: 'Linh Xuân',
        floor: 3,
        hasElevator: false,
        contactName: customerName,
        contactPhone: phone,
        notes: 'Gọi trước 10 phút khi đến. Có thang bộ.',
      ),
      delivery: OrderLocationPoint(
        address: o.deliveryAddress,
        city: 'TP. Hồ Chí Minh',
        district: 'Quận 5',
        ward: 'Phường 14',
        floor: 2,
        hasElevator: true,
        contactName: customerName,
        contactPhone: phone,
        notes: 'Bảo vệ cho xe vào hầm B.',
      ),
      pricing: OrderPriceBreakdown(
        basePrice: base,
        distancePrice: dist,
        floorPrice: floor,
        serviceFee: o.serviceType == 'premium' ? 50000 : 0,
        discountAmount: 0,
        totalPrice: o.totalPrice,
      ),
      items: lineItems,
      itemsDescription: o.itemSummary ?? 'Đồ chuyển phòng / pass đồ sau chốt deal',
      estimatedWeightKg: 180,
      hasFragileItems: o.serviceType == 'premium',
      requiresHelpers: o.vehicleSize == 'large_truck' || o.vehicleSize == 'medium_truck',
      numberOfHelpers: o.vehicleSize == 'large_truck' ? 2 : 1,
      hasInsurance: o.serviceType == 'premium',
      insuranceValue: o.serviceType == 'premium' ? 5000000 : null,
      hasPackingService: false,
      scheduledPickupTime: o.createdAt?.add(const Duration(hours: 2)),
      actualPickupTime: o.isActive || o.isCompleted ? o.createdAt?.add(const Duration(hours: 3)) : null,
      actualDeliveryTime: o.isCompleted ? o.createdAt?.add(const Duration(hours: 5)) : null,
      completedAt: o.isCompleted ? o.createdAt?.add(const Duration(hours: 5)) : null,
    );
  }

  /// Cập nhật trạng thái 1 đơn (demo nhận/từ chối/hoàn thành).
  static void updateStatus(String id, String status) {
    final i = orders.indexWhere((o) => o.id == id);
    if (i != -1) orders[i] = orders[i].copyWith(status: status);
  }

  /// Khách có đang thực hiện chuyến (đơn active) hay không → quyết định được chat.
  static bool customerHasActiveTrip(String? customerId) {
    if (customerId == null) return false;
    return orders.any((o) => o.isActive && o.customerId == customerId);
  }

  // ----- Tin nhắn demo -----
  static final List<ChatThread> chatThreads = [
    ChatThread(
      id: 't1',
      name: 'Lê Nhật Nam',
      customerId: 'c1000000-0000-4000-8000-000000000001',
      time: '2 phút',
      unread: true,
      messages: [
        ChatMessage(text: 'Chào anh, em vừa đặt chuyến chuyển trọ ạ.', fromProvider: false, time: '09:10'),
        ChatMessage(text: 'Anh nhận đơn rồi nhé, em chuẩn bị đồ giúp anh.', fromProvider: true, time: '09:12'),
        ChatMessage(text: 'Anh ơi tới chưa ạ? Em đợi ở cổng KTX B nhé.', fromProvider: false, time: '09:20'),
      ],
    ),
    ChatThread(
      id: 't2',
      name: 'Trần Thu Hà',
      customerId: 'c1000000-0000-4000-8000-000000000002',
      time: '1 giờ',
      unread: true,
      messages: [
        ChatMessage(text: 'Anh ơi đồ em hơi nhiều, có cần thêm người không?', fromProvider: false, time: '08:02'),
        ChatMessage(text: 'Anh đi 2 người và xe lớn rồi, em yên tâm nhé.', fromProvider: true, time: '08:05'),
        ChatMessage(text: 'Đồ em hơi nhiều, anh mang thêm dây ràng giúp em.', fromProvider: false, time: '08:30'),
      ],
    ),
    ChatThread(
      id: 't3',
      name: 'Phạm Minh Đức',
      customerId: 'c1000000-0000-4000-8000-000000000003',
      time: 'Hôm qua',
      unread: false,
      messages: [
        ChatMessage(text: 'Anh đang trên đường tới điểm giao nhé.', fromProvider: true, time: 'Hôm qua'),
        ChatMessage(text: 'Dạ vâng, em đợi ở sảnh ạ.', fromProvider: false, time: 'Hôm qua'),
        ChatMessage(text: 'Cảm ơn anh, chuyến vừa rồi nhanh gọn ạ!', fromProvider: false, time: 'Hôm qua'),
      ],
    ),
    ChatThread(
      id: 't4',
      name: 'Hỗ trợ UniMove',
      customerId: null,
      time: '2 ngày',
      unread: false,
      messages: [
        ChatMessage(text: 'Chào bạn, giấy tờ của bạn đã được duyệt.', fromProvider: false, time: '2 ngày trước'),
        ChatMessage(text: 'Cảm ơn đội ngũ UniMove ạ!', fromProvider: true, time: '2 ngày trước'),
      ],
    ),
  ];

  static ChatThread? chatThreadById(String id) {
    try {
      return chatThreads.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tìm hội thoại theo khách (để mở từ chi tiết đơn).
  static ChatThread? chatThreadByCustomer(String? customerId) {
    if (customerId == null) return null;
    try {
      return chatThreads.firstWhere((t) => t.customerId == customerId);
    } catch (_) {
      return null;
    }
  }

  // ----- Giấy tờ demo -----
  /// (tiêu đề, yêu cầu, trạng thái: verified | pending | missing)
  static const List<({String title, String requirement, String status})> documents = [
    (title: 'Giấy phép lái xe', requirement: 'Bắt buộc', status: 'verified'),
    (title: 'Đăng ký phương tiện', requirement: 'Bắt buộc', status: 'verified'),
    (title: 'Bảo hiểm vận tải', requirement: 'Khuyến nghị', status: 'pending'),
    (title: 'Giấy phép kinh doanh', requirement: 'Tùy loại hình', status: 'missing'),
  ];
}
