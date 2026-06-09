import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/auth/auth_token_storage.dart';
import '../../../../core/services/auth_session_notifier.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/dark_glass_background.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../data/auth_repository.dart';

const _pollInterval = Duration(seconds: 30);

class PendingApprovalPage extends ConsumerStatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  ConsumerState<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends ConsumerState<PendingApprovalPage> {
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Poll mỗi 30 giây
    _timer = Timer.periodic(_pollInterval, (_) => _checkApproval());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkApproval({bool manual = false}) async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final profile = await ref.read(authRepositoryProvider).fetchProfileFallback();
      if (!mounted) return;

      if (profile?.status == 'active') {
        _timer?.cancel();
        AuthTokenStorage.instance.updateCachedStatus('active');
        // Không gọi notifyAuthChanged() ở đây — sẽ gây redirect ngay,
        // dialog chưa kịp hiện. Gọi sau khi user bấm "Vào trang chủ".
        _showApprovedDialog();
        return;
      }

      if (manual) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Chưa có cập nhật'),
            description: Text('Hồ sơ vẫn đang được xét duyệt. Vui lòng thử lại sau.'),
          ),
        );
      }
    } catch (_) {
      // Lỗi mạng — bỏ qua, thử lại lần sau
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showApprovedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final c = UniMoveColors.of(ctx);
        final theme = ShadTheme.of(ctx);
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.partyPopper, size: 36, color: c.success),
              ),
              const SizedBox(height: 20),
              Text(
                'Hồ sơ đã được duyệt!',
                textAlign: TextAlign.center,
                style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w800, color: c.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Chào mừng bạn tham gia UniMove Partner.\nBắt đầu nhận đơn ngay bây giờ!',
                textAlign: TextAlign.center,
                style: theme.textTheme.p.copyWith(color: c.onSurfaceMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              ShadButton(
                width: double.infinity,
                onPressed: () {
                  Navigator.pop(ctx);
                  authSessionNotifier.notifyAuthChanged();
                  context.go('/home');
                },
                child: const Text('Vào trang chủ'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadScreenScope(
      builder: (shadContext, theme) {
        final c = UniMoveColors.of(context);
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const DarkGlassBackground(variant: DarkGlassVariant.standard),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: c.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: c.primary.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Icon(LucideIcons.clipboardCheck, size: 40, color: c.primary),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutBack)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 28),

                      Text(
                        'Hồ sơ đang xét duyệt',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.h3.copyWith(
                          fontWeight: FontWeight.w800,
                          color: c.onSurface,
                        ),
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 12),

                      Text(
                        'Chúng tôi đang xem xét thông tin và giấy tờ của bạn.\nThông thường mất 1–2 ngày làm việc.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.p.copyWith(color: c.onSurfaceMuted, height: 1.55),
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 32),

                      // Status steps
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: c.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          children: [
                            _statusRow(c, theme, LucideIcons.userCheck, 'Tạo tài khoản', done: true),
                            _divider(c),
                            _statusRow(c, theme, LucideIcons.fileText, 'Nộp hồ sơ & giấy tờ', done: true),
                            _divider(c),
                            _statusRow(c, theme, LucideIcons.shieldCheck, 'Admin xét duyệt', done: false, pending: true),
                            _divider(c),
                            _statusRow(c, theme, LucideIcons.zap, 'Bắt đầu nhận đơn', done: false),
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 12),

                      // Auto-check hint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_checking)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                            )
                          else
                            Icon(LucideIcons.refreshCw, size: 14, color: c.onSurfaceMuted),
                          const SizedBox(width: 6),
                          Text(
                            _checking ? 'Đang kiểm tra...' : 'Tự động kiểm tra mỗi 30 giây',
                            style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 28),

                      // Manual check button
                      ShadButton(
                        width: double.infinity,
                        enabled: !_checking,
                        onPressed: () => _checkApproval(manual: true),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.searchCheck, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text('Kiểm tra ngay'),
                          ],
                        ),
                      ).animate().fadeIn(delay: 450.ms),
                      const SizedBox(height: 12),

                      // Logout
                      ShadButton.outline(
                        width: double.infinity,
                        onPressed: () async {
                          await ref.read(authRepositoryProvider).signOut();
                          if (!context.mounted) return;
                          context.go('/login');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.logOut, size: 16, color: c.onSurfaceMuted),
                            const SizedBox(width: 8),
                            Text('Đăng xuất', style: theme.textTheme.p.copyWith(color: c.onSurfaceMuted)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusRow(
    UniMoveColors c,
    ShadThemeData theme,
    IconData icon,
    String label, {
    required bool done,
    bool pending = false,
  }) {
    final color = done ? c.success : pending ? c.primary : c.onSurfaceMuted.withValues(alpha: 0.4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            done ? LucideIcons.circleCheck : (pending ? LucideIcons.clock : LucideIcons.circle),
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.p.copyWith(
                color: done ? c.onSurface : pending ? c.primary : c.onSurfaceMuted.withValues(alpha: 0.5),
                fontWeight: done || pending ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (pending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Đang xử lý',
                style: theme.textTheme.small.copyWith(color: c.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider(UniMoveColors c) =>
      Divider(color: c.border.withValues(alpha: 0.5), height: 1);
}
