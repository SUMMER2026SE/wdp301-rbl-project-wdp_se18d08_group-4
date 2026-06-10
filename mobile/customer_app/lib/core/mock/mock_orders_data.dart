import '../../features/booking/domain/booking_models.dart';
import '../../features/booking/presentation/cubit/booking_flow_state.dart';
import '../../features/chat/domain/chat_models.dart';
import '../../features/orders/data/order_api_mapper.dart';
import '../../features/orders/domain/order_models.dart';
import 'mock_customer_data.dart';

/// Dữ liệu demo — field names khớp schema Supabase.
abstract final class MockOrdersData {
  static const activeOrderId = 'a1000000-0000-4000-8000-000000000001';
  static const completedOrderId = 'a1000000-0000-4000-8000-000000000002';
  static const cancelledOrderId = 'a1000000-0000-4000-8000-000000000003';
  static const conversationId = 'c1000000-0000-4000-8000-000000000001';
  static const completedConversationId = 'c1000000-0000-4000-8000-000000000002';
  static const providerId = 'p1000000-0000-4000-8000-000000000001';

  static const providerName = 'Minh Quân';
  static const providerPlate = '29A-123.45';
  static const providerRating = 4.9;

  static final Map<String, CustomerOrder> _placedOrders = {};

  static String placeBookingOrder(BookingFlowState state) {
    final id = 'b${DateTime.now().millisecondsSinceEpoch.remainder(1000000000)}';
    final partner = state.selectedPartner;
    final pkg = state.selectedPackage;
    final order = CustomerOrder(
      id: id,
      orderNumber: 'UM-${id.substring(id.length - 5)}',
      customerId: MockCustomerData.userId,
      providerId: partner?.id,
      status: OrderStatus.pending,
      packageLabel: switch (state.selectedTier) {
        ServiceTier.premium => ServicePackageLabel.premium,
        ServiceTier.economy => ServicePackageLabel.economy,
        _ => ServicePackageLabel.standard,
      },
      vehicleLabel: partner?.vehicleLabel ?? pkg?.label ?? 'Xe tải',
      pickupAddress: state.pickup,
      deliveryAddress: state.destination.isEmpty ? 'Chưa nhập điểm đến' : state.destination,
      totalPrice: state.total,
      createdAt: DateTime.now(),
      scheduledPickupAt: state.scheduledPickupAt,
      providerName: partner?.name,
      providerRating: partner?.rating,
      providerPlate: providerPlate,
    );
    _placedOrders[id] = order;
    return id;
  }

  static CustomerOrder? orderById(String id) {
    final placed = _placedOrders[id];
    if (placed != null) return placed;
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<CustomerOrder> get allOrders {
    final merged = <CustomerOrder>[..._placedOrders.values, ...orders];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  static final List<CustomerOrder> orders = [
    CustomerOrder(
      id: activeOrderId,
      orderNumber: 'UM-29304',
      customerId: MockCustomerData.userId,
      providerId: providerId,
      status: OrderStatus.pickingUp,
      packageLabel: ServicePackageLabel.standard,
      vehicleLabel: 'Xe tải 500kg',
      pickupAddress: 'Ký túc xá khu B, ĐHQG',
      deliveryAddress: '152 Nguyễn Văn Cừ, Quận 5',
      totalPrice: 450000,
      createdAt: DateTime(2023, 10, 15),
      etaMinutes: 5,
      estimatedDistanceKm: 1.2,
      providerName: providerName,
      providerAvatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBGFoTg7NghjPuAR_l_24vH7bPAvReVKw8S0JyqDk7DnwrXAzbREJXSyxNKUUBynTCdT_1u6IFQ2K-3z3d_gilgFCZAKIwMLPo4GbaAST0QnUtgCOHYHhHBBNzhxfCOLr2ccnd32yjvLibc2RZ9W9Him2flnnvn6i1drxClJx56l207I2q4UU1Z6Q0-FjprMvR0cJj0Aew4bS4HcKMgXYEez6IAIWeb79KTPosUcvRRnU36Tjq_qgjFQVqps1Zn-JagW9VdHxu8hFVC',
      providerRating: providerRating,
      providerPlate: providerPlate,
      conversationId: conversationId,
    ),
    CustomerOrder(
      id: completedOrderId,
      orderNumber: 'UM-28801',
      customerId: MockCustomerData.userId,
      providerId: providerId,
      status: OrderStatus.completed,
      packageLabel: ServicePackageLabel.standard,
      vehicleLabel: 'Xe tải 500kg',
      pickupAddress: 'Ký túc xá Khu B, ĐHQG',
      deliveryAddress: 'Căn hộ Landmark 81, Bình Thạnh',
      totalPrice: 450000,
      createdAt: DateTime(2023, 10, 15),
      completedAt: DateTime(2023, 10, 15, 14, 30),
      providerName: providerName,
      providerRating: providerRating,
      conversationId: completedConversationId,
      hasReview: false,
    ),
    CustomerOrder(
      id: cancelledOrderId,
      orderNumber: 'UM-28112',
      customerId: MockCustomerData.userId,
      status: OrderStatus.cancelled,
      packageLabel: ServicePackageLabel.economy,
      vehicleLabel: 'Xe tải nhỏ',
      pickupAddress: 'Ký túc xá khu A',
      deliveryAddress: 'Quận 7, TP.HCM',
      totalPrice: 215000,
      createdAt: DateTime(2023, 9, 2),
      cancelledAt: DateTime(2023, 9, 2, 10, 0),
      cancellationNote:
          'Đơn hàng đã được hủy bởi khách hàng. Số tiền đã hoàn lại vào ví UniMove của bạn.',
    ),
  ];

  static final conversations = [
    ChatConversation(
      id: conversationId,
      orderId: activeOrderId,
      orderNumber: 'UM-29304',
      providerId: providerId,
      providerName: providerName,
      providerAvatarUrl: orders.first.providerAvatarUrl!,
      isOnline: true,
      lastMessagePreview: 'Dạ vâng đợi em 2 phút em xuống ngay ạ.',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 2)),
      unreadCount: 1,
    ),
    ChatConversation(
      id: completedConversationId,
      orderId: completedOrderId,
      orderNumber: 'UM-28801',
      providerId: providerId,
      providerName: providerName,
      providerAvatarUrl: orders.first.providerAvatarUrl!,
      isOnline: false,
      lastMessagePreview: 'Cảm ơn bạn, chuyến đi đã hoàn thành!',
      lastMessageAt: DateTime(2023, 10, 15, 14, 25),
      unreadCount: 0,
    ),
  ];

  static final messages = <ChatMessage>[
    ChatMessage(
      id: 'm1',
      conversationId: conversationId,
      senderId: providerId,
      senderRole: MessageSenderRole.provider,
      content: 'Chào bạn, mình đã đến cổng Ký túc xá khu B rồi nhé.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
    ),
    ChatMessage(
      id: 'm2',
      conversationId: conversationId,
      senderId: MockCustomerData.userId,
      senderRole: MessageSenderRole.customer,
      content: 'Dạ vâng đợi em 2 phút em xuống ngay ạ.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 4)),
      isRead: true,
    ),
    ChatMessage(
      id: 'm3',
      conversationId: conversationId,
      senderId: providerId,
      senderRole: MessageSenderRole.system,
      content: 'Tài xế đang đợi tại điểm đón của bạn.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      messageType: ChatMessageType.orderUpdate,
    ),
  ];

  static TrackingSnapshot trackingFor(String orderId) {
    final order = orderById(orderId) ?? orders.first;
    return OrderApiMapper.trackingFromOrder(order);
  }
}
