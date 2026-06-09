import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_token_storage.dart';
import '../../../core/mock/mock_provider_data.dart';
import '../../../core/network/api_client.dart';
import '../../auth/domain/provider_profile.dart';

final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>((ref) {
  return ProviderProfileRepository(ref.watch(apiClientProvider));
});

class ProviderProfileRepository {
  ProviderProfileRepository(this._api);

  final ApiClient _api;

  // ── Profile ───────────────────────────────────────────────────────────────

  /// GET /providers/me — full provider profile.
  /// Fallback về /auth/me nếu /providers/me trả lỗi (provider chưa có bản ghi provider_profiles).
  Future<ProviderProfile> fetchProfile() async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      return MockProviderData.profile;
    }
    try {
      final envelope = await _api.guard(() => _api.get('/providers/me'));
      return ProviderProfile.fromJson(envelope['data'] as Map<String, dynamic>);
    } catch (_) {
      final envelope = await _api.guard(() => _api.get('/auth/me'));
      return ProviderProfile.fromJson(envelope['data'] as Map<String, dynamic>);
    }
  }

  /// PATCH /providers/me — update editable profile fields.
  Future<ProviderProfile> updateProfile({
    String? fullName,
    String? phone,
    String? businessName,
    String? vehicleType,
    List<String>? serviceAreas,
    int? basePrice,
    int? pricePerKm,
  }) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return MockProviderData.profile;
    }
    final body = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (businessName != null) 'business_name': businessName,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (serviceAreas != null) 'service_area': serviceAreas,
      if (basePrice != null) 'base_price': basePrice,
      if (pricePerKm != null) 'price_per_km': pricePerKm,
    };
    final envelope = await _api.guard(() => _api.patch('/providers/me', body: body));
    return ProviderProfile.fromJson(envelope['data'] as Map<String, dynamic>);
  }

  /// POST /providers/me/avatar — multipart upload; returns updated avatar URL.
  Future<String> uploadAvatar(String filePath) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return 'https://api.dicebear.com/7.x/initials/png?seed=MQ';
    }
    final envelope = await _api.guard(
      () => _api.post('/providers/me/avatar', body: {'file_path': filePath}),
    );
    return envelope['data']?['avatar_url'] as String? ?? '';
  }

  /// POST /providers/me/documents — upload ảnh tài liệu lên Cloudinary qua backend.
  /// [docType]: cccd_front | license_front | license_back | vehicle_registration | vehicle_photo
  /// Trả về Cloudinary URL của ảnh vừa upload.
  Future<String> uploadDocument({
    required String docType,
    required Uint8List fileBytes,
    required String filename,
  }) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return 'https://res.cloudinary.com/demo/image/upload/sample.jpg';
    }
    final envelope = await _api.guard(
      () => _api.postMultipart(
        '/providers/me/documents',
        fileBytes: fileBytes,
        filename: filename,
        fileField: 'file',
        fields: {'doc_type': docType},
      ),
    );
    return envelope['data']?['url'] as String? ?? '';
  }

  // ── Online status ─────────────────────────────────────────────────────────

  /// PATCH /providers/me/status  { is_available: bool }
  /// Toggles provider online/offline; backend broadcasts via Supabase realtime.
  Future<void> setOnlineStatus({required bool isOnline}) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }
    await _api.guard(
      () => _api.patch('/providers/me/status', body: {'is_available': isOnline}),
    );
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// GET /providers/me/schedule
  Future<Map<String, dynamic>> fetchSchedule() async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      return _mockSchedule;
    }
    final envelope = await _api.guard(() => _api.get('/providers/me/schedule'));
    return Map<String, dynamic>.from(envelope['data'] as Map);
  }

  /// PATCH /providers/me/schedule
  Future<void> updateSchedule(Map<String, dynamic> schedule) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }
    await _api.guard(() => _api.patch('/providers/me/schedule', body: schedule));
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  /// GET /providers/me/documents
  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      return MockProviderData.documents
          .map((d) => {'title': d.title, 'requirement': d.requirement, 'status': d.status})
          .toList();
    }
    final envelope = await _api.guard(() => _api.get('/providers/me/documents'));
    final rows = envelope['data'] as List<dynamic>? ?? [];
    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Earnings summary ──────────────────────────────────────────────────────

  /// GET /providers/me/earnings?period=today|week|month|all
  /// Returns a summary; if endpoint unavailable, data is computed client-side
  /// from the orders list in [EarningsTabPage].
  Future<Map<String, dynamic>> fetchEarningsSummary({String period = 'all'}) async {
    if (await AuthTokenStorage.instance.isMockSession()) {
      return {'period': period, 'gross': 0, 'net': 0, 'count': 0};
    }
    final envelope = await _api.guard(
      () => _api.get('/providers/me/earnings?period=$period'),
    );
    return Map<String, dynamic>.from(envelope['data'] as Map);
  }
}

// ── Mock schedule data ────────────────────────────────────────────────────────

const _mockSchedule = <String, dynamic>{
  'working_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  'start_time': '07:00',
  'end_time': '20:00',
  'max_orders_per_day': 5,
  'preferred_areas': ['Quận Ngũ Hành Sơn', 'Quận Hải Châu', 'Quận Thanh Khê'],
};
