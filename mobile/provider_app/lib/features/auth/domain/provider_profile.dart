class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.businessName,
    this.phone,
    this.avatarUrl,
    this.vehicleType,
    this.serviceAreas = const [],
    this.isVerified = false,
    this.isOnline = false,
    this.rating = 0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.basePrice,
    this.pricePerKm,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? businessName;
  final String? phone;
  final String? avatarUrl;
  final String? vehicleType;
  final List<String> serviceAreas;
  final bool isVerified;
  final bool isOnline;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final int completedOrders;
  final int? basePrice;
  final int? pricePerKm;

  String get displayName => businessName?.isNotEmpty == true ? businessName! : fullName;

  String get vehicleLabel => switch (vehicleType) {
        'motorbike' => 'Xe máy (< 50kg)',
        'small_truck' => 'Xe tải nhỏ (~500kg)',
        'medium_truck' => 'Xe tải vừa (~1 tấn)',
        'large_truck' => 'Xe tải lớn (~1.5 tấn)',
        _ => vehicleType ?? 'Chưa cập nhật',
      };

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    final areas = json['service_area'];
    return ProviderProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'provider',
      businessName: json['business_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      serviceAreas: areas is List ? areas.map((e) => e.toString()).toList() : const [],
      isVerified: json['is_verified'] as bool? ?? false,
      isOnline: json['is_available'] as bool? ?? json['is_online'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completed_orders'] as num?)?.toInt() ?? 0,
      basePrice: (json['base_price'] as num?)?.toInt(),
      pricePerKm: (json['price_per_km'] as num?)?.toInt(),
    );
  }

  ProviderProfile copyWith({bool? isOnline}) {
    return ProviderProfile(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      businessName: businessName,
      phone: phone,
      avatarUrl: avatarUrl,
      vehicleType: vehicleType,
      serviceAreas: serviceAreas,
      isVerified: isVerified,
      isOnline: isOnline ?? this.isOnline,
      rating: rating,
      totalReviews: totalReviews,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      basePrice: basePrice,
      pricePerKm: pricePerKm,
    );
  }
}
