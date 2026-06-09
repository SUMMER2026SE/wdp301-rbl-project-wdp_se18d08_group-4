import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../orders/domain/order_models.dart';
import '../../data/booking_media_repository.dart';
import '../../data/booking_mock_repository.dart';
import '../../data/quote_progress_repository.dart';
import '../../data/labor_repository.dart';
import '../../data/providers_repository.dart';
import '../../../orders/data/customer_orders_repository.dart';
import '../../domain/booking_models.dart';
import 'booking_flow_state.dart';

class BookingFlowCubit extends Cubit<BookingFlowState> {
  BookingFlowCubit({
    BookingMockRepository? repository,
    LaborRepository? laborRepository,
    ProvidersRepository? providersRepository,
    CustomerOrdersRepository? ordersRepository,
    BookingMediaRepository? mediaRepository,
    QuoteProgressRepository? quoteProgressRepository,
  })  : _repo = repository ?? BookingMockRepository(),
        _laborRepo = laborRepository ?? LaborRepository(),
        _providersRepo = providersRepository ?? ProvidersRepository(),
        _ordersRepo = ordersRepository ?? CustomerOrdersRepository(),
        _mediaRepo = mediaRepository ?? BookingMediaRepository(),
        _quoteRepo = quoteProgressRepository ?? QuoteProgressRepository.instance,
        super(const BookingFlowState());

  final BookingMockRepository _repo;
  final LaborRepository _laborRepo;
  final ProvidersRepository _providersRepo;
  final CustomerOrdersRepository _ordersRepo;
  final BookingMediaRepository _mediaRepo;
  final QuoteProgressRepository _quoteRepo;

  static const maxImagesPerSection = 3;

  Future<void> loadPlaces() async {
    if (state.recentPlaces.isNotEmpty) return;
    emit(state.copyWith(loadingPlaces: true));
    final places = await _repo.fetchRecentPlaces();
    emit(state.copyWith(loadingPlaces: false, recentPlaces: places));
  }

  Future<void> loadPackages() async {
    if (state.packages.isNotEmpty) return;
    final packages = await _repo.fetchPackages();
    emit(state.copyWith(packages: packages));
  }

  Future<void> loadInsurancePlans() async {
    if (state.insurancePlans.isNotEmpty) return;
    emit(state.copyWith(loadingInsurancePlans: true));
    final plans = await _repo.fetchInsurancePlans();
    emit(state.copyWith(
      loadingInsurancePlans: false,
      insurancePlans: plans,
      selectedInsurancePlanId: state.selectedInsurancePlanId ?? 'standard',
    ));
  }

  void selectInsurancePlan(String planId) {
    emit(state.copyWith(selectedInsurancePlanId: planId));
  }

  Future<void> loadPartners() async {
    if (state.partners.isNotEmpty) return;
    emit(state.copyWith(loadingPartners: true));
    List<PartnerOffer> partners;
    try {
      partners = await _providersRepo.browse();
      if (partners.isEmpty) {
        partners = await _repo.fetchPartners();
      }
    } catch (_) {
      partners = await _repo.fetchPartners();
    }
    emit(state.copyWith(
      loadingPartners: false,
      partners: partners,
      selectedPartnerId: state.selectedPartnerId ?? (partners.isNotEmpty ? partners.first.id : null),
    ));
  }

  Future<String> checkout() => _ordersRepo.createFromBooking(state);

  Future<void> loadLaborQuotes() async {
    emit(state.copyWith(loadingLaborQuotes: true, laborQuotes: []));
    final helpers = state.helperCount < 1 ? 1 : state.helperCount;
    final quotes = await _laborRepo.fetchLaborQuotes(
      helperCount: helpers,
      laborHours: state.laborHours,
      floorFee: state.floorFee,
      forExistingOrder: state.isLaborAddon,
    );
    emit(state.copyWith(
      loadingLaborQuotes: false,
      laborQuotes: quotes,
      selectedLaborProviderId:
          state.selectedLaborProviderId ?? (quotes.isNotEmpty ? quotes.first.id : null),
    ));
  }

  void setDestination(String value) => emit(state.copyWith(destination: value));

  void selectPlace(RecentPlace place) => emit(state.copyWith(destination: place.title));

  void selectTier(ServiceTier tier) =>
      emit(state.copyWith(selectedTier: tier, extraComboLaborCount: 0));

  void setExtraComboLaborCount(int count) {
    emit(state.copyWith(extraComboLaborCount: count.clamp(0, 2)));
  }

  void selectPartner(String id) => emit(state.copyWith(selectedPartnerId: id));

  void selectLaborProvider(String id) => emit(state.copyWith(selectedLaborProviderId: id));

  void selectPayment(PaymentMethod method) => emit(state.copyWith(paymentMethod: method));

  void setDiscountCode(String code) => emit(state.copyWith(discountCode: code));

  void applyDiscount() {
    if (state.discountCode.trim().toUpperCase() == 'UNIMOVE50') {
      emit(state.copyWith(discountApplied: true));
    }
  }

  /// Khuân vác độc lập — không cần đơn chuyển xe.
  void startLaborOnlyBooking() {
    emit(
      const BookingFlowState(
        serviceType: BookingServiceType.laborOnly,
        helperCount: 2,
        laborHours: 2,
        floorCount: 0,
        hasElevator: true,
        destination: '',
      ),
    );
  }

