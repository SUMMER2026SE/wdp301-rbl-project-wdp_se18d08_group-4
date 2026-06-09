import '../../../core/auth/auth_token_storage.dart';
import '../../../core/network/api_client.dart';
import '../domain/pass_extras.dart';
import '../domain/pass_item.dart';
import '../domain/pass_item_provinces.dart';

class PassItemRepository {
  final ApiClient _api = ApiClient.instance;
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

  static String _statusToApi(PassItemStatus s) => switch (s) {
        PassItemStatus.open => 'active',
        PassItemStatus.reserved => 'reserved',
        PassItemStatus.hidden => 'hidden',
        PassItemStatus.completed => 'closed',
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
      images: images,
      usageDuration: j['usage_duration'] as String? ?? '',
      posterName: owner['full_name'] as String? ?? '',
      posterContact: owner['phone'] as String? ?? '',
      posterId: owner['id'] as String? ?? '',
      posterAvatarUrl: owner['avatar_url'] as String?,
      status: _statusFromApi(j['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(j['created_at'] as String),
      isMine: myId != null && (j['is_mine'] as bool? ?? owner['id'] == myId),
      interestedCount: (j['interest_count'] as num?)?.toInt() ?? 0,
      dealConfirmed: j['deal_confirmed'] as bool? ?? false,
      confirmedPrice: (j['confirmed_price'] as num?)?.toInt(),
      buyerTransportBooked: j['transport_booked'] as bool? ?? false,
      isRated: j['is_rated'] as bool? ?? false,
      isInterested: j['is_interested'] as bool? ?? false,
    );
  }

  Future<String?> _myId() async {
    final user = await AuthTokenStorage.instance.loadUser();
    return user?['id'] as String?;
  }

  Future<String?> currentUserId() => _myId();

  void _updateCache(List<PassItemPost> posts) {
    for (final p in posts) {
      final idx = _cache.indexWhere((c) => c.id == p.id);
      if (idx == -1) _cache.add(p);
      else _cache[idx] = p;
    }
  }

  // ── API-059: Khám phá tin ─────────────────────────────────────────────────

  Future<List<PassItemPost>> browse({String? keyword, String? category, String? provinceId}) async {
    final query = <String, dynamic>{};
    if (keyword != null && keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    if (category != null && category.isNotEmpty && category != 'Tất cả') {
      final apiCat = _categoryToApi[category];
      if (apiCat != null) query['category'] = apiCat;
    }
    if (provinceId != null && provinceId.isNotEmpty) {
      query['area'] = PassItemProvince.resolve(provinceId).label;
    }

    final myId = await _myId();
    final envelope = await _api.guard(() => _api.get('/marketplace/listings', queryParameters: query));
    final raw = (envelope['listings'] as List?) ?? [];
    final posts = raw.map((e) => _fromJson(Map<String, dynamic>.from(e as Map), myId: myId)).toList();
    _updateCache(posts);
    return posts;
  }

  // ── Seller profile: Tin của người bán ───────────────────────────────────

  Future<List<PassItemPost>> browseByOwner(String sellerId) async {
    final myId = await _myId();
    final envelope = await _api.guard(
      () => _api.get('/marketplace/listings', queryParameters: {'seller_id': sellerId}),
    );
    final raw = (envelope['listings'] as List?) ?? [];
    return raw.map((e) => _fromJson(Map<String, dynamic>.from(e as Map), myId: myId)).toList();
  }

  // ── API-060: Tin của tôi ─────────────────────────────────────────────────

  Future<List<PassItemPost>> myPosts() async {
    final myId = await _myId();
    final envelope = await _api.guard(() => _api.get('/marketplace/my-listings'));
    final raw = (envelope['listings'] as List?) ?? [];
    final posts = raw.map((e) => _fromJson(Map<String, dynamic>.from(e as Map), myId: myId)).toList();
    _updateCache(posts);
    return posts;
  }

  // ── API-061: Chi tiết tin ────────────────────────────────────────────────

  Future<PassItemPost?> byId(String id) async {
    final myId = await _myId();
    try {
      final envelope = await _api.guard(() => _api.get('/marketplace/listings/$id'));
      final post = _fromJson(Map<String, dynamic>.from(envelope['data'] as Map), myId: myId);
      _updateCache([post]);
      return post;
    } catch (_) {
      try { return _cache.firstWhere((e) => e.id == id); } catch (_) { return null; }
    }
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
    required List<String> images,
  }) async {
    final myId = await _myId();
    final envelope = await _api.guard(() => _api.post('/marketplace/listings', body: {
      'title': title,
      'description': description.isEmpty ? null : description,
      'category': _categoryToApi[category] ?? 'other',
      'condition': _conditionToApi(condition),
      'area': area.isNotEmpty ? area : PassItemProvince.resolve(provinceId).label,
      'price': price,
      'images': images,
      if (usageDuration.isNotEmpty) 'usage_duration': usageDuration,
    }));
    final post = _fromJson(Map<String, dynamic>.from(envelope['data'] as Map), myId: myId);
    _cache.insert(0, post);
    return post;
  }

  // ── Rating ───────────────────────────────────────────────────────────────

  Future<void> rateTransaction(String listingId, int rating, String? comment) async {
    await _api.guard(() => _api.post('/marketplace/listings/$listingId/rating', body: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    }));
  }

