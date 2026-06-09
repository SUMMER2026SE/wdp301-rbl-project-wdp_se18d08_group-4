import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/mock/mock_provider_data.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../orders/domain/provider_order.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../../profile/data/provider_profile_repository.dart';

class ProviderDashboardPage extends ConsumerStatefulWidget {
  const ProviderDashboardPage({super.key});

  @override
  ConsumerState<ProviderDashboardPage> createState() =>
      _ProviderDashboardPageState();
}

class _ProviderDashboardPageState
    extends ConsumerState<ProviderDashboardPage> {
  bool _online = true;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(providerProfileProvider);
    final ordersAsync = ref.watch(providerOrdersListProvider);
    final c = UniMoveColors.of(context);

    return ShadScreenScope(
      builder: (_, theme) {
        return Scaffold(
          backgroundColor: c.background,
          body: Stack(
            children: [
              // Gradient bleed at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.primary.withValues(alpha: 0.08),
                        c.background,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: profileAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Lỗi: $e',
                        style: TextStyle(color: c.onSurface)),
                  ),
                  data: (profile) {
                    final orders =
                        ordersAsync.asData?.value ?? const <ProviderOrder>[];
                    final completed =
                        orders.where((o) => o.isCompleted).toList();
                    final active = orders.where((o) => o.isActive).toList();
                    final pending =
                        orders.where((o) => o.isPending).toList();
                    final earnings = completed.fold<int>(
                        0, (s, o) => s + o.netEarnings);
                    final total = completed.length +
                        active.length +
                        pending.length +
                        orders
                            .where((o) =>
                                !o.isCompleted &&
                                !o.isActive &&
                                !o.isPending)
                            .length;
                    final acceptRate = total == 0
                        ? 100
                        : ((completed.length + active.length) /
                                total *
                                100)
                            .round();

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(providerProfileProvider);
                        ref.invalidate(providerOrdersListProvider);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          _header(theme, c, profile?.fullName ?? 'Đối tác',
                                  profile?.businessName)
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: -0.1, curve: Curves.easeOut),
                          const SizedBox(height: 16),
                          _onlineCard(theme, c)
                              .animate()
                              .fadeIn(delay: 80.ms, duration: 280.ms)
                              .slideY(begin: 0.08, curve: Curves.easeOut),
                          const SizedBox(height: 16),
                          _earningsHero(theme, c, earnings, completed.length)
                              .animate()
                              .fadeIn(delay: 140.ms, duration: 300.ms)
                              .slideY(begin: 0.1, curve: Curves.easeOut),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  theme,
                                  c,
                                  LucideIcons.circleCheck,
                                  '${completed.length}',
                                  'Hoàn thành',
                                  c.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _statCard(
                                  theme,
                                  c,
                                  LucideIcons.star,
                                  '${profile?.rating ?? 0}',
                                  'Đánh giá',
                                  c.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _statCard(
                                  theme,
                                  c,
                                  LucideIcons.percent,
                                  '$acceptRate%',
                                  'Tỉ lệ nhận',
                                  c.accentGreen,
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 300.ms)
                              .slideY(begin: 0.1, curve: Curves.easeOut),
                          if (active.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _sectionTitle(theme, c, 'Đơn đang thực hiện'),
                            const SizedBox(height: 10),
                            _activeOrderCard(theme, c, active.first)
                                .animate()
                                .fadeIn(delay: 260.ms, duration: 300.ms),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child:
                                    _sectionTitle(theme, c, 'Đơn mới'),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/orders'),
                                child: Text(
                                  '${pending.length} chờ nhận',
                                  style: theme.textTheme.small.copyWith(
                                    color: c.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (pending.isEmpty)
                            _emptyRequests(theme, c)
                                .animate()
                                .fadeIn(delay: 300.ms)
                          else
                            ...pending.asMap().entries.map(
                                  (e) => _requestCard(theme, c, e.value)
                                      .animate()
                                      .fadeIn(
                                        delay:
                                            (300 + e.key * 60).ms,
                                        duration: 280.ms,
                                      )
                                      .slideX(
                                        begin: 0.04,
                                        curve: Curves.easeOut,
                                      ),
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Header ----------
  Widget _header(
      ShadThemeData theme, UniMoveColors c, String name, String? business) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.primary, c.primaryLight]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: theme.textTheme.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: theme.textTheme.small
                    .copyWith(color: c.onSurfaceMuted),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.large.copyWith(
                  fontWeight: FontWeight.w800,
                  color: c.onSurface,
                ),
              ),
            ],
          ),
        ),
        _iconButton(c, LucideIcons.calendarClock,
            () => context.push('/schedule')),
        const SizedBox(width: 10),
        _iconButton(c, LucideIcons.bell, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chưa có thông báo mới')),
          );
        }),
      ],
    );
  }

  Widget _iconButton(UniMoveColors c, IconData icon, VoidCallback onTap) {
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: c.onSurface, size: 20),
        ),
      ),
    );
  }

  // ---------- Online toggle ----------
  Widget _onlineCard(ShadThemeData theme, UniMoveColors c) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 18,
      child: Row(
        children: [
          // Pulsing status dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, value, child) => Transform.scale(
              scale: _online ? value : 1.0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _online ? c.success : c.onSurfaceMuted,
                  shape: BoxShape.circle,
                  boxShadow: _online
                      ? [
                          BoxShadow(
                            color: c.success.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _online ? 'Đang nhận đơn' : 'Đang nghỉ',
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                ),
                Text(
                  _online
                      ? 'Khách có thể thấy và đặt bạn'
                      : 'Bạn sẽ không nhận đơn mới',
                  style: theme.textTheme.small
                      .copyWith(color: c.onSurfaceMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _online,
            activeThumbColor: c.primary,
            onChanged: (v) {
              setState(() => _online = v);
              ref
                  .read(providerProfileRepositoryProvider)
                  .setOnlineStatus(isOnline: v)
                  .ignore();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(v ? 'Đã bật nhận đơn' : 'Đã tạm nghỉ'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- Earnings hero ----------
  Widget _earningsHero(
      ShadThemeData theme, UniMoveColors c, int earnings, int trips) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/earnings/history'),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.primary, c.primaryLight],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.38),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.wallet,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'TỔNG THU NHẬP',
                      style: theme.textTheme.small.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem tất cả',
                            style: theme.textTheme.small.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _money(earnings),
                  style: theme.textTheme.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$trips chuyến',
                        style: theme.textTheme.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chạm để xem lịch sử',
                      style: theme.textTheme.small
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(ShadThemeData theme, UniMoveColors c, IconData icon,
      String value, String label, Color tint) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.h3.copyWith(
              fontWeight: FontWeight.w800,
              color: c.onSurface,
            ),
          ),
          Text(
            label,
            style:
                theme.textTheme.small.copyWith(color: c.onSurfaceMuted),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
      ShadThemeData theme, UniMoveColors c, String text) {
    return Text(
      text,
      style: theme.textTheme.large.copyWith(
        fontWeight: FontWeight.w800,
        color: c.onSurface,
      ),
    );
  }

  // ---------- Active order ----------
  Widget _activeOrderCard(
      ShadThemeData theme, UniMoveColors c, ProviderOrder o) {
    final customer = MockProviderData.customerNameOf(o.customerId);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/orders/${o.id}'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.primaryLight, c.primary],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.truck,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '#${o.orderNumber ?? o.id} · $customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.p.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      o.statusLabel,
                      style: theme.textTheme.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _routeLine(theme, LucideIcons.circleDot, 'Điểm lấy',
                  o.pickupAddress),
              const SizedBox(height: 8),
              _routeLine(theme, LucideIcons.mapPin, 'Điểm giao',
                  o.deliveryAddress),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: c.primary,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.push('/orders/${o.id}'),
                  child: const Text(
                    'Xem chi tiết đơn',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeLine(ShadThemeData theme, IconData icon, String label,
      String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.small
                    .copyWith(color: Colors.white60),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.small.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Request card ----------
  Widget _requestCard(
      ShadThemeData theme, UniMoveColors c, ProviderOrder o) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/request/${o.id}'),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.chipBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Gói ${o.serviceLabel}',
                        style: theme.textTheme.small.copyWith(
                          color: c.primaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _money(o.totalPrice),
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w800,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _reqRow(theme, c, LucideIcons.circleDot,
                    o.pickupAddress, c.primary),
                const SizedBox(height: 6),
                _reqRow(theme, c, LucideIcons.mapPin,
                    o.deliveryAddress, c.success),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(LucideIcons.clock,
                        size: 12, color: c.onSurfaceMuted),
                    const SizedBox(width: 4),
                    Text(
                      ProviderOrder.timeAgo(o.createdAt),
                      style: theme.textTheme.small
                          .copyWith(color: c.onSurfaceMuted, fontSize: 11),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Xem yêu cầu →',
                        style: theme.textTheme.small.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reqRow(ShadThemeData theme, UniMoveColors c, IconData icon,
      String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                theme.textTheme.small.copyWith(color: c.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _emptyRequests(ShadThemeData theme, UniMoveColors c) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.iconBgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.inbox,
                color: c.onSurfaceMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chưa có đơn mới. Bật "Đang nhận đơn" để nhận yêu cầu.',
              style: theme.textTheme.small
                  .copyWith(color: c.onSurfaceMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  static String _money(int amount) {
    if (amount <= 0) return '0đ';
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    buf.write('đ');
    return buf.toString();
  }
}
