import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../domain/provider_document_models.dart';

class ProviderDocumentsRepository {
  ProviderDocumentsRepository(this._api);

  final ApiClient _api;
  static const _storageKey = 'provider_documents_kyc_v2';

  // ── Backend doc_type → Flutter ProviderDocumentType ──────────────────────
  static ProviderDocumentType? _fromApiType(String apiType) => switch (apiType) {
        'cccd_front' || 'id_card_front' => ProviderDocumentType.idCardFront,
        'cccd_back' || 'id_card_back'   => ProviderDocumentType.idCardBack,
        'license_front' || 'license'    => ProviderDocumentType.license,
        'license_back'                  => ProviderDocumentType.license,
        'vehicle_registration'          => ProviderDocumentType.vehicleRegistration,
        'vehicle_photo'                 => ProviderDocumentType.vehiclePhoto,
        'insurance'                     => ProviderDocumentType.insurance,
        'business_license'              => ProviderDocumentType.businessLicense,
        _                               => null,
      };

  static DocumentReviewStatus _fromApiStatus(String? s) => switch (s) {
        'approved' => DocumentReviewStatus.approved,
        'rejected' => DocumentReviewStatus.rejected,
        'pending'  => DocumentReviewStatus.pending,
        _          => DocumentReviewStatus.pending,
      };

  // ── Load: API-first, fall back to local cache ─────────────────────────────
  Future<ProviderVerificationState> load() async {
    try {
      final envelope = await _api.guard(() => _api.get('/providers/me/documents'));
      final list = (envelope['data'] as List<dynamic>?) ?? [];

      // Build a map from ProviderDocumentType → record (last upload wins for duplicates)
      final Map<ProviderDocumentType, ProviderDocumentRecord> byType = {};
      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);
        final type = _fromApiType(map['document_type'] as String? ?? '');
        if (type == null) continue;
        byType[type] = ProviderDocumentRecord(
          type: type,
          status: _fromApiStatus(map['status'] as String?),
          previewLabel: map['document_url'] as String?,
          uploadedAt: map['created_at'] != null
              ? DateTime.tryParse(map['created_at'] as String)
              : null,
        );
      }

      // Merge: all template types, fill in from API data
      final docs = ProviderDocumentType.values.map((t) {
        return byType[t] ?? ProviderDocumentRecord(type: t, status: DocumentReviewStatus.notUploaded);
      }).toList();

