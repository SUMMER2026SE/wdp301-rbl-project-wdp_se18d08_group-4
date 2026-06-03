import '../../../core/auth/auth_token_storage.dart';
import '../../../core/network/api_client.dart';
import '../domain/pass_extras.dart';
import '../domain/pass_item.dart';
import '../domain/pass_item_provinces.dart';

class PassItemRepository {
  final ApiClient _api = ApiClient.instance;

  // Cache API results cho byId lookup
  final List<PassItemPost> _cache = [];

  // ── Mapping helpers ───────────────────────────────────────────────────────

  static const _categoryToApi = <String, String>{
    'Nội thất': 'furniture',
    'Điện tử': 'electronics',
    'Gia dụng': 'appliances',
    'Sách & VPP': 'books',
    'Quần áo': 'clothes',
    'Khác': 'other',
  };

  static const _categoryFromApi = <String, String>{
    'furniture': 'Nội thất',
    'electronics': 'Điện tử',
    'appliances': 'Gia dụng',
    'books': 'Sách & VPP',
    'clothes': 'Quần áo',
    'other': 'Khác',
  };

  static PassItemCondition _conditionFromApi(String c) => switch (c) {
        'new' || 'like_new' => PassItemCondition.likeNew,
        'good' => PassItemCondition.good,
        _ => PassItemCondition.fair,
      };

  static String _conditionToApi(PassItemCondition c) => switch (c) {
        PassItemCondition.likeNew => 'like_new',
        PassItemCondition.good => 'good',
        PassItemCondition.fair => 'fair',
      };

  static PassItemStatus _statusFromApi(String s) => switch (s) {
        'active' => PassItemStatus.open,
        'reserved' => PassItemStatus.reserved,
        'hidden' => PassItemStatus.hidden,
        _ => PassItemStatus.completed,
      };

