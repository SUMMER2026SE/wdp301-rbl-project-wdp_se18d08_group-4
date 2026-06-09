import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/auth/auth_token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/dark_glass_background.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../profile/data/provider_profile_repository.dart';

enum _VehicleType { motorbike, pickup, truck }

extension _VehicleTypeExt on _VehicleType {
  String get apiValue => switch (this) {
        _VehicleType.motorbike => 'motorbike',
        _VehicleType.pickup => 'small_truck',
        _VehicleType.truck => 'medium_truck',
      };

  int get defaultBasePrice => switch (this) {
        _VehicleType.motorbike => 80000,
        _VehicleType.pickup => 150000,
        _VehicleType.truck => 250000,
      };
}

class DriverRegistrationPage extends ConsumerStatefulWidget {
  const DriverRegistrationPage({super.key});

  @override
  ConsumerState<DriverRegistrationPage> createState() => _DriverRegistrationPageState();
}

class _DriverRegistrationPageState extends ConsumerState<DriverRegistrationPage> {
  static const _stepLabels = ['Thông tin cá nhân', 'Chi tiết phương tiện', 'Tải lên hồ sơ', 'Hoàn tất'];

  final _picker = ImagePicker();

  int _step = 0;
  bool _submitting = false;
  String _uploadStatus = '';
  String? _error;

  // Step 0 — personal
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Step 1 — vehicle
  _VehicleType? _vehicle;
  final _plateCtrl = TextEditingController();
  XFile? _vehiclePhotoFile;
  Uint8List? _vehiclePhotoPreview;

