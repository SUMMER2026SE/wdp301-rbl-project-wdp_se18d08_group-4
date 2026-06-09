import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/mock/mock_provider_data.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../domain/provider_order.dart';
import '../providers/orders_providers.dart';

class OrdersInboxPage extends ConsumerWidget {
  const OrdersInboxPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(providerOrdersListProvider);
    final c = UniMoveColors.of(context);

    return ShadScreenScope(
      builder: (_, theme) {
        return ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(providerOrdersListProvider),
          ),
          data: (orders) {
            final pending = orders.where((o) => o.isPending).toList();
            final active = orders.where((o) => o.isActive).toList();
            final done = orders
                .where((o) => !o.isPending && !o.isActive)
                .toList();

            return DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Đơn hàng',
                              style: theme.textTheme.h3.copyWith(
                                fontWeight: FontWeight.w800,
                                color: c.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.refreshCw,
                                color: c.onSurfaceMuted, size: 20),
                            onPressed: () =>
                                ref.invalidate(providerOrdersListProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: c.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border),
                      ),
                      child: TabBar(
                        padding: const EdgeInsets.all(3),
                        indicator: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: c.primary.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: c.onSurfaceMuted,
                        labelStyle: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        tabs: [
                          _TabItem(label: 'Chờ xử lý', count: pending.length, hasAlert: pending.isNotEmpty),
                          _TabItem(label: 'Đang thực hiện', count: active.length),
                          _TabItem(label: 'Lịch sử', count: done.length),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OrderList(
                          orders: pending,
                          emptyText: 'Không có đơn chờ xử lý',
                          emptyIcon: LucideIcons.inbox,
                        ),
                        _OrderList(
                          orders: active,
                          emptyText: 'Không có đơn đang thực hiện',
                          emptyIcon: LucideIcons.truck,
                        ),
                        _OrderList(
                          orders: done,
                          emptyText: 'Chưa có lịch sử',
                          emptyIcon: LucideIcons.history,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, this.count = 0, this.hasAlert = false});

  final String label;
  final int count;
  final bool hasAlert;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyText,
    required this.emptyIcon,
  });

  final List<ProviderOrder> orders;
  final String emptyText;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _EmptyTab(text: emptyText, icon: emptyIcon);
    }

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, i) => _OrderTile(order: orders[i]),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final theme = ShadTheme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.iconBgSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: c.onSurfaceMuted),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: theme.textTheme.p.copyWith(
              color: c.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOut);
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final ProviderOrder order;

  Color _statusColor(UniMoveColors c) {
    if (order.isPending) return const Color(0xFFF59E0B);
    if (order.isActive) return c.primary;
    if (order.isCompleted) return c.success;
    return c.onSurfaceMuted;
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final theme = ShadTheme.of(context);
    final customer = MockProviderData.customerNameOf(order.customerId);
    final statusColor = _statusColor(c);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/orders/${order.id}'),
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            padding: EdgeInsets.zero,
            radius: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  // Status accent bar
                  Container(
                    width: 4,
                    height: 90,
                    color: statusColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color:
                                      statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  order.isPending
                                      ? LucideIcons.bell
                                      : order.isActive
                                          ? LucideIcons.truck
                                          : order.isCompleted
                                              ? LucideIcons.circleCheck
                                              : LucideIcons.xCircle,
                                  color: statusColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${order.orderNumber ?? order.id}  ·  $customer',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.p.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: c.onSurface,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          margin:
                                              const EdgeInsets.only(top: 3),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            order.statusLabel,
                                            style: theme.textTheme.small
                                                .copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatPrice(order.totalPrice),
                                style: theme.textTheme.p.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: c.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _addrLine(theme, c, LucideIcons.circleDot,
                              order.pickupAddress, c.primary),
                          const SizedBox(height: 3),
                          _addrLine(theme, c, LucideIcons.mapPin,
                              order.deliveryAddress, c.success),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideX(begin: 0.04, curve: Curves.easeOut);
  }

  Widget _addrLine(ShadThemeData theme, UniMoveColors c, IconData icon,
      String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted),
          ),
        ),
      ],
    );
  }

  String _formatPrice(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ShadButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
