import '../../domain/booking_models.dart';

class BookingFlowState {
  const BookingFlowState({
    this.serviceType = BookingServiceType.fullMove,
    this.pickup = 'Ký túc xá Khu B',
    this.destination = '',
    this.selectedTier = ServiceTier.standard,
    this.selectedPartnerId,
    this.selectedLaborProviderId,
    this.paymentMethod = PaymentMethod.payos,
    this.discountCode = '',
    this.discountApplied = false,
    this.loadingPlaces = false,
    this.loadingPartners = false,
    this.loadingLaborQuotes = false,
    this.recentPlaces = const [],
    this.packages = const [],
    this.partners = const [],
    this.laborQuotes = const [],
    this.helperCount = 0,
    this.laborHours = 2,
    this.floorCount = 1,
    this.hasElevator = true,
    this.pickupFloor = 1,
    this.pickupHasElevator = true,
    this.pickupAlleyAccess = AlleyAccess.unknown,
    this.destinationAlleyAccess = AlleyAccess.unknown,
    this.cargoVolume = CargoVolume.medium,
    this.dormNote = '',
    this.pickupAlleyImagePaths = const [],
    this.destinationAlleyImagePaths = const [],
    this.pickupStairImagePaths = const [],
    this.destinationStairImagePaths = const [],
    this.cargoImagePaths = const [],
    this.dormImageUrls = const [],
    this.laborNote = '',
    this.linkedOrderId,
    this.linkedOrderNumber,
    this.linkedProviderName,
    this.quickCompareEntry = false,
    this.passItemDelivery = false,
    this.passItemId,
    this.extraComboLaborCount = 0,
    this.insurancePlans = const [],
    this.selectedInsurancePlanId,
    this.loadingInsurancePlans = false,
  });

  final BookingServiceType serviceType;
  final String pickup;
  final String destination;
  final ServiceTier selectedTier;
  final String? selectedPartnerId;
  final String? selectedLaborProviderId;
  final PaymentMethod paymentMethod;
  final String discountCode;
  final bool discountApplied;
  final bool loadingPlaces;
  final bool loadingPartners;
  final bool loadingLaborQuotes;
  final List<RecentPlace> recentPlaces;
  final List<ServicePackage> packages;
  final List<PartnerOffer> partners;
  final List<LaborProviderQuote> laborQuotes;
  final int helperCount;
  final int laborHours;
  final int floorCount;
  final bool hasElevator;
  final int pickupFloor;
  final bool pickupHasElevator;
  final AlleyAccess pickupAlleyAccess;
  final AlleyAccess destinationAlleyAccess;
  final CargoVolume cargoVolume;
  final String dormNote;

  final List<String> pickupAlleyImagePaths;
  final List<String> destinationAlleyImagePaths;
  final List<String> pickupStairImagePaths;
  final List<String> destinationStairImagePaths;
  final List<String> cargoImagePaths;

  /// URL sau khi upload lên server (khi gửi yêu cầu báo giá).
  final List<String> dormImageUrls;

  bool get showPickupAlleyPhotos => pickupAlleyAccess.needsAlleyPhoto;

  bool get showDestinationAlleyPhotos => destinationAlleyAccess.needsAlleyPhoto;

  bool get showPickupStairPhotos => !pickupHasElevator;

  bool get showDestinationStairPhotos => !hasElevator;

  bool get showCargoPhotos => cargoVolume.needsCargoPhoto;

  List<String> dormImagePathsFor(DormPhotoSection section) => switch (section) {
        DormPhotoSection.pickupAlley => pickupAlleyImagePaths,
        DormPhotoSection.destinationAlley => destinationAlleyImagePaths,
        DormPhotoSection.pickupStairs => pickupStairImagePaths,
        DormPhotoSection.destinationStairs => destinationStairImagePaths,
        DormPhotoSection.cargo => cargoImagePaths,
      };

  Iterable<String> get activeDormImagePaths sync* {
    if (showPickupAlleyPhotos) yield* pickupAlleyImagePaths;
    if (showPickupStairPhotos) yield* pickupStairImagePaths;
    if (showDestinationAlleyPhotos) yield* destinationAlleyImagePaths;
    if (showDestinationStairPhotos) yield* destinationStairImagePaths;
    if (showCargoPhotos) yield* cargoImagePaths;
  }