  static PassItemPost _fromJson(Map<String, dynamic> j, {String? myId}) {
    final owner = (j['profiles'] as Map?)?.cast<String, dynamic>() ?? {};
    final images = (j['images'] as List?)?.cast<String>() ?? [];
    final rawCat = j['category'] as String? ?? 'other';
    return PassItemPost(
      id: j['id'] as String,
      title: j['title'] as String,
      description: j['description'] as String? ?? '',
      category: _categoryFromApi[rawCat] ?? rawCat,
      condition: _conditionFromApi(j['condition'] as String? ?? 'good'),
      area: j['area'] as String? ?? '',
      provinceId: PassItemProvince.detectId(j['area'] as String? ?? ''),
      price: (j['price'] as num?)?.toInt() ?? 0,
      imageUrl: images.isNotEmpty ? images.first : '',
      usageDuration: '',
      posterName: owner['full_name'] as String? ?? '',
      posterContact: '',
      status: _statusFromApi(j['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(j['created_at'] as String),
      isMine: myId != null && owner['id'] == myId,
    );
  }

  Future<String?> _myId() async {
    final user = await AuthTokenStorage.instance.loadUser();
    return user?['id'] as String?;
  }

  void _updateCache(List<PassItemPost> posts) {
    for (final p in posts) {
      final idx = _cache.indexWhere((c) => c.id == p.id);
      if (idx == -1) {
        _cache.add(p);
      } else {
        _cache[idx] = p;
      }
    }
  }

  // ── API-059: Khám phá tin ─────────────────────────────────────────────────

  Future<List<PassItemPost>> browse({
    String? keyword,
    String? category,
    String? provinceId,
  }) async {
    final query = <String, dynamic>{};
    if (keyword != null && keyword.trim().isNotEmpty) {
      query['keyword'] = keyword.trim();
    }
    if (category != null && category.isNotEmpty && category != 'Tất cả') {
      final apiCat = _categoryToApi[category];
      if (apiCat != null) query['category'] = apiCat;
    }
    if (provinceId != null && provinceId.isNotEmpty) {
      query['area'] = PassItemProvince.resolve(provinceId).label;
    }

    final myId = await _myId();
    final envelope = await _api.guard(
      () => _api.get('/marketplace/listings', queryParameters: query),
    );
    final raw = (envelope['listings'] as List?) ?? [];
    final posts = raw
        .map((e) => _fromJson(Map<String, dynamic>.from(e as Map), myId: myId))
        .toList();
    _updateCache(posts);
    return posts;
  }

  // ── API-060: Tin của tôi ─────────────────────────────────────────────────

  Future<List<PassItemPost>> myPosts() async {
    final myId = await _myId();
    final envelope = await _api.guard(
      () => _api.get('/marketplace/my-listings'),
    );
    final raw = (envelope['listings'] as List?) ?? [];
    final posts = raw
        .map((e) => _fromJson(Map<String, dynamic>.from(e as Map), myId: myId))
        .toList();
    _updateCache(posts);
    return posts;
  }

  // ── API-062: Đăng tin mới ─────────────────────────────────────────────────

  Future<PassItemPost> create({
    required String title,
    required String description,
    required String category,
    required PassItemCondition condition,
    required String area,
    required String provinceId,
    required int price,
    required String usageDuration,
    required bool isNegotiable,
    required String imageUrl,
  }) async {
    final myId = await _myId();
    final body = <String, dynamic>{
      'title': title,
      'description': description.isEmpty ? null : description,
      'category': _categoryToApi[category] ?? 'other',
      'condition': _conditionToApi(condition),
      'area': PassItemProvince.formatArea(detail: area, provinceId: provinceId),
      'price': price,
      'images': imageUrl.isNotEmpty ? [imageUrl] : [],
    };

    final envelope = await _api.guard(
      () => _api.post('/marketplace/listings', body: body),
    );
    final post = _fromJson(
      Map<String, dynamic>.from(envelope['data'] as Map),
      myId: myId,
    );
    _cache.insert(0, post);
    return post;
  }

  // ── byId: tìm trong cache (sau khi browse/myPosts đã load) ───────────────

  Future<PassItemPost?> byId(String id) async {
    try {
      return _cache.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Upload ảnh (mock: trả path local; API thật ở API-073 Batch 5) ────────

  Future<String> uploadImage({required String filePath}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return filePath;
  }

  // ── Các method bên dưới vẫn dùng mock — sẽ chuyển sang API ở Batch 2/3/4 ─

  Future<void> updateStatus(String id, PassItemStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final idx = _cache.indexWhere((e) => e.id == id);
    if (idx != -1) _cache[idx] = _cache[idx].copyWith(status: status);
  }

  Future<bool> confirmDeal(String itemId, {int? agreedPrice}) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final idx = _cache.indexWhere((e) => e.id == itemId);
    if (idx == -1) return false;
    final post = _cache[idx];
    if (!post.isMine || post.dealConfirmed || post.buyerTransportBooked) return false;

    final price = agreedPrice ?? (post.isFree ? 0 : post.price);
    _cache[idx] = post.copyWith(
      dealConfirmed: true,
      confirmedPrice: post.isFree ? 0 : price,
      status: PassItemStatus.reserved,
    );

    final priceLine = post.isFree ? 'đồ cho tặng' : 'giá ${_formatMoney(price)}';
    _appendSystemToAllThreads(
      itemId,
      PassChatMessage(
        text: 'Đã chốt đơn ($priceLine). Bạn có thể đặt xe lấy đồ ngay.',
        fromBuyer: false,
        time: _now(),
        isDealConfirm: true,
      ),
    );
    return true;
  }

  Future<bool> cancelDealConfirmation(String itemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final idx = _cache.indexWhere((e) => e.id == itemId);
    if (idx == -1) return false;
    final post = _cache[idx];
    if (!post.sellerCanCancelDeal) return false;

    _cache[idx] = post.copyWith(
      dealConfirmed: false,
      clearConfirmedPrice: true,
      status: PassItemStatus.open,
    );

    _appendSystemToAllThreads(
      itemId,
      PassChatMessage(
        text:
            'Người bán đã huỷ chốt đơn. Thương lượng lại giá — đặt xe sẽ mở sau khi chốt đơn lần nữa.',
        fromBuyer: false,
        time: _now(),
        isDealCancel: true,
      ),
    );
    return true;
  }

  Future<void> markTransportBooked(String itemId) async {
    final idx = _cache.indexWhere((e) => e.id == itemId);
    if (idx == -1) return;
    final post = _cache[idx];
    if (!post.dealConfirmed || post.buyerTransportBooked) return;
    _cache[idx] = post.copyWith(buyerTransportBooked: true);
  }

  // ── Interested buyers (mock — Batch 2) ───────────────────────────────────

  static const currentBuyerId = 'buyer_me';

  static final PassInterestedBuyer currentBuyer = PassInterestedBuyer(
    id: currentBuyerId,
    name: 'Nguyễn Văn An',
    contact: '0918 333 444',
    area: 'KTX Khu A, ĐHQG',
    interestedAt: DateTime(2026, 6, 3, 10, 0),
    note: 'Tôi muốn nhận món này',
  );

  static final Map<String, List<PassInterestedBuyer>> _interestedByPost = {};

  Future<List<PassInterestedBuyer>> interestedBuyers(String itemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final list =
        List<PassInterestedBuyer>.from(_interestedByPost[itemId] ?? const []);
    for (final b in list) {
      _ensureThread(itemId, b.id);
    }
    list.sort((a, b) => b.interestedAt.compareTo(a.interestedAt));
    return list;
  }

  Future<void> expressInterest(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final idx = _cache.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final buyers = _interestedByPost.putIfAbsent(id, () => []);
    if (!buyers.any((b) => b.id == currentBuyerId)) {
      buyers.insert(
        0,
        PassInterestedBuyer(
          id: currentBuyer.id,
          name: currentBuyer.name,
          contact: currentBuyer.contact,
          area: currentBuyer.area,
          interestedAt: DateTime.now(),
          note: currentBuyer.note,
          lastMessage: 'Chào bạn, mình quan tâm món này.',
        ),
      );
      _ensureThread(id, currentBuyerId, seedBuyerOpens: true);
    }
    _cache[idx] =
        _cache[idx].copyWith(interestedCount: buyers.length);
  }

  void markThreadRead(String itemId, String buyerId) {
    final buyers = _interestedByPost[itemId];
    if (buyers == null) return;
    final i = buyers.indexWhere((b) => b.id == buyerId);
    if (i != -1) buyers[i] = buyers[i].copyWith(unreadForSeller: 0);
  }

  // ── Chat (mock — Batch 3) ─────────────────────────────────────────────────

  static final Map<String, List<PassChatMessage>> _chats = {};

  static String _threadKey(String itemId, String buyerId) =>
      '$itemId::$buyerId';

  void _ensureThread(String itemId, String buyerId,
      {bool seedBuyerOpens = false}) {
    final key = _threadKey(itemId, buyerId);
    if (_chats.containsKey(key)) return;
    if (seedBuyerOpens) {
      _chats[key] = [
        PassChatMessage(
          text: 'Chào bạn, mình quan tâm món này.',
          fromBuyer: true,
          time: _now(),
        ),
        const PassChatMessage(
          text: 'Chào bạn, mình vẫn còn món này nhé. Bạn quan tâm phần nào?',
          fromBuyer: false,
          time: '09:02',
        ),
      ];
    } else {
      _chats[key] = [
        const PassChatMessage(
          text: 'Chào shop, mình muốn hỏi thêm về món này.',
          fromBuyer: true,
          time: '09:01',
        ),
        const PassChatMessage(
          text: 'Chào bạn, mình vẫn còn món này nhé.',
          fromBuyer: false,
          time: '09:02',
        ),
      ];
    }
  }

  void _appendSystemToAllThreads(String itemId, PassChatMessage message) {
    final buyers = _interestedByPost[itemId] ?? const [];
    if (buyers.isEmpty) {
      final key = _threadKey(itemId, currentBuyerId);
      _chats.putIfAbsent(key, () => []);
      _chats[key]!.add(message);
      return;
    }
    for (final b in buyers) {
      final key = _threadKey(itemId, b.id);
      _chats.putIfAbsent(key, () => []);
      _chats[key]!.add(message);
    }
  }

  Future<List<PassChatMessage>> messages(
    String itemId,
    String buyerId, {
    bool markRead = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _ensureThread(itemId, buyerId);
    if (markRead) markThreadRead(itemId, buyerId);
    final key = _threadKey(itemId, buyerId);
    return List<PassChatMessage>.from(_chats[key]!);
  }

  void sendMessage(
    String itemId,
    String buyerId,
    PassChatMessage message, {
    required bool sentBySeller,
  }) {
    if (message.isDealConfirm || message.isDealCancel) return;
    final key = _threadKey(itemId, buyerId);
    _chats.putIfAbsent(key, () => []);
    final stored = PassChatMessage(
      text: message.text,
      fromBuyer: !sentBySeller,
      time: message.time,
      isOffer: message.isOffer,
      offerAmount: message.offerAmount,
    );
    _chats[key]!.add(stored);
    _updateBuyerPreview(itemId, buyerId, stored.text, sentBySeller: sentBySeller);

    final reply = stored.isOffer
        ? PassChatMessage(
            text: sentBySeller
                ? 'Mình chấp nhận mức ${message.offerAmount}đ, bạn đặt xe nhé!'
                : 'Mình xem giá ${message.offerAmount}đ nhé, bạn qua lấy được luôn không?',
            fromBuyer: sentBySeller,
            time: _now(),
          )
        : PassChatMessage(
            text: sentBySeller
                ? 'Ok bạn, mình chờ bạn đặt xe nhé!'
                : 'Ok bạn, mình phản hồi ngay nhé!',
            fromBuyer: sentBySeller,
            time: _now(),
          );
    _chats[key]!.add(reply);
    _updateBuyerPreview(itemId, buyerId, reply.text,
        sentBySeller: reply.fromBuyer == false);
  }

  void _updateBuyerPreview(
    String itemId,
    String buyerId,
    String text, {
    required bool sentBySeller,
  }) {
    final buyers = _interestedByPost[itemId];
    if (buyers == null) return;
    final i = buyers.indexWhere((b) => b.id == buyerId);
    if (i == -1) return;
    buyers[i] = buyers[i].copyWith(
      lastMessage: text,
      unreadForSeller: sentBySeller
          ? buyers[i].unreadForSeller
          : buyers[i].unreadForSeller + 1,
    );
  }

  // ── Transport quotes (mock — Batch 4) ────────────────────────────────────

  Future<List<PassTransportQuote>> transportQuotes(PassItemPost post) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return const [
      PassTransportQuote(
        id: 'tq1',
        providerName: 'Minh Quân Express',
        vehicleLabel: 'Xe tải nhỏ 500kg',
        rating: 4.9,
        price: 90000,
        etaMinutes: 20,
        badge: 'Rẻ nhất',
      ),
      PassTransportQuote(
        id: 'tq2',
        providerName: 'FastMove SV',
        vehicleLabel: 'Xe ba gác',
        rating: 4.7,
        price: 75000,
        etaMinutes: 30,
      ),
      PassTransportQuote(
        id: 'tq3',
        providerName: 'GreenLine Moving',
        vehicleLabel: 'Xe tải 1 tấn',
        rating: 4.8,
        price: 120000,
        etaMinutes: 18,
        badge: 'Nhanh nhất',
      ),
    ];
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _formatMoney(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  static String _now() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }
}
