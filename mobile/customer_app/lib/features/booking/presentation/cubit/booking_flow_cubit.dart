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
import '../../domain/quote_models.dart';
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
    if (state.partners.isNotEmpty && !state.isComboBooking) return;
    if (state.isComboBooking && state.partners.isNotEmpty) {
      final tier = state.selectedTier;
      final filtered = state.partners.where((p) => p.offersCombo(tier)).toList();
      if (filtered.isNotEmpty) {
        emit(state.copyWith(
          partners: filtered,
          selectedPartnerId:
              state.selectedPartnerId ?? (filtered.isNotEmpty ? filtered.first.id : null),
        ));
        return;
      }
    }
    emit(state.copyWith(loadingPartners: true));
    List<PartnerOffer> partners;
    if (state.isComboBooking) {
      // Chưa có API combo niêm yết — luôn dùng mock nhà xe đăng ký combo.
      partners = await _repo.fetchComboPartners(state.selectedTier);
    } else {
      try {
        partners = await _providersRepo.browse();
        if (partners.isEmpty) {
          partners = await _repo.fetchPartners();
        }
      } catch (_) {
        partners = await _repo.fetchPartners();
      }
    }
    if (state.isComboBooking) {
      partners.sort((a, b) => state.comboTotalForPartner(a).compareTo(state.comboTotalForPartner(b)));
    }
    emit(state.copyWith(
      loadingPartners: false,
      partners: partners,
      selectedPartnerId: state.selectedPartnerId ?? (partners.isNotEmpty ? partners.first.id : null),
    ));
  }

  void refreshComboPartners() {
    emit(state.copyWith(partners: [], selectedPartnerId: null));
    unawaited(loadPartners());
  }

  Future<String> checkout() => _ordersRepo.createFromBooking(state);

  Future<void> loadLaborQuotes() async {
    emit(state.copyWith(loadingLaborQuotes: true, laborQuotes: []));
    final helpers = state.helperCount < 1 ? 1 : state.helperCount;

    if (state.isLaborAddon) {
      final quote = await _laborRepo.fetchTransportProviderLaborQuote(
        providerId: state.selectedPartnerId,
        providerName: state.linkedProviderName ?? 'Nhà xe vận chuyển',
        helperCount: helpers,
        laborHours: state.laborHours,
        floorFee: state.floorFee,
      );
      emit(state.copyWith(
        loadingLaborQuotes: false,
        laborQuotes: [quote],
        selectedLaborProviderId: quote.id,
      ));
      return;
    }

    final quotes = await _laborRepo.fetchLaborQuotes(
      helperCount: helpers,
      laborHours: state.laborHours,
      floorFee: state.floorFee,
      forExistingOrder: false,
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

  void selectTier(ServiceTier tier) {
    ServicePackage? pkg;
    for (final p in state.packages) {
      if (p.tier == tier) {
        pkg = p;
        break;
      }
    }
    emit(state.copyWith(
      selectedTier: tier,
      selectedComboLaborCount: pkg?.laborSuggested ?? 1,
      wantsRetailLabor: false,
      partners: state.isComboBooking ? const [] : state.partners,
      selectedPartnerId: state.isComboBooking ? null : state.selectedPartnerId,
      clearLaborProvider: true,
      clearLaborQuotes: true,
    ));
    if (state.isComboBooking) {
      unawaited(loadPartners());
    }
  }

  void setComboLaborCount(int count) {
    final max = state.selectedPackage?.maxLaborCount ?? 3;
    var next = state.copyWith(selectedComboLaborCount: count.clamp(1, max));
    if (next.isComboBooking && next.partners.isNotEmpty) {
      final sorted = [...next.partners]
        ..sort((a, b) => next.comboTotalForPartner(a).compareTo(next.comboTotalForPartner(b)));
      next = next.copyWith(partners: sorted);
    }
    emit(next);
  }

  void skipRetailLabor() {
    emit(state.copyWith(
      wantsRetailLabor: false,
      clearLaborProvider: true,
      clearLaborQuotes: true,
    ));
  }

  void confirmRetailLabor() {
    if (state.selectedLaborProviderId == null) return;
    emit(state.copyWith(wantsRetailLabor: true));
  }

  Future<void> loadRetailLaborQuotes() async {
    emit(state.copyWith(loadingLaborQuotes: true, laborQuotes: []));
    final helpers = state.helperCount < 1 ? 2 : state.helperCount;
    final pkg = state.selectedPackage;
    final quotes = await _laborRepo.fetchLaborQuotes(
      helperCount: helpers,
      laborHours: state.laborHours,
      floorFee: state.floorFee,
      retailMode: true,
      comboLaborUnitPrice: pkg?.extraLaborComboPrice,
    );
    final combinable = quotes.where((q) => q.canCombineWithTransport).toList();
    final display = combinable.isNotEmpty ? combinable : quotes;
    emit(state.copyWith(
      loadingLaborQuotes: false,
      laborQuotes: display,
      helperCount: helpers,
      selectedLaborProviderId:
          state.selectedLaborProviderId ?? (display.isNotEmpty ? display.first.id : null),
    ));
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

  /// Đặt chuyến thường — nhà xe báo giá tự do.
  void startFullMoveBooking() {
    emit(const BookingFlowState(isComboBooking: false));
  }

  /// Combo niêm yết — khai báo địa điểm như đặt chuyến, giá xe/km cố định trên app.
  void startComboBooking() {
    emit(const BookingFlowState(isComboBooking: true));
  }

  /// Chuyển từ combo sang đặt chuyến linh hoạt — giữ địa điểm đã nhập.
  void switchToCustomTrip() {
    emit(state.copyWith(
      isComboBooking: false,
      partners: const [],
      selectedPartnerId: null,
      wantsRetailLabor: false,
      clearLaborProvider: true,
      clearLaborQuotes: true,
    ));
    unawaited(loadPartners());
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

  /// Đặt chuyến linh hoạt — so sánh báo giá nhà xe (không qua combo niêm yết).
  void startCompareQuotesFlow() {
    emit(
      const BookingFlowState(
        isComboBooking: false,
        pickup: 'Ký túc xá Khu B, ĐHQG',
        destination: '152 Nguyễn Văn Cừ, Quận 5',
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
    emit(state.copyWith(helperCount: count.clamp(1, 6), clearLaborProvider: true));
    _reloadLaborQuotesAfterConfigChange();
  }

  void setLaborHours(int hours) {
    emit(state.copyWith(laborHours: hours.clamp(1, 12), clearLaborProvider: true));
    _reloadLaborQuotesAfterConfigChange();
  }

  void setFloorCount(int floors) {
    emit(state.copyWith(floorCount: floors.clamp(0, 20), clearLaborProvider: true));
    _reloadLaborQuotesAfterConfigChange();
  }

  void setHasElevator(bool value) {
    emit(state.copyWith(hasElevator: value, clearLaborProvider: true));
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

  void setWantsTransportLabor(bool value) => emit(state.copyWith(wantsTransportLabor: value));

  void setTransportLaborHelpers(int count) =>
      emit(state.copyWith(transportLaborHelpers: count.clamp(1, 6)));

  void setTransportLaborHours(int hours) =>
      emit(state.copyWith(transportLaborHours: hours.clamp(1, 12)));

  void setScheduledPickup(DateTime value) => emit(state.copyWith(scheduledPickupAt: value));

  /// Khung giờ lấy đồ hợp lệ — tối thiểu 2 giờ kể từ bây giờ.
  static bool isValidPickupTime(DateTime value) {
    return value.isAfter(DateTime.now().add(const Duration(hours: 2)));
  }

  static DateTime defaultPickupSuggestion() {
    final now = DateTime.now().add(const Duration(hours: 2));
    final day = DateTime(now.year, now.month, now.day);
    var hour = now.hour;
    if (now.minute > 0) hour += 1;
    if (hour < 7) return DateTime(day.year, day.month, day.day, 8);
    if (hour >= 18) return DateTime(day.year, day.month, day.day + 1, 8);
    return DateTime(day.year, day.month, day.day, hour);
  }

  static const maxPhotosPerSection = 3;

  void addDormPhoto(DormPhotoSection section, String path) {
    final current = state.dormPhotos[section] ?? [];
    if (current.length >= maxPhotosPerSection) return;
    final next = Map<DormPhotoSection, List<String>>.from(state.dormPhotos);
    next[section] = [...current, path];
    emit(state.copyWith(dormPhotos: next));
  }

  void removeDormPhoto(DormPhotoSection section, int index) {
    final current = state.dormPhotos[section];
    if (current == null || index < 0 || index >= current.length) return;
    final next = Map<DormPhotoSection, List<String>>.from(state.dormPhotos);
    final updated = [...current]..removeAt(index);
    if (updated.isEmpty) {
      next.remove(section);
    } else {
      next[section] = updated;
    }
    emit(state.copyWith(dormPhotos: next));
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

  /// Chuẩn bị state thanh toán cho chuyến báo giá đã chốt nhà xe.
  void prepareQuoteDepositPayment(QuoteRequestSnapshot snap) {
    final quote = snap.confirmedQuote;
    if (quote == null) {
      throw Exception('Chưa chốt nhà xe để đặt cọc');
    }

    emit(
      state.copyWith(
        isQuoteBooking: true,
        isComboBooking: false,
        quoteReferenceId: snap.id,
        pickup: snap.pickup,
        destination: snap.destination,
        scheduledPickupAt: snap.scheduledPickupAt,
        dormNote: snap.dormNote,
        quoteProviderName: quote.providerName,
        quoteBasePrice: quote.basePrice,
        quoteSurcharges: quote.surcharges,
        selectedPartnerId: quote.providerId,
        wantsRetailLabor: false,
        discountApplied: false,
      ),
    );
  }

  /// Hoàn tất đặt cọc sau khi thanh toán trên màn Payment.
  Future<QuoteRequestSnapshot> completeQuoteDeposit() async {
    final ref = state.quoteReferenceId;
    if (ref == null || !state.isQuoteBooking) {
      throw Exception('Không tìm thấy yêu cầu báo giá để đặt cọc');
    }
    final snap = await _quoteRepo.payDeposit(ref);
    emit(state.copyWith(clearQuoteBooking: true));
    return snap;
  }
}
