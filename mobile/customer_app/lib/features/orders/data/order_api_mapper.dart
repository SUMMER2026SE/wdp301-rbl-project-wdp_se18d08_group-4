import '../domain/order_models.dart';

abstract final class OrderApiMapper {
  static CustomerOrder fromJson(Map<String, dynamic> json) {
    final serviceType = json['service_type'] as String? ?? 'standard';
    final vehicleSize = json['vehicle_size'] as String? ?? 'medium_truck';
    final total = ((json['total_price'] as num?) ?? 0).round();

    return CustomerOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      providerId: json['provider_id'] as String?,
      status: OrderStatus.fromDb(json['status'] as String? ?? 'pending'),
      packageLabel: _packageFromService(serviceType),
      vehicleLabel: _vehicleLabel(vehicleSize),
      pickupAddress: json['pickup_address'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      totalPrice: total,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'] as String)
          : null,
      cancellationNote: json['cancellation_reason'] as String?,
      estimatedDistanceKm: (json['estimated_distance'] as num?)?.toDouble(),
      providerName: null,
      providerAvatarUrl: null,
      providerRating: null,
      providerPlate: null,
      conversationId: null,
      scheduledPickupAt: json['scheduled_pickup_time'] != null
          ? DateTime.tryParse(json['scheduled_pickup_time'] as String)
          : null,
    );
  }

  static ServicePackageLabel _packageFromService(String serviceType) {
    return switch (serviceType) {
      'premium' => ServicePackageLabel.premium,
      'express' => ServicePackageLabel.standard,
      _ => ServicePackageLabel.economy,
    };
  }

  static String _vehicleLabel(String vehicleSize) {
    return switch (vehicleSize) {
      'motorbike' => 'Xe máy',
      'small_truck' => 'Xe tải nhỏ',
      'large_truck' => 'Xe tải lớn',
      _ => 'Xe tải trung',
    };
  }

  static TrackingSnapshot trackingFromOrder(CustomerOrder order) {
    final awaiting = order.isAwaitingScheduledPickup;
    final steps = _stepsForStatus(order.status, scheduled: order.scheduledPickupAt != null);
    final activeIndex = steps.indexWhere((s) => s.active);
    final eta = awaiting ? 0 : (order.etaMinutes ?? (order.showLiveTracking ? 25 : 0));

    return TrackingSnapshot(
      order: order,
      steps: steps,
      etaMinutes: eta,
      distanceKm: awaiting ? 0 : (order.estimatedDistanceKm ?? 5.2),
      driverLat: 10.762622,
      driverLng: 106.660172,
      statusLabel: awaiting
          ? 'Chờ đến giờ lấy đồ'
          : steps[activeIndex >= 0 ? activeIndex : 0].label,
      isAwaitingScheduledPickup: awaiting,
    );
  }

  static List<TrackingStep> _stepsForStatus(OrderStatus status, {bool scheduled = false}) {
    final labels = scheduled
        ? [
            ('pending', 'Đã đặt lịch'),
            ('accepted', 'Nhà xe xác nhận'),
            ('picking_up', 'Đến giờ lấy đồ'),
            ('in_progress', 'Đang vận chuyển'),
            ('completed', 'Hoàn thành'),
          ]
        : [
            ('pending', 'Đã đặt đơn'),
            ('accepted', 'Nhà xe nhận'),
            ('picking_up', 'Đang lấy hàng'),
            ('in_progress', 'Đang vận chuyển'),
            ('completed', 'Hoàn thành'),
          ];

    final order = ['pending', 'accepted', 'picking_up', 'in_progress', 'completed'];
    final current = status.dbValue;
    var passed = true;

    return labels.map((e) {
      final done = passed && order.indexOf(e.$1) <= order.indexOf(current);
      final active = e.$1 == current && status.isActive;
      if (e.$1 == current) passed = false;
      return TrackingStep(key: e.$1, label: e.$2, done: done || status == OrderStatus.completed, active: active);
    }).toList();
  }
}
