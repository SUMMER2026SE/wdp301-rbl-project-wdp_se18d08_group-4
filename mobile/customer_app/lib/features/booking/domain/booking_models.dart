import 'package:flutter/material.dart';

class RecentPlace {
  const RecentPlace({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

enum ServiceTier { economy, standard, premium }

class ServicePackage {
  const ServicePackage({
    required this.tier,
    required this.label,
    required this.badge,
    required this.price,
    required this.features,
    required this.popular,
    required this.laborIncluded,
    required this.includedKm,
    required this.extraKmPrice,
    required this.extraLaborComboPrice,
    required this.extraLaborRetailPrice,
    this.subtitle = '',
  });

  final ServiceTier tier;
  final String label;
  final String badge;
  final int price;
  final List<PackageFeature> features;
  final bool popular;

  /// Số người khuân vác đã gộp trong combo.
  final int laborIncluded;

  /// Số km di chuyển đã bao gồm trong giá combo.
  final int includedKm;

  /// Giá mỗi km vượt quá [includedKm] (tham chiếu).
  final int extraKmPrice;

  /// Giá thêm 1 người khi đã chọn combo (ưu đãi).
  final int extraLaborComboPrice;

  /// Giá tham chiếu nếu thuê khuân vác riêng (để so sánh).
  final int extraLaborRetailPrice;

  final String subtitle;

  int get laborSavingsPerPerson => extraLaborRetailPrice - extraLaborComboPrice;
}

class PackageFeature {
  const PackageFeature({required this.text, required this.included});

  final String text;
  final bool included;
}

class PartnerOffer {
  const PartnerOffer({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.imageUrl,
    required this.vehicleLabel,
    this.completedTrips = 0,
    this.recentReviews = const [],
  });

  final String id;
  final String name;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final int price;
  final String imageUrl;
  final String vehicleLabel;
  final int completedTrips;
  final List<ProviderReview> recentReviews;
}

class ProviderReview {
  const ProviderReview({
    required this.author,
    required this.rating,
    required this.comment,
    required this.timeAgoLabel,
  });

  final String author;
  final double rating;
  final String comment;
  final String timeAgoLabel;
}

enum PaymentMethod { payos, momo, otherWallet }

/// Loại đặt dịch vụ — khớp `orders.requires_helpers` / `number_of_helpers`.
enum BookingServiceType { fullMove, laborOnly, laborAddon }

/// Báo giá đội khuân vác từ đối tác marketplace (UniMove trung gian).
class LaborProviderQuote {
  const LaborProviderQuote({
    required this.id,
    required this.name,
    required this.teamLabel,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.etaMinutes,
    this.badge,
    this.canCombineWithTransport = true,
  });

  final String id;
  final String name;
  final String teamLabel;
  final double rating;
  final int reviewCount;
  final int price;
  final int etaMinutes;
  final String? badge;
  /// Có thể phối hợp cùng nhà xe / đơn chuyển trọ hiện có.
  final bool canCombineWithTransport;
}

/// Cấu hình giá khuân vác (tham chiếu seed: 50.000–100.000đ/người).
abstract final class LaborPricing {
  static const int perHelperPerHour = 75000;
  static const int perFloorNoElevator = 15000;
  static const List<int> hourOptions = [2, 4, 8];
}

class LaborServiceInfo {
  const LaborServiceInfo({
    required this.title,
    required this.description,
    required this.benefits,
    required this.minPrice,
  });

  final String title;
  final String description;
  final List<String> benefits;
  final int minPrice;
}

/// Gói bảo hiểm đồ đạc — khớp `orders.has_insurance`, `orders.insurance_value`.
class CargoInsurancePlan {
  const CargoInsurancePlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.coverageAmount,
    required this.price,
    required this.benefits,
    this.recommended = false,
    this.isNoCoverage = false,
  });

  final String id;
  final String name;
  final String tagline;

  /// Mức bồi thường tối đa (VND).
  final int coverageAmount;
  final int price;
  final List<String> benefits;
  final bool recommended;
  final bool isNoCoverage;
}

/// Đường vào trọ — quyết định loại xe và phụ phí có thể phát sinh.
enum AlleyAccess {
  truckOk,
  smallOnly,
  motorbikeOnly,
  unknown;

  String get label => switch (this) {
        AlleyAccess.truckOk => 'Xe tải vào được',
        AlleyAccess.smallOnly => 'Chỉ xe nhỏ / ba gác',
        AlleyAccess.motorbikeOnly => 'Hẻm hẹp — chỉ xe máy',
        AlleyAccess.unknown => 'Chưa rõ — cần ảnh',
      };

  String get hint => switch (this) {
        AlleyAccess.truckOk => 'Đường rộng, xe tải ~1 tấn vào cổng được',
        AlleyAccess.smallOnly => 'Hẻm vừa, ba gác hoặc xe tải nhỏ',
        AlleyAccess.motorbikeOnly => 'Hẻm nhỏ, có thể phụ phí khuân bộ',
        AlleyAccess.unknown => 'Nên chụp ảnh cổng hẻm khi gửi yêu cầu',
      };
}

/// Khối lượng đồ ước tính.
enum CargoVolume {
  light,
  medium,
  heavy;

  String get label => switch (this) {
        CargoVolume.light => 'Ít đồ',
        CargoVolume.medium => 'Vừa (phòng trọ thường)',
        CargoVolume.heavy => 'Nhiều đồ',
      };

  String get examples => switch (this) {
        CargoVolume.light => 'Vali, vài thùng, bàn nhỏ',
        CargoVolume.medium => 'Giường, tủ, bếp, máy giặt',
        CargoVolume.heavy => 'Full phòng trọ + tủ lớn',
      };

  bool get needsCargoPhoto => this != CargoVolume.light;
}

extension AlleyAccessPhoto on AlleyAccess {
  bool get needsAlleyPhoto => this != AlleyAccess.truckOk;
}

/// Kết quả gửi yêu cầu báo giá.
class QuoteSubmitResult {
  const QuoteSubmitResult({
    required this.referenceId,
    this.photoUploadFailed = false,
  });

  final String referenceId;
  final bool photoUploadFailed;
}

/// Nhóm ảnh theo từng mục trong form mô tả trọ.
enum DormPhotoSection {
  pickupAlley,
  destinationAlley,
  pickupStairs,
  destinationStairs,
  cargo;

  String get label => switch (this) {
        DormPhotoSection.pickupAlley => 'Ảnh hẻm / cổng trọ cũ',
        DormPhotoSection.destinationAlley => 'Ảnh hẻm / cổng trọ mới',
        DormPhotoSection.pickupStairs => 'Ảnh cầu thang trọ cũ',
        DormPhotoSection.destinationStairs => 'Ảnh cầu thang trọ mới',
        DormPhotoSection.cargo => 'Ảnh đồ cần chuyển',
      };

  String get hint => switch (this) {
        DormPhotoSection.pickupAlley => 'Chụp cổng hẻm, đường vào điểm lấy đồ',
        DormPhotoSection.destinationAlley => 'Chụp cổng hẻm, đường vào trọ mới',
        DormPhotoSection.pickupStairs => 'Chụp cầu thang / hành lang (không có thang máy)',
        DormPhotoSection.destinationStairs => 'Chụp cầu thang / hành lang (không có thang máy)',
        DormPhotoSection.cargo => 'Chụp tủ, giường, đồ cồng kềnh',
      };
}
