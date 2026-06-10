import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../../orders/domain/provider_order.dart';
import '../../../orders/presentation/providers/orders_providers.dart';

enum _Period { today, week, month, all }

extension _PeriodLabel on _Period {
  String get label {
    return switch (this) {
      _Period.today => 'Hôm nay',
      _Period.week => 'Tuần này',
      _Period.month => 'Tháng này',
      _Period.all => 'Tất cả',
    };
  }
}

class EarningsTabPage extends ConsumerStatefulWidget {
  const EarningsTabPage({super.key});

  @override
  ConsumerState<EarningsTabPage> createState() => _EarningsTabPageState();
}

class _EarningsTabPageState extends ConsumerState<EarningsTabPage> {
  _Period _period = _Period.all;
  static const _platformRate = 0.15;

  List<ProviderOrder> _filter(List<ProviderOrder> orders) {
    final completed = orders.where((o) => o.isCompleted).toList();
    if (_period == _Period.all) return completed;
    final now = DateTime.now();
    return completed.where((o) {
      final d = o.createdAt;
      if (d == null) return false;
      return switch (_period) {
        _Period.today =>
          d.year == now.year && d.month == now.month && d.day == now.day,
        _Period.week => now.difference(d).inDays < 7,
        _Period.month => d.year == now.year && d.month == now.month,
        _Period.all => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final ordersAsync = ref.watch(providerOrdersListProvider);

    return ShadScreenScope(
      builder: (_, theme) {
        return SafeArea(
          child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Lỗi: $e', style: TextStyle(color: c.onSurface))),
            data: (allOrders) {
              final filtered = _filter(allOrders);
              final active = allOrders.where((o) => o.isActive || o.isPending).toList();
              final gross = filtered.fold<int>(0, (s, o) => s + o.totalPrice);
              final fee = (gross * _platformRate).round();
              final net = gross - fee;

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(providerOrdersListProvider),
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thu nhập',
                                style: theme.textTheme.h3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: c.onSurface,
                                ),
                              ),
                              Text(
                                '${filtered.length} đơn đã hoàn thành',
                                style: theme.textTheme.small
                                    .copyWith(color: c.onSurfaceMuted),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/earnings/history'),
                          icon: Icon(LucideIcons.history,
                              size: 14, color: c.primaryLight),
                          label: Text(
                            'Lịch sử',
                            style:
                                TextStyle(color: c.primaryLight, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Period selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _Period.values.map((p) {
                          final active = p == _period;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _period = p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: active ? c.primary : c.surfaceHigh,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: active ? c.primary : c.border,
                                  ),
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: c.primary.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  p.label,
                                  style: theme.textTheme.small.copyWith(
                                    color: active ? Colors.white : c.onSurfaceMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hero earnings card
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [c.primary, c.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.wallet,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'THỰC NHẬN (SAU PHÍ ${(_platformRate * 100).toInt()}%)',
                                style: theme.textTheme.small.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _money(net),
                            style: theme.textTheme.h1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _heroStat(theme, 'Tổng doanh thu',
                                    _money(gross)),
                                _divider(),
                                _heroStat(
                                    theme, 'Phí nền tảng', '- ${_money(fee)}'),
                                _divider(),
                                _heroStat(
                                    theme, 'Số đơn', '${filtered.length}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick stats
                    Row(
                      children: [
                        Expanded(
                          child: _miniStat(
                            theme,
                            c,
                            LucideIcons.circleCheck,
                            '${filtered.length}',
                            'Hoàn thành',
                            c.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _miniStat(
                            theme,
                            c,
                            LucideIcons.truck,
                            '${active.length}',
                            'Đang/chờ',
                            c.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _miniStat(
                            theme,
                            c,
                            LucideIcons.trendingUp,
                            gross > 0
                                ? _money((gross / (filtered.isEmpty ? 1 : filtered.length)).round())
                                : '0đ',
                            'TB/chuyến',
                            c.accentGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Recent orders
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Đơn gần đây',
                            style: theme.textTheme.large.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.onSurface,
                            ),
                          ),
                        ),
                        if (filtered.isNotEmpty)
                          Text(
                            '${filtered.length} đơn',
                            style: theme.textTheme.small
                                .copyWith(color: c.onSurfaceMuted),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        radius: 16,
                        child: Row(
                          children: [
                            Icon(LucideIcons.inbox,
                                color: c.onSurfaceMuted, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Không có đơn trong khoảng thời gian này.',
                              style: theme.textTheme.small
                                  .copyWith(color: c.onSurfaceMuted),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filtered.map((o) => _payoutTile(context, theme, c, o)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _heroStat(ShadThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _payoutTile(
      BuildContext context, ShadThemeData theme, UniMoveColors c, ProviderOrder o) {
    final net = (o.totalPrice * (1 - _platformRate)).round();
    final d = o.createdAt;
    final dateStr = d == null ? '' : '${d.day}/${d.month}/${d.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/orders/${o.id}'),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            radius: 16,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.iconBgTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.circleCheck,
                      color: c.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${o.orderNumber ?? o.id}',
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w700,
                          color: c.onSurface,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: theme.textTheme.small
                            .copyWith(color: c.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+ ${_money(net)}',
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w800,
                        color: c.success,
                      ),
                    ),
                    Text(
                      _money(o.totalPrice),
                      style: theme.textTheme.small.copyWith(
                        color: c.onSurfaceMuted,
                        decoration: TextDecoration.lineThrough,
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

  Widget _miniStat(ShadThemeData theme, UniMoveColors c, IconData icon,
      String value, String label, Color tint) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.h4.copyWith(
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

  static String _money(int amount) {
    if (amount == 0) return '0đ';
    final neg = amount < 0;
    final s = amount.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${neg ? '-' : ''}$bufđ';
  }
}