  final String laborNote;
  final String? linkedOrderId;
  final String? linkedOrderNumber;
  final String? linkedProviderName;

  /// Vào từ "So sánh báo giá" trên Home — đã có địa điểm mẫu, bỏ qua bước chọn điểm.
  final bool quickCompareEntry;

  /// Đặt xe lấy đồ từ tin pass đồ — điểm lấy đã là khu vực người bán.
  final bool passItemDelivery;

  /// Tin pass đồ liên kết (khóa huỷ chốt khi khách đã đặt xe).
  final String? passItemId;

  /// Số người khuân vác thêm (ngoài số đã có trong combo).
  final int extraComboLaborCount;

  final List<CargoInsurancePlan> insurancePlans;
  final String? selectedInsurancePlanId;
  final bool loadingInsurancePlans;

  bool get isLaborOnly => serviceType == BookingServiceType.laborOnly;

  bool get isLaborAddon => serviceType == BookingServiceType.laborAddon;

  bool get isLaborService => isLaborOnly || isLaborAddon;

  bool get requiresHelpers => isLaborService;

  ServicePackage? get selectedPackage {
    for (final p in packages) {
      if (p.tier == selectedTier) return p;
    }
    return null;
  }

  PartnerOffer? get selectedPartner {
    if (selectedPartnerId == null) return null;
    for (final p in partners) {
      if (p.id == selectedPartnerId) return p;
    }
    return null;
  }

  LaborProviderQuote? get selectedLaborProvider {
    if (selectedLaborProviderId == null) return null;
    for (final q in laborQuotes) {
      if (q.id == selectedLaborProviderId) return q;
    }
    return null;
  }

  int get baseLaborFee =>
      isLaborService ? helperCount * laborHours * LaborPricing.perHelperPerHour : 0;

  /// Tạm tính trước khi chọn đối tác (chưa gồm markup marketplace).
  int get laborFee => baseLaborFee;

  int get floorFee => isLaborService && !hasElevator && floorCount > 0
      ? floorCount * LaborPricing.perFloorNoElevator
      : 0;

  /// Giá khuân vác từ đối tác đã chọn (marketplace).
  int get laborQuotedPrice =>
      selectedLaborProvider?.price ?? (baseLaborFee + floorFee);

  int get movePackagePrice => isLaborService ? 0 : (selectedPackage?.price ?? 450000);

  int get comboExtraLaborFee {
    if (isLaborService) return 0;
    final pkg = selectedPackage;
    if (pkg == null) return 0;
    return extraComboLaborCount * pkg.extraLaborComboPrice;
  }

  CargoInsurancePlan? get selectedInsurancePlan {
    if (selectedInsurancePlanId == null) return null;
    for (final p in insurancePlans) {
      if (p.id == selectedInsurancePlanId) return p;
    }
    return null;
  }

  bool get hasInsuranceCoverage {
    final plan = selectedInsurancePlan;
    return plan != null && !plan.isNoCoverage;
  }

  int get insuranceFee {
    if (isLaborService) return 0;
    final plan = selectedInsurancePlan;
    if (plan == null || plan.isNoCoverage) return 0;
    return plan.price;
  }

  int get subtotal {
    if (isLaborService) return laborQuotedPrice;
    return movePackagePrice + comboExtraLaborFee + insuranceFee;
  }

  int get discount => discountApplied ? 35000 : 0;

  int get serviceFee => 0;

  int get total => subtotal - discount + serviceFee;