  // Step 2 — documents
  XFile? _idFrontFile;
  Uint8List? _idFrontPreview;
  XFile? _licenseFrontFile;
  Uint8List? _licenseFrontPreview;
  XFile? _licenseBackFile;
  Uint8List? _licenseBackPreview;
  XFile? _registrationFile;
  Uint8List? _registrationPreview;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    try {
      final profile = await ref.read(providerProfileRepositoryProvider).fetchProfile();
      if (!mounted) return;
      if (_nameCtrl.text.isEmpty && profile.fullName.isNotEmpty) _nameCtrl.text = profile.fullName;
      if (_emailCtrl.text.isEmpty && profile.email.isNotEmpty) _emailCtrl.text = profile.email;
      if (_phoneCtrl.text.isEmpty && profile.phone != null) _phoneCtrl.text = profile.phone!;
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(String docType) async {
    final source = await _showSourceSheet();
    if (source == null) return;
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1920);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        switch (docType) {
          case 'vehicle_photo':
            _vehiclePhotoFile = file;
            _vehiclePhotoPreview = bytes;
          case 'cccd_front':
            _idFrontFile = file;
            _idFrontPreview = bytes;
          case 'license_front':
            _licenseFrontFile = file;
            _licenseFrontPreview = bytes;
          case 'license_back':
            _licenseBackFile = file;
            _licenseBackPreview = bytes;
          case 'vehicle_registration':
            _registrationFile = file;
            _registrationPreview = bytes;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Không thể chọn ảnh: $e');
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final c = UniMoveColors.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(10)),
                    child: Icon(LucideIcons.camera, color: c.primary, size: 20),
                  ),
                  title: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Mở camera để chụp trực tiếp'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: c.iconBgSecondary, borderRadius: BorderRadius.circular(10)),
                    child: Icon(LucideIcons.image, color: c.primaryLight, size: 20),
                  ),
                  title: const Text('Chọn từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Chọn ảnh đã có trong máy'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  bool get _isLastInputStep => _step == 2;

  Future<void> _next() async {
    setState(() => _error = null);

    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Vui lòng nhập họ tên và số điện thoại.');
        return;
      }
    } else if (_step == 1) {
      if (_vehicle == null) {
        setState(() => _error = 'Vui lòng chọn loại xe.');
        return;
      }
      if (_plateCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Vui lòng nhập biển số xe.');
        return;
      }
    } else if (_step == 2) {
      if (_idFrontFile == null || _licenseFrontFile == null || _licenseBackFile == null) {
        setState(() => _error = 'Cần tải lên CCCD và bằng lái (2 mặt).');
        return;
      }
      await _submitRegistration();
      return;
    }

    setState(() => _step += 1);
  }

  Future<void> _submitRegistration() async {
    setState(() { _submitting = true; _uploadStatus = 'Đang cập nhật thông tin...'; });
    try {
      final isMock = await AuthTokenStorage.instance.isMockSession();
      final repo = ref.read(providerProfileRepositoryProvider);

      if (!isMock) {
        await repo.updateProfile(
          phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
          vehicleType: _vehicle?.apiValue,
          basePrice: _vehicle?.defaultBasePrice,
        );

        final docs = <(XFile, String)>[
          if (_idFrontFile != null) (_idFrontFile!, 'cccd_front'),
          if (_licenseFrontFile != null) (_licenseFrontFile!, 'license_front'),
          if (_licenseBackFile != null) (_licenseBackFile!, 'license_back'),
          if (_registrationFile != null) (_registrationFile!, 'vehicle_registration'),
          if (_vehiclePhotoFile != null) (_vehiclePhotoFile!, 'vehicle_photo'),
        ];

        for (var i = 0; i < docs.length; i++) {
          final (file, docType) = docs[i];
          if (mounted) {
            setState(() => _uploadStatus = 'Đang tải lên tài liệu ${i + 1}/${docs.length}...');
          }
          final bytes = await file.readAsBytes();
          await repo.uploadDocument(docType: docType, fileBytes: bytes, filename: file.name);
        }

        ref.invalidate(providerProfileProvider);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }

      if (!mounted) return;
      setState(() => _step += 1);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() { _submitting = false; _uploadStatus = ''; });
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() { _error = null; _step -= 1; });
    }
  }

  void _goHome() {
    final hasSession = AuthTokenStorage.instance.cachedToken?.isNotEmpty == true;
    context.go(hasSession ? '/home' : '/login');
  }

  void _onCheckStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hồ sơ đang được xét duyệt (24–48 giờ)')),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    return ShadScreenScope(
      builder: (_, theme) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const DarkGlassBackground(variant: DarkGlassVariant.subtle),
              SafeArea(
                child: _step == 3
                    ? _PendingView(onCheck: _onCheckStatus, onHome: _goHome)
                    : Column(
                        children: [
                          _header(theme, c),
                          _progress(theme, c),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                              children: [
                                if (_step == 0) ..._personalStep(theme, c),
                                if (_step == 1) ..._vehicleStep(theme, c),
                                if (_step == 2) ..._documentsStep(theme, c),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  _errorBox(theme, c, _error!),
                                ],
                              ],
                            ),
                          ),
                          _bottomBar(theme, c),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(ShadThemeData theme, UniMoveColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 0),
      child: Row(
        children: [
          ShadIconButton.ghost(
            icon: Icon(LucideIcons.arrowLeft, size: 20, color: c.onSurface),
            onPressed: _back,
          ),
          const SizedBox(width: 4),
          Text(
            'Đăng ký đối tác',
            style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w800, color: c.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _progress(ShadThemeData theme, UniMoveColors c) {
    final pct = (_step + 1) / 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BƯỚC ${_step + 1} TRÊN 4',
                style: theme.textTheme.small.copyWith(
                  color: c.onSurfaceMuted, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${(pct * 100).round()}% Hoàn tất',
                style: theme.textTheme.small.copyWith(color: c.primaryLight, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _stepLabels[_step],
            style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w800, color: c.onSurface),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation(c.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: personal ─────────────────────────────────────────────────────

  List<Widget> _personalStep(ShadThemeData theme, UniMoveColors c) {
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primary, c.primaryLight],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bắt đầu hành trình của bạn',
                      style: theme.textTheme.p.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Cung cấp thông tin cơ bản để chúng tôi xác thực hồ sơ đối tác.',
                    style: theme.textTheme.small.copyWith(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.contact, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _field(theme, c, 'Họ và tên', _nameCtrl, 'Nguyễn Văn A', LucideIcons.user),
      const SizedBox(height: 16),
      _field(theme, c, 'Số điện thoại', _phoneCtrl, '0901 234 567', LucideIcons.phone,
          keyboard: TextInputType.phone),
      const SizedBox(height: 16),
      _field(theme, c, 'Địa chỉ Email', _emailCtrl, 'email@vi-du.com', LucideIcons.mail,
          keyboard: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _field(theme, c, 'Địa chỉ thường trú', _addressCtrl,
          'Số nhà, đường, Quận/Huyện, Tỉnh/TP', LucideIcons.mapPin, maxLines: 2),
      const SizedBox(height: 20),
      _securityNote(theme, c),
    ];
  }

  Widget _securityNote(ShadThemeData theme, UniMoveColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.shieldCheck, color: c.success, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cam kết bảo mật',
                    style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
                const SizedBox(height: 2),
                Text(
                  'Thông tin được mã hoá, chỉ dùng cho mục đích xác thực đối tác.',
                  style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: vehicle ──────────────────────────────────────────────────────

  List<Widget> _vehicleStep(ShadThemeData theme, UniMoveColors c) {
    return [
      Text('Chọn loại xe',
          style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
      const SizedBox(height: 10),
      _vehicleOption(theme, c, _VehicleType.motorbike, LucideIcons.bike, 'Xe máy',
          'Linh hoạt & nhanh — phù hợp đồ nhẹ < 50kg'),
      const SizedBox(height: 10),
      _vehicleOption(theme, c, _VehicleType.pickup, LucideIcons.truck, 'Xe bán tải / Xe tải nhỏ',
          'Chở hàng đa năng — khoảng 500kg'),
      const SizedBox(height: 10),
      _vehicleOption(theme, c, _VehicleType.truck, LucideIcons.truck, 'Xe tải vừa',
          'Tải trọng lớn — khoảng 1 tấn'),
      const SizedBox(height: 20),
      Text('Biển số xe',
          style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
      const SizedBox(height: 10),
      _field(theme, c, '', _plateCtrl, 'VD: 43A-123.45', LucideIcons.idCard),
      const SizedBox(height: 8),
      Text('Nhập chính xác biển số hiển thị trên giấy tờ xe.',
          style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
      const SizedBox(height: 20),
      Text('Hình ảnh xe',
          style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
      const SizedBox(height: 10),
      _uploadBox(theme, c,
        title: 'Tải lên ảnh xe',
        subtitle: 'Chụp rõ biển số và thân xe (tối đa 10MB)',
        file: _vehiclePhotoFile,
        preview: _vehiclePhotoPreview,
        onTap: () => _pickImage('vehicle_photo'),
      ),
    ];
  }

  Widget _vehicleOption(ShadThemeData theme, UniMoveColors c, _VehicleType type, IconData icon,
      String title, String subtitle) {
    final selected = _vehicle == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _vehicle = type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? c.primary : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : c.primary, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.p.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : c.onSurface)),
                    Text(subtitle,
                        style: theme.textTheme.small
                            .copyWith(color: selected ? Colors.white70 : c.onSurfaceMuted)),
                  ],
                ),
              ),
              if (selected) const Icon(LucideIcons.circleCheck, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 2: documents ────────────────────────────────────────────────────

  List<Widget> _documentsStep(ShadThemeData theme, UniMoveColors c) {
    return [
      Text('Căn cước công dân (CCCD)',
          style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
      const SizedBox(height: 6),
      Text('Tải ảnh chụp mặt trước rõ nét của CCCD/CMND còn hiệu lực.',
          style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
      const SizedBox(height: 10),
      _uploadBox(theme, c,
        title: 'Mặt trước CCCD',
        subtitle: 'JPG, PNG, WEBP (tối đa 10MB)',
        file: _idFrontFile,
        preview: _idFrontPreview,
        onTap: () => _pickImage('cccd_front'),
      ),
      const SizedBox(height: 20),
      Text('Bằng lái xe',
          style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
      const SizedBox(height: 6),
      Text('Chụp cả hai mặt của giấy phép lái xe.',
          style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
      const SizedBox(height: 10),
      _uploadBox(theme, c,
        title: 'Mặt trước bằng lái',
        subtitle: 'JPG, PNG, WEBP',
        file: _licenseFrontFile,
        preview: _licenseFrontPreview,
        onTap: () => _pickImage('license_front'),
      ),
      const SizedBox(height: 10),
      _uploadBox(theme, c,
        title: 'Mặt sau bằng lái',
        subtitle: 'JPG, PNG, WEBP',
        file: _licenseBackFile,
        preview: _licenseBackPreview,
        onTap: () => _pickImage('license_back'),
      ),
      const SizedBox(height: 20),
      Text('Đăng ký xe (Cà vẹt)',
          style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
      const SizedBox(height: 6),
      Text('Không bắt buộc — có thể bổ sung sau.',
          style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
      const SizedBox(height: 10),
      _uploadBox(theme, c,
        title: 'Giấy đăng ký xe',
        subtitle: 'Bản gốc hoặc bản sao công chứng',
        file: _registrationFile,
        preview: _registrationPreview,
        onTap: () => _pickImage('vehicle_registration'),
        optional: true,
      ),
    ];
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _uploadBox(
    ShadThemeData theme,
    UniMoveColors c, {
    required String title,
    required String subtitle,
    required XFile? file,
    required Uint8List? preview,
    required VoidCallback onTap,
    bool optional = false,
  }) {
    final done = file != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: done ? c.iconBgTertiary : c.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done ? c.success : c.glassBorderStrong,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              // Thumbnail or icon
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: done && preview != null
                    ? Image.memory(preview, width: 52, height: 52, fit: BoxFit.cover)
                    : Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 24),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            done ? '$title — đã chọn' : title,
                            style: theme.textTheme.p
                                .copyWith(fontWeight: FontWeight.w700, color: c.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (optional && !done)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.surfaceHigh,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: c.border),
                            ),
                            child: Text('Tuỳ chọn',
                                style: theme.textTheme.small.copyWith(
                                    color: c.onSurfaceMuted, fontSize: 10)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done ? file.name : subtitle,
                      style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                done ? LucideIcons.circleCheck : LucideIcons.upload,
                color: done ? c.success : c.onSurfaceMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(ShadThemeData theme, UniMoveColors c, String label,
      TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600, color: c.onSurface)),
          const SizedBox(height: 8),
        ],
        ShadInput(
          controller: ctrl,
          placeholder: Text(hint),
          leading: Icon(icon, size: 18),
          keyboardType: keyboard,
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget _errorBox(ShadThemeData theme, UniMoveColors c, String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: theme.textTheme.small.copyWith(color: const Color(0xFF991B1B))),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(ShadThemeData theme, UniMoveColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: c.glassCard,
        border: Border(top: BorderSide(color: c.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_submitting && _uploadStatus.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(_uploadStatus,
                      style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
                ],
              ),
            ),
          ],
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.onSurface,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitting ? null : _back,
                    child: const Text('Quay lại'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : _next,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLastInputStep ? 'Hoàn tất đăng ký' : 'Tiếp tục',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.arrowRight, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pending screen ────────────────────────────────────────────────────────────

class _PendingView extends StatelessWidget {
  const _PendingView({required this.onCheck, required this.onHome});

  final VoidCallback onCheck;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final theme = ShadTheme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.primary, c.primaryLight]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: c.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(LucideIcons.clock, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 24),
        Text('Đang chờ phê duyệt',
            textAlign: TextAlign.center,
            style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.w800, color: c.onSurface)),
        const SizedBox(height: 10),
        Text(
          'Cảm ơn bạn đã hoàn thành đăng ký! UniMove đang kiểm tra hồ sơ của bạn.',
          textAlign: TextAlign.center,
          style: theme.textTheme.p.copyWith(color: c.onSurfaceMuted, height: 1.5),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.surfaceHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              _infoRow(theme, c, c.primary, LucideIcons.clock, 'Thời gian dự kiến',
                  'Chúng tôi sẽ xác minh tài liệu trong vòng 24–48 giờ tới.'),
              const SizedBox(height: 18),
              _infoRow(theme, c, c.success, LucideIcons.bellRing, 'Thông báo phê duyệt',
                  'Bạn sẽ nhận thông báo qua Email và ứng dụng ngay khi hồ sơ được duyệt.'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onCheck,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.refreshCw, size: 18),
                SizedBox(width: 8),
                Text('Kiểm tra trạng thái', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: c.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: c.surfaceHigh,
            ),
            onPressed: onHome,
            child: const Text('Về trang chủ', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(ShadThemeData theme, UniMoveColors c, Color tint, IconData icon,
      String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.p
                      .copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
              const SizedBox(height: 2),
              Text(body,
                  style: theme.textTheme.small
                      .copyWith(color: c.onSurfaceMuted, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}
