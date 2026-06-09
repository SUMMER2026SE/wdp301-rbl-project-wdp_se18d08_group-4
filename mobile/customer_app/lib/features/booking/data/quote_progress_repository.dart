import '../../../core/constants/app_images.dart';
import '../domain/booking_models.dart';
import '../domain/quote_models.dart';
import '../presentation/cubit/booking_flow_state.dart';
import 'booking_mock_repository.dart';
import 'quote_local_notifications.dart';
import 'quote_runtime_store.dart';

/// Lưu tiến trình báo giá — Phase 1 mock, sau nối API quote-requests.
class QuoteProgressRepository {
  QuoteProgressRepository._({BookingMockRepository? partnersRepo})
      : _partnersRepo = partnersRepo ?? BookingMockRepository();

  static final QuoteProgressRepository instance = QuoteProgressRepository._();

  factory QuoteProgressRepository() => instance;

  final BookingMockRepository _partnersRepo;
  static final Map<String, QuoteRequestSnapshot> _store = {};

  Future<QuoteRequestSnapshot> createFromBooking({
    required String referenceId,
    required BookingFlowState state,
    List<String> imageUrls = const [],
  }) async {
    final snapshot = QuoteRequestSnapshot(
      id: referenceId,
      status: QuoteProgressStatus.waitingQuotes,
      pickup: state.pickup,
      destination: state.destination,
      createdAt: DateTime.now(),
      imageUrls: imageUrls,
      dormNote: state.dormNote,
    );
    _store[referenceId] = snapshot;

    Future<void>.delayed(const Duration(seconds: 2), () => _populateQuotes(referenceId));

    return snapshot;
  }

  QuoteRequestSnapshot? peek(String referenceId) => _store[referenceId];

  /// Các chuyến đã đặt — hiển thị tab Hoạt động.
  List<QuoteRequestSnapshot> listBookedTrips() {
    final list = _store.values.where((s) => s.status.isBookedTrip).toList();
    list.sort((a, b) {
      final at = a.scheduledPickupAt ?? a.createdAt;
      final bt = b.scheduledPickupAt ?? b.createdAt;
      return at.compareTo(bt);
    });
    return list;
  }

  Future<QuoteRequestSnapshot?> fetch(String referenceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final snap = _store[referenceId];
    if (snap == null) return null;
    if (snap.status == QuoteProgressStatus.waitingQuotes && snap.quotes.isEmpty) {
      await _populateQuotes(referenceId);
    }

    _ensureRuntimeChat(referenceId);
    await _tryAdvanceMoveDay(referenceId);

    return _store[referenceId];
  }

  void _ensureRuntimeChat(String referenceId) {
    final snap = _store[referenceId];
    if (snap == null) return;
    if (snap.status != QuoteProgressStatus.providerAccepted &&
        snap.status != QuoteProgressStatus.depositPaid &&
        snap.status != QuoteProgressStatus.inProgress) {
      return;
    }

    final convId = snap.conversationId ?? QuoteRuntimeStore.instance.conversationIdFor(referenceId);
    if (QuoteRuntimeStore.instance.conversationById(convId) != null) return;
    if (snap.confirmedQuote == null) return;

    QuoteRuntimeStore.instance.onProviderAccepted(snap);
    _store[referenceId] = snap.copyWith(
      orderId: snap.orderId ?? QuoteRuntimeStore.instance.orderIdFor(referenceId),
      conversationId: convId,
    );
  }

  Future<QuoteRequestSnapshot> confirmProvider({
    required String referenceId,
    required String quoteId,
  }) async {
    final snap = _store[referenceId];
    if (snap == null) throw Exception('Không tìm thấy yêu cầu báo giá');

    final updated = snap.copyWith(
      status: QuoteProgressStatus.providerConfirmed,
      confirmedQuoteId: quoteId,
    );
    _store[referenceId] = updated;
    return updated;
  }

  Future<QuoteRequestSnapshot> selectMoveSlot({
    required String referenceId,
    required MoveTimeSlot slot,
  }) async {
    final snap = _store[referenceId];
    if (snap == null) throw Exception('Không tìm thấy yêu cầu báo giá');
    if (!slot.available) throw Exception('Khung giờ đã được đặt');

    final slotLabel = _formatScheduledLabel(slot);
    final updated = snap.copyWith(
      status: QuoteProgressStatus.scheduled,
      scheduledPickupAt: slot.start,
      scheduledSlotLabel: slotLabel,
    );
    _store[referenceId] = updated;

    Future<void>.delayed(const Duration(seconds: 4), () => _tryAdvanceProviderAccept(referenceId));

    return updated;
  }

  /// Đặt cọc giữ chỗ — chưa bắt đầu vận chuyển ngay.
  Future<QuoteRequestSnapshot> payDeposit(String referenceId) async {
    final snap = _store[referenceId];
    if (snap == null) throw Exception('Không tìm thấy yêu cầu báo giá');
    if (snap.status != QuoteProgressStatus.providerAccepted) {
      throw Exception('Nhà xe chưa xác nhận lịch');
    }

    final orderId = snap.orderId ?? QuoteRuntimeStore.instance.orderIdFor(referenceId);
    final convId = snap.conversationId ?? QuoteRuntimeStore.instance.conversationIdFor(referenceId);
    QuoteRuntimeStore.instance.onDepositPaid(snap);
    QuoteLocalNotifications.scheduleMoveReminders(snap);

    final updated = snap.copyWith(
      status: QuoteProgressStatus.depositPaid,
      depositPaidAt: DateTime.now(),
      orderId: orderId,
      conversationId: convId,
    );
    _store[referenceId] = updated;
    return updated;
  }

