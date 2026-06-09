/// Khớp bảng `orders` + enum `order_status` trong Supabase.
enum OrderStatus {
  pending,
  accepted,
  pickingUp,
  inProgress,
  completed,
  cancelled,
  disputed;

  static OrderStatus fromDb(String value) {
    return switch (value) {
      'pending' => OrderStatus.pending,
      'accepted' => OrderStatus.accepted,
      'picking_up' => OrderStatus.pickingUp,
      'in_progress' => OrderStatus.inProgress,
      'completed' => OrderStatus.completed,
      'cancelled' => OrderStatus.cancelled,
      'disputed' => OrderStatus.disputed,
      'matched' => OrderStatus.accepted,
      _ => OrderStatus.pending,
    };
  }

  String get dbValue => switch (this) {
        OrderStatus.pending => 'pending',
        OrderStatus.accepted => 'accepted',
        OrderStatus.pickingUp => 'picking_up',
        OrderStatus.inProgress => 'in_progress',
        OrderStatus.completed => 'completed',
        OrderStatus.cancelled => 'cancelled',
        OrderStatus.disputed => 'disputed',
      };

  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.accepted ||
      this == OrderStatus.pickingUp ||
      this == OrderStatus.inProgress;
}

enum ServicePackageLabel { economy, standard, premium }

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.providerId,
    required this.status,
    required this.packageLabel,
    required this.vehicleLabel,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.totalPrice,
    required this.createdAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationNote,
    this.etaMinutes,
    this.estimatedDistanceKm,
    this.providerName,
    this.providerAvatarUrl,
    this.providerRating,
    this.providerPlate,
    this.conversationId,
    this.hasReview = false,
    this.scheduledPickupAt,
    this.quoteReferenceId,
  });

  final String id;
  final String orderNumber;
  final String customerId;
  final String? providerId;
  final OrderStatus status;
  final ServicePackageLabel packageLabel;
  final String vehicleLabel;
  final String pickupAddress;
  final String deliveryAddress;
  final int totalPrice;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationNote;
  final int? etaMinutes;
  final double? estimatedDistanceKm;
  final String? providerName;
  final String? providerAvatarUrl;
  final double? providerRating;
  final String? providerPlate;
  final String? conversationId;
  final bool hasReview;
  final DateTime? scheduledPickupAt;
  final String? quoteReferenceId;

  String get packageDisplay => switch (packageLabel) {
        ServicePackageLabel.economy => 'Gói Economy',
        ServicePackageLabel.standard => 'Gói Standard',
        ServicePackageLabel.premium => 'Gói Premium',
      };

  String get formattedPrice {
    final s = totalPrice.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }
}

class TrackingStep {
  const TrackingStep({
    required this.key,
    required this.label,
    required this.done,
    required this.active,
  });

  final String key;
  final String label;
  final bool done;
  final bool active;
}

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.order,
    required this.steps,
    required this.etaMinutes,
    required this.distanceKm,
    required this.driverLat,
    required this.driverLng,
    required this.statusLabel,
  });

  final CustomerOrder order;
  final List<TrackingStep> steps;
  final int etaMinutes;
  final double distanceKm;
  final double driverLat;
  final double driverLng;
  final String statusLabel;
}