  /// Thêm khuân vác vào đơn chuyển trọ đã có.
  void startLaborAddonFromOrder(CustomerOrder order) {
    emit(
      BookingFlowState(
        serviceType: BookingServiceType.laborAddon,
        linkedOrderId: order.id,
        linkedOrderNumber: order.orderNumber,
        linkedProviderName: order.providerName,
        pickup: order.pickupAddress,
        destination: order.deliveryAddress,
        helperCount: 2,
        laborHours: 2,
        floorCount: 0,
        hasElevator: true,
        selectedPartnerId: order.providerId,
      ),
    );
  }

  void resetToFullMove() {
    emit(const BookingFlowState());
  }

  /// Đặt chuyến mới — bắt đầu từ chọn địa điểm.
  void startFullMoveBooking() {
    emit(const BookingFlowState());
  }

  /// Đặt vận chuyển cho 1 món pass đồ — điểm lấy = nơi bán, khách chọn điểm giao.
  void startPassItemDelivery({required String pickup, required String passItemId}) {
    emit(BookingFlowState(
      pickup: pickup,
      destination: '',
      passItemDelivery: true,
      passItemId: passItemId,
    ));
  }

  /// So sánh báo giá nhanh — đã có địa điểm mẫu, vào thẳng quy mô chuyến.
  void startCompareQuotesFlow() {
    emit(
      const BookingFlowState(
        pickup: 'Ký túc xá Khu B, ĐHQG',
        destination: '152 Nguyễn Văn Cừ, Quận 5',
        selectedTier: ServiceTier.standard,
        quickCompareEntry: true,
      ),
    );
  }

  void clearQuickCompareEntry() {
    if (state.quickCompareEntry) {
      emit(state.copyWith(quickCompareEntry: false));
    }
  }

  void setHelperCount(int count) {
    emit(state.copyWith(helperCount: count.clamp(1, 6), selectedLaborProviderId: null));
    _reloadLaborQuotesAfterConfigChange();
  }

  void setLaborHours(int hours) {
    emit(state.copyWith(laborHours: hours, selectedLaborProviderId: null));
    _reloadLaborQuotesAfterConfigChange();
  }

  void setFloorCount(int floors) {
    emit(state.copyWith(floorCount: floors.clamp(0, 20), selectedLaborProviderId: null));
    _reloadLaborQuotesAfterConfigChange();
  }

  void setHasElevator(bool value) {
    emit(state.copyWith(hasElevator: value, selectedLaborProviderId: null));
    _reloadLaborQuotesAfterConfigChange();
  }

  void _reloadLaborQuotesAfterConfigChange() {
    if (state.isLaborService) {
      unawaited(loadLaborQuotes());
    }
  }

  void setLaborNote(String note) => emit(state.copyWith(laborNote: note));

  void setPickupFloor(int floor) => emit(state.copyWith(pickupFloor: floor.clamp(0, 30)));

  void setPickupHasElevator(bool value) => emit(state.copyWith(pickupHasElevator: value));

  void setPickupAlley(AlleyAccess access) => emit(state.copyWith(pickupAlleyAccess: access));

  void setDestinationAlley(AlleyAccess access) =>
      emit(state.copyWith(destinationAlleyAccess: access));

  void setCargoVolume(CargoVolume volume) => emit(state.copyWith(cargoVolume: volume));

  void setDormNote(String note) => emit(state.copyWith(dormNote: note));

  void addSectionImage(DormPhotoSection section, String path) {
    final current = state.dormImagePathsFor(section);
    if (current.length >= maxImagesPerSection) return;
    final next = [...current, path];
    emit(_copyWithSectionImages(section, next));
  }

  void removeSectionImage(DormPhotoSection section, int index) {
    final current = state.dormImagePathsFor(section);
    if (index < 0 || index >= current.length) return;
    final next = [...current]..removeAt(index);
    emit(_copyWithSectionImages(section, next));
  }

  BookingFlowState _copyWithSectionImages(DormPhotoSection section, List<String> paths) {
    return switch (section) {
      DormPhotoSection.pickupAlley => state.copyWith(pickupAlleyImagePaths: paths),
      DormPhotoSection.destinationAlley => state.copyWith(destinationAlleyImagePaths: paths),
      DormPhotoSection.pickupStairs => state.copyWith(pickupStairImagePaths: paths),
      DormPhotoSection.destinationStairs => state.copyWith(destinationStairImagePaths: paths),
      DormPhotoSection.cargo => state.copyWith(cargoImagePaths: paths),
    };
  }

  /// Gửi yêu cầu báo giá — upload ảnh (nếu có) rồi trả mã tham chiếu.
  Future<QuoteSubmitResult> submitQuoteRequest() async {
    final urls = <String>[];
    var photoUploadFailed = false;

    for (final path in state.activeDormImagePaths) {
      try {
        urls.add(await _mediaRepo.uploadDormPhoto(filePath: path));
      } catch (_) {
        photoUploadFailed = true;
      }
    }

    if (urls.isNotEmpty) {
      emit(state.copyWith(dormImageUrls: urls));
    }
    if (state.activeDormImagePaths.isNotEmpty && urls.isEmpty) {
      photoUploadFailed = true;
    }

    final ref = 'QR-${DateTime.now().millisecondsSinceEpoch.remainder(1000000)}';
    await _quoteRepo.createFromBooking(
      referenceId: ref,
      state: state,
      imageUrls: urls,
    );
    return QuoteSubmitResult(referenceId: ref, photoUploadFailed: photoUploadFailed);
  }
}