  BookingFlowState copyWith({
    BookingServiceType? serviceType,
    String? pickup,
    String? destination,
    ServiceTier? selectedTier,
    String? selectedPartnerId,
    String? selectedLaborProviderId,
    PaymentMethod? paymentMethod,
    String? discountCode,
    bool? discountApplied,
    bool? loadingPlaces,
    bool? loadingPartners,
    bool? loadingLaborQuotes,
    List<RecentPlace>? recentPlaces,
    List<ServicePackage>? packages,
    List<PartnerOffer>? partners,
    List<LaborProviderQuote>? laborQuotes,
    int? helperCount,
    int? laborHours,
    int? floorCount,
    bool? hasElevator,
    int? pickupFloor,
    bool? pickupHasElevator,
    AlleyAccess? pickupAlleyAccess,
    AlleyAccess? destinationAlleyAccess,
    CargoVolume? cargoVolume,
    String? dormNote,
    List<String>? pickupAlleyImagePaths,
    List<String>? destinationAlleyImagePaths,
    List<String>? pickupStairImagePaths,
    List<String>? destinationStairImagePaths,
    List<String>? cargoImagePaths,
    List<String>? dormImageUrls,
    String? laborNote,
    String? linkedOrderId,
    String? linkedOrderNumber,
    String? linkedProviderName,
    bool? quickCompareEntry,
    bool? passItemDelivery,
    String? passItemId,
    int? extraComboLaborCount,
    bool clearPassItemId = false,
    List<CargoInsurancePlan>? insurancePlans,
    String? selectedInsurancePlanId,
    bool? loadingInsurancePlans,
    bool clearLinkedOrder = false,
  }) {
    return BookingFlowState(
      serviceType: serviceType ?? this.serviceType,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      selectedTier: selectedTier ?? this.selectedTier,
      selectedPartnerId: selectedPartnerId ?? this.selectedPartnerId,
      selectedLaborProviderId: selectedLaborProviderId ?? this.selectedLaborProviderId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discountCode: discountCode ?? this.discountCode,
      discountApplied: discountApplied ?? this.discountApplied,
      loadingPlaces: loadingPlaces ?? this.loadingPlaces,
      loadingPartners: loadingPartners ?? this.loadingPartners,
      loadingLaborQuotes: loadingLaborQuotes ?? this.loadingLaborQuotes,
      recentPlaces: recentPlaces ?? this.recentPlaces,
      packages: packages ?? this.packages,
      partners: partners ?? this.partners,
      laborQuotes: laborQuotes ?? this.laborQuotes,
      helperCount: helperCount ?? this.helperCount,
      laborHours: laborHours ?? this.laborHours,
      floorCount: floorCount ?? this.floorCount,
      hasElevator: hasElevator ?? this.hasElevator,
      pickupFloor: pickupFloor ?? this.pickupFloor,
      pickupHasElevator: pickupHasElevator ?? this.pickupHasElevator,
      pickupAlleyAccess: pickupAlleyAccess ?? this.pickupAlleyAccess,
      destinationAlleyAccess: destinationAlleyAccess ?? this.destinationAlleyAccess,
      cargoVolume: cargoVolume ?? this.cargoVolume,
      dormNote: dormNote ?? this.dormNote,
      pickupAlleyImagePaths: pickupAlleyImagePaths ?? this.pickupAlleyImagePaths,
      destinationAlleyImagePaths: destinationAlleyImagePaths ?? this.destinationAlleyImagePaths,
      pickupStairImagePaths: pickupStairImagePaths ?? this.pickupStairImagePaths,
      destinationStairImagePaths: destinationStairImagePaths ?? this.destinationStairImagePaths,
      cargoImagePaths: cargoImagePaths ?? this.cargoImagePaths,
      dormImageUrls: dormImageUrls ?? this.dormImageUrls,
      laborNote: laborNote ?? this.laborNote,
      linkedOrderId: clearLinkedOrder ? null : (linkedOrderId ?? this.linkedOrderId),
      linkedOrderNumber:
          clearLinkedOrder ? null : (linkedOrderNumber ?? this.linkedOrderNumber),
      linkedProviderName:
          clearLinkedOrder ? null : (linkedProviderName ?? this.linkedProviderName),
      quickCompareEntry: quickCompareEntry ?? this.quickCompareEntry,
      passItemDelivery: passItemDelivery ?? this.passItemDelivery,
      passItemId: clearPassItemId ? null : (passItemId ?? this.passItemId),
      extraComboLaborCount: extraComboLaborCount ?? this.extraComboLaborCount,
      insurancePlans: insurancePlans ?? this.insurancePlans,
      selectedInsurancePlanId: selectedInsurancePlanId ?? this.selectedInsurancePlanId,
      loadingInsurancePlans: loadingInsurancePlans ?? this.loadingInsurancePlans,
    );
  }
}