  Future<void> confirmReceived(String listingId) async {
    await _api.guard(() => _api.post('/marketplace/listings/$listingId/confirm-received', body: {}));
  }

  Future<Map<String, dynamic>> sellerStats(String sellerId) async {
    try {
      final envelope = await _api.guard(() => _api.get('/marketplace/seller/$sellerId/stats'));
      return (envelope['data'] as Map?)?.cast<String, dynamic>() ?? {};
    } catch (_) {
      return {};
    }
  }

  // ── Bump listing ─────────────────────────────────────────────────────────

  Future<String?> bumpListing(String id) async {
    try {
      await _api.guard(() => _api.post('/marketplace/listings/$id/bump', body: {}));
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── API-064: Đổi trạng thái tin ──────────────────────────────────────────

  Future<void> updateStatus(String id, PassItemStatus status) async {
    await _api.guard(() => _api.patch('/marketplace/listings/$id/status', body: {'status': _statusToApi(status)}));
    final idx = _cache.indexWhere((e) => e.id == id);
    if (idx != -1) _cache[idx] = _cache[idx].copyWith(status: status);
  }

  // ── API-065: Quan tâm tin ────────────────────────────────────────────────

  Future<void> expressInterest(String id) async {
    final envelope = await _api.guard(() => _api.post('/marketplace/listings/$id/interest', body: {}));
    final newCount = (envelope['data']?['interest_count'] as num?)?.toInt();
    final idx = _cache.indexWhere((e) => e.id == id);
    if (idx != -1 && newCount != null) {
      _cache[idx] = _cache[idx].copyWith(interestedCount: newCount);
    }
  }

  // ── API-065b: Bỏ quan tâm ────────────────────────────────────────────────

  Future<void> removeInterest(String id) async {
    await _api.guard(() => _api.delete('/marketplace/listings/$id/interest'));
  }

  // ── My Interests: Tin tôi quan tâm ───────────────────────────────────────

  Future<List<PassItemPost>> myInterests() async {
    try {
      final myId = await _myId();
      final envelope = await _api.guard(() => _api.get('/marketplace/my-interests'));
      final raw = (envelope['listings'] as List?) ?? [];
      return raw.map((e) => _fromJson(Map<String, dynamic>.from(e as Map), myId: myId)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── API-066: DS khách quan tâm ───────────────────────────────────────────

  Future<List<PassInterestedBuyer>> interestedBuyers(String itemId) async {
    try {
    final envelope = await _api.guard(() => _api.get('/marketplace/listings/$itemId/interests'));
    final raw = (envelope['data'] as List?) ?? [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return PassInterestedBuyer(
        id:             m['id'] as String,
        name:           m['name'] as String? ?? '',
        contact:        m['contact'] as String? ?? '',
        area:           '',
        interestedAt:   DateTime.parse(m['interested_at'] as String),
        note:           m['note'] as String?,
        lastMessage:    m['last_message'] as String?,
        unreadForSeller: (m['unread_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── API-067: Đọc chat ────────────────────────────────────────────────────

  Future<List<PassChatMessage>> messages(String itemId, String? buyerId, {bool markRead = false}) async {
    if (buyerId == null) return [];
    try {
      final envelope = await _api.guard(
        () => _api.get('/marketplace/listings/$itemId/conversations/$buyerId/messages'),
      );
      final raw = (envelope['data']?['messages'] as List?) ?? [];
      return raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final dt = DateTime.parse(m['created_at'] as String).toLocal();
        final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        return PassChatMessage(
          text:          m['text'] as String,
          fromBuyer:     m['from_buyer'] as bool? ?? true,
          time:          timeStr,
          isOffer:       m['is_offer'] as bool? ?? false,
          offerAmount:   (m['offer_amount'] as num?)?.toInt(),
          isDealConfirm: m['is_deal_confirm'] as bool? ?? false,
          isDealCancel:  m['is_deal_cancel'] as bool? ?? false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── API-068: Gửi chat ────────────────────────────────────────────────────

  Future<void> sendMessageApi(String itemId, String? buyerId, PassChatMessage message, {required bool sentBySeller}) async {
    if (buyerId == null) return;
    await _api.guard(() => _api.post(
      '/marketplace/listings/$itemId/conversations/$buyerId/messages',
      body: {
        'text': message.text,
        if (message.isOffer && message.offerAmount != null) ...{
          'is_offer': true,
          'offer_amount': message.offerAmount,
        },
      },
    ));
  }

  // ── sendMessage (gọi API + update local preview) ─────────────────────────

  void sendMessage(String itemId, String? buyerId, PassChatMessage message, {required bool sentBySeller}) {
    if (buyerId == null) return;
    if (message.isDealConfirm || message.isDealCancel) return;
    // Gọi API async, không await (fire-and-forget, UI optimistic update)
    sendMessageApi(itemId, buyerId, message, sentBySeller: sentBySeller);
  }

  void markThreadRead(String itemId, String buyerId) {
    // Handled server-side khi gọi getMessages
  }

  // ── API-073: Upload ảnh tin ──────────────────────────────────────────────

  Future<String> uploadImage({required String filePath}) async {
    final envelope = await _api.guard(
      () => _api.uploadFile('/marketplace/listings/images', filePath: filePath, field: 'image'),
    );
    final url = envelope['data']?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Không nhận được URL ảnh từ server');
    }
    return url;
  }

  // ── API-069: Chốt đơn ────────────────────────────────────────────────────

  Future<bool> confirmDeal(String itemId, {int? agreedPrice, String? buyerId}) async {
    if (buyerId == null) return false;
    try {
      await _api.guard(() => _api.post(
        '/marketplace/listings/$itemId/conversations/$buyerId/deal',
        body: {
          if (agreedPrice != null && agreedPrice > 0) 'agreed_price': agreedPrice,
        },
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── API-070: Huỷ chốt ────────────────────────────────────────────────────

  Future<bool> cancelDealConfirmation(String itemId) async {
    try {
      await _api.guard(() => _api.delete('/marketplace/listings/$itemId/deal'));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── API-071: Buyer đặt xe ─────────────────────────────────────────────────

  Future<void> markTransportBooked(String itemId) async {
    try {
      await _api.guard(() => _api.post(
        '/marketplace/listings/$itemId/transport-booked',
        body: {},
      ));
    } catch (_) {}
  }

  // ── Transport quotes (mock — Batch 4) ────────────────────────────────────

  Future<List<PassTransportQuote>> transportQuotes(PassItemPost post) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return const [
      PassTransportQuote(id: 'tq1', providerName: 'Minh Quân Express', vehicleLabel: 'Xe tải nhỏ 500kg', rating: 4.9, price: 90000, etaMinutes: 20, badge: 'Rẻ nhất'),
      PassTransportQuote(id: 'tq2', providerName: 'FastMove SV', vehicleLabel: 'Xe ba gác', rating: 4.7, price: 75000, etaMinutes: 30),
      PassTransportQuote(id: 'tq3', providerName: 'GreenLine Moving', vehicleLabel: 'Xe tải 1 tấn', rating: 4.8, price: 120000, etaMinutes: 18, badge: 'Nhanh nhất'),
    ];
  }
}