      final state = _recomputeKyc(ProviderVerificationState(
        documents: docs,
        kycStatus: ProviderKycStatus.incomplete,
      ));
      await _saveLocal(state);
      return state;
    } catch (_) {
      return _loadLocal();
    }
  }

  // ── Local cache ───────────────────────────────────────────────────────────
  Future<ProviderVerificationState> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return _emptyState();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final docs = (map['documents'] as List<dynamic>)
        .map((e) => ProviderDocumentRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProviderVerificationState(
      documents: _mergeWithTemplate(docs),
      kycStatus: ProviderKycStatus.values.firstWhere(
        (s) => s.name == map['kyc_status'],
        orElse: () => ProviderKycStatus.incomplete,
      ),
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'] as String)
          : null,
      reviewNote: map['review_note'] as String?,
    );
  }

  Future<void> save(ProviderVerificationState state) => _saveLocal(state);

  Future<void> _saveLocal(ProviderVerificationState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'kyc_status': state.kycStatus.name,
        'submitted_at': state.submittedAt?.toIso8601String(),
        'review_note': state.reviewNote,
        'documents': state.documents.map((d) => d.toJson()).toList(),
      }),
    );
  }

  // ── Upload (local state update — actual file upload done in registration) ─
  Future<ProviderVerificationState> uploadDocument({
    required ProviderDocumentType type,
    String? documentNumber,
    DateTime? expiryDate,
    String previewLabel = 'Đã chọn ảnh',
  }) async {
    final state = await _loadLocal();
    final updated = state.documents.map((d) {
      if (d.type != type) return d;
      return d.copyWith(
        status: DocumentReviewStatus.pending,
        documentNumber: documentNumber,
        expiryDate: expiryDate,
        uploadedAt: DateTime.now(),
        rejectionReason: null,
        previewLabel: previewLabel,
      );
    }).toList();
    final newState = _recomputeKyc(state.copyWith(documents: updated));
    await _saveLocal(newState);
    return newState;
  }

  Future<ProviderVerificationState> submitForReview() async {
    final state = await _loadLocal();
    if (!state.allRequiredUploaded) {
      throw StateError('Chưa đủ giấy tờ bắt buộc');
    }
    final newState = state.copyWith(
      kycStatus: ProviderKycStatus.pendingReview,
      submittedAt: DateTime.now(),
      reviewNote: null,
    );
    await _saveLocal(newState);
    return newState;
  }

  // ── Demo / mock helpers ───────────────────────────────────────────────────
  static ProviderVerificationState fullyVerifiedDemoState() {
    final submitted = DateTime(2026, 5, 12);
    final docs = ProviderDocumentType.values.map((t) {
      final (String? number, DateTime? expiry) = switch (t) {
        ProviderDocumentType.license => ('B2-123456', DateTime(2030, 8, 1)),
        ProviderDocumentType.vehicleRegistration => ('51C-12345', null),
        ProviderDocumentType.insurance => ('BH-2026-88421', DateTime(2027, 1, 1)),
        ProviderDocumentType.businessLicense => ('GPKD-0312789456', DateTime(2028, 12, 31)),
        _ => (null, null),
      };
      return ProviderDocumentRecord(
        type: t,
        status: DocumentReviewStatus.approved,
        previewLabel: '${t.id}.jpg',
        documentNumber: number,
        expiryDate: expiry,
        uploadedAt: submitted,
      );
    }).toList();
    return ProviderVerificationState(
      documents: docs,
      kycStatus: ProviderKycStatus.approved,
      submittedAt: submitted,
      reviewNote: null,
    );
  }

  Future<void> seedVerifiedDemoProvider() => _saveLocal(fullyVerifiedDemoState());

  static Future<void> seedDemo() async {
    final prefs = await SharedPreferences.getInstance();
    final state = fullyVerifiedDemoState();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'kyc_status': state.kycStatus.name,
        'submitted_at': state.submittedAt?.toIso8601String(),
        'review_note': state.reviewNote,
        'documents': state.documents.map((d) => d.toJson()).toList(),
      }),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  ProviderVerificationState _emptyState() => ProviderVerificationState(
        documents: ProviderDocumentType.values
            .map((t) => ProviderDocumentRecord(type: t, status: DocumentReviewStatus.notUploaded))
            .toList(),
        kycStatus: ProviderKycStatus.incomplete,
      );

  ProviderVerificationState _recomputeKyc(ProviderVerificationState state) {
    final required = state.requiredDocs;
    final allApproved = required.every((d) => d.status == DocumentReviewStatus.approved);
    final anyRejected = state.hasRejected;
    final allUploaded = state.allRequiredUploaded;
    final anyPending = required.any((d) => d.status == DocumentReviewStatus.pending);

    final kyc = anyRejected
        ? ProviderKycStatus.rejected
        : allApproved
            ? ProviderKycStatus.approved
            : allUploaded && (anyPending || state.kycStatus == ProviderKycStatus.pendingReview)
                ? ProviderKycStatus.pendingReview
                : ProviderKycStatus.incomplete;

    return state.copyWith(kycStatus: kyc);
  }

  List<ProviderDocumentRecord> _mergeWithTemplate(List<ProviderDocumentRecord> saved) {
    return ProviderDocumentType.values.map((t) {
      final hit = saved.where((d) => d.type == t);
      return hit.isEmpty
          ? ProviderDocumentRecord(type: t, status: DocumentReviewStatus.notUploaded)
          : hit.first;
    }).toList();
  }
}

extension on ProviderVerificationState {
  ProviderVerificationState copyWith({
    List<ProviderDocumentRecord>? documents,
    ProviderKycStatus? kycStatus,
    DateTime? submittedAt,
    String? reviewNote,
  }) {
    return ProviderVerificationState(
      documents: documents ?? this.documents,
      kycStatus: kycStatus ?? this.kycStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewNote: reviewNote,
    );
  }
}