  Future<void> _tryAdvanceProviderAccept(String referenceId) async {
    var snap = _store[referenceId];
    if (snap == null || snap.status != QuoteProgressStatus.scheduled) return;

    if (snap.confirmedQuote == null && snap.quotes.isEmpty) {
      await _populateQuotes(referenceId);
      snap = _store[referenceId];
      if (snap == null) return;
    }

    final orderId = QuoteRuntimeStore.instance.orderIdFor(referenceId);
    final convId = QuoteRuntimeStore.instance.conversationIdFor(referenceId);
    if (snap.confirmedQuote != null) {
      QuoteRuntimeStore.instance.onProviderAccepted(snap);
    }

    _store[referenceId] = snap.copyWith(
      status: QuoteProgressStatus.providerAccepted,
      orderId: orderId,
      conversationId: convId,
    );
  }

  Future<void> _tryAdvanceMoveDay(String referenceId) async {
    final snap = _store[referenceId];
    if (snap == null || snap.status != QuoteProgressStatus.depositPaid) return;
    if (!_shouldStartMoveDay(snap)) return;

    final orderId = snap.orderId ?? QuoteRuntimeStore.instance.orderIdFor(referenceId);
    final convId = snap.conversationId ?? QuoteRuntimeStore.instance.conversationIdFor(referenceId);
    QuoteRuntimeStore.instance.onTransportStarted(orderId, convId);

    _store[referenceId] = snap.copyWith(status: QuoteProgressStatus.inProgress);
  }

  bool _shouldStartMoveDay(QuoteRequestSnapshot snap) {
    final at = snap.scheduledPickupAt;
    if (at == null) return false;
    return !DateTime.now().isBefore(at);
  }

  String _formatScheduledLabel(MoveTimeSlot slot) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = slot.start;
    return '${two(d.day)}/${two(d.month)}/${d.year} · ${slot.label}';
  }

  Future<void> _populateQuotes(String referenceId) async {
    final snap = _store[referenceId];
    if (snap == null || snap.quotes.isNotEmpty) return;

    final partners = await _partnersRepo.fetchPartners();
    final quotes = partners.asMap().entries.map((e) {
      final p = e.value;
      final surcharges = _surchargesForPartner(e.key, p);
      return ProviderQuoteResponse(
        id: 'q-${p.id}',
        providerId: p.id,
        providerName: p.name,
        rating: p.rating,
        reviewCount: p.reviewCount,
        completedTrips: p.completedTrips,
        vehicleLabel: p.vehicleLabel,
        distanceKm: p.distanceKm,
        imageUrl: p.imageUrl,
        basePrice: p.price,
        surcharges: surcharges,
        recentReviews: p.recentReviews,
        note: 'Giá gồm xe + khuân vác cơ bản. Phụ phí liệt kê bên dưới.',
      );
    }).toList();

    final status = snap.status == QuoteProgressStatus.waitingQuotes
        ? QuoteProgressStatus.quotesReady
        : snap.status;

    _store[referenceId] = snap.copyWith(status: status, quotes: quotes);
  }

  List<QuoteSurchargeLine> _surchargesForPartner(int index, PartnerOffer p) {
    return switch (index) {
      0 => const [
          QuoteSurchargeLine(label: 'Tầng không thang máy (x2)', amount: 80000),
          QuoteSurchargeLine(label: 'Hẻm hẹp — xe nhỏ', amount: 50000),
        ],
      1 => const [
          QuoteSurchargeLine(label: 'Đồ cồng kềnh thêm', amount: 100000),
        ],
      _ => const [
          QuoteSurchargeLine(label: 'Km vượt gói (3 km)', amount: 21000),
          QuoteSurchargeLine(label: 'Thêm 1 người khuân (1 giờ)', amount: 90000),
        ],
    };
  }

  static void seedDemoIfEmpty() {
    if (_store.isNotEmpty) return;
    _store['QR-DEMO'] = QuoteRequestSnapshot(
      id: 'QR-DEMO',
      status: QuoteProgressStatus.quotesReady,
      pickup: 'Ký túc xá Khu B',
      destination: '152 Nguyễn Văn Cừ, Quận 5',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      quotes: [
        ProviderQuoteResponse(
          id: 'q-p1',
          providerId: 'p1',
          providerName: 'Minh Quân Logistics',
          rating: 4.9,
          reviewCount: 148,
          completedTrips: 1260,
          vehicleLabel: 'Xe tải 1 tấn',
          distanceKm: 1.2,
          imageUrl: AppImages.partnerTruck1,
          basePrice: 250000,
          surcharges: const [
            QuoteSurchargeLine(label: 'Tầng không thang máy (x2)', amount: 80000),
            QuoteSurchargeLine(label: 'Hẻm hẹp', amount: 50000),
          ],
        ),
      ],
    );
  }
}
