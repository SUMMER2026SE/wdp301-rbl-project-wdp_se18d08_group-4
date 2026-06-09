import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/mock/mock_provider_data.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../domain/provider_order.dart';
import '../providers/orders_providers.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  final _declineReasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _declineReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _respond(String response) async {
    setState(() => _submitting = true);
    try {
      await ref.read(providerOrdersRepositoryProvider).respond(
            orderId: widget.orderId,
            response: response,
            declineReason: response == 'declined' ? _declineReasonCtrl.text : null,
          );
      ref.invalidate(providerOrdersListProvider);
      ref.invalidate(providerOrderDetailProvider(widget.orderId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response == 'accepted' ? 'Đã nhận đơn' : 'Đã từ chối đơn')),
      );
      if (response == 'accepted') context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(providerOrderDetailProvider(widget.orderId));
    final c = UniMoveColors.of(context);

    return ShadScreenScope(
      builder: (_, theme) {
        return Scaffold(
          backgroundColor: c.background,
          body: orderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e', style: TextStyle(color: c.onSurface))),
            data: (order) {
              final customer = MockProviderData.customerNameOf(order.customerId);
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 210,
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    iconTheme: const IconThemeData(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.primary, c.primaryLight],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order.statusLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (order.createdAt != null)
                                  Text(
                                    ProviderOrder.timeAgo(order.createdAt),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '#${order.orderNumber ?? order.id.substring(0, 8)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ProviderOrder.formatDateTime(order.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _quickStats(c, order),
                        const SizedBox(height: 16),
                        _sectionTitle(c, 'Hành trình'),
                        const SizedBox(height: 10),
                        _routeCard(c, order),
                        const SizedBox(height: 20),
                        _sectionTitle(c, 'Khách hàng'),
                        const SizedBox(height: 10),
                        _customerCard(c, theme, customer, order),
                        const SizedBox(height: 20),
                        _sectionTitle(c, 'Dịch vụ & phương tiện'),
                        const SizedBox(height: 10),
                        _serviceCard(c, theme, order),
                        if (order.items.isNotEmpty || (order.itemsDescription?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: 20),
                          _sectionTitle(c, 'Hàng hóa'),
                          const SizedBox(height: 10),
                          _itemsCard(c, theme, order),
                        ],
                        const SizedBox(height: 20),
                        _sectionTitle(c, 'Chi phí'),
                        const SizedBox(height: 10),
                        _pricingCard(c, theme, order),
                        if (order.scheduledPickupTime != null ||
                            order.actualPickupTime != null ||
                            order.completedAt != null) ...[
                          const SizedBox(height: 20),
                          _sectionTitle(c, 'Thời gian'),
                          const SizedBox(height: 10),
                          _timingCard(c, theme, order),
                        ],
                        if (order.isActive) ...[
                          const SizedBox(height: 20),
                          ShadButton(
                            width: double.infinity,
                            onPressed: () {
                              final thread = MockProviderData.chatThreadByCustomer(order.customerId);
                              if (thread != null) {
                                context.push('/chat/${thread.id}');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Chưa có hội thoại với $customer')),
                                );
                              }
                            },
                            leading: const Icon(LucideIcons.messageCircle, size: 18),
                            child: const Text('Nhắn tin cho khách'),
                          ),
                        ],
                        if (order.isPending) ...[
                          const SizedBox(height: 24),
                          ShadButton(
                            width: double.infinity,
                            onPressed: _submitting ? null : () => _respond('accepted'),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Nhận đơn'),
                          ),
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Lý do từ chối (tuỳ chọn)',
                                  style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                ShadInput(
                                  controller: _declineReasonCtrl,
                                  placeholder: const Text('Ví dụ: không còn slot trong khung giờ...'),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 12),
                                ShadButton.outline(
                                  width: double.infinity,
                                  onPressed: _submitting ? null : () => _respond('declined'),
                                  child: const Text('Từ chối đơn'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionTitle(UniMoveColors c, String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.onSurface),
    );
  }

  Widget _quickStats(UniMoveColors c, ProviderOrder order) {
    return Row(
      children: [
        Expanded(child: _statTile(c, Icons.route_outlined, 'Quãng đường', '${order.distanceKm?.toStringAsFixed(1) ?? '—'} km')),
        const SizedBox(width: 10),
        Expanded(child: _statTile(c, Icons.schedule_outlined, 'ETA', order.etaMinutes != null ? '${order.etaMinutes} phút' : '—')),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            c,
            Icons.payments_outlined,
            'Tổng thu',
            ProviderOrder.formatMoney(order.totalPrice),
            highlight: true,
          ),
        ),
      ],
    );
  }

  Widget _statTile(
    UniMoveColors c,
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? c.primary.withValues(alpha: 0.1) : c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? c.primary.withValues(alpha: 0.35) : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: highlight ? c.primary : c.onSurfaceMuted),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, color: c.onSurfaceMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: highlight ? c.primary : c.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(UniMoveColors c, ProviderOrder order) {
    final pickup = order.pickupPoint;
    final delivery = order.deliveryPoint;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _routeStop(
            c,
            color: c.primary,
            icon: Icons.trip_origin,
            title: 'Điểm lấy',
            address: pickup.address,
            meta: _locationMeta(pickup),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              children: [
                Container(width: 2, height: 28, color: c.border),
                const SizedBox(width: 12),
                if (order.distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.chipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${order.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.primary),
                    ),
                  ),
              ],
            ),
          ),
          _routeStop(
            c,
            color: c.success,
            icon: Icons.location_on,
            title: 'Điểm giao',
            address: delivery.address,
            meta: _locationMeta(delivery),
          ),
        ],
      ),
    );
  }

  String _locationMeta(OrderLocationPoint p) {
    final parts = <String>[
      if (p.districtLine.isNotEmpty) p.districtLine,
      'Tầng ${p.floor}',
      p.hasElevator ? 'Có thang máy' : 'Không thang máy',
    ];
    return parts.join(' · ');
  }

  Widget _routeStop(
    UniMoveColors c, {
    required Color color,
    required IconData icon,
    required String title,
    required String address,
    required String meta,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.onSurfaceMuted)),
              const SizedBox(height: 4),
              Text(address, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.onSurface, height: 1.35)),
              const SizedBox(height: 4),
              Text(meta, style: TextStyle(fontSize: 12, color: c.onSurfaceMuted, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _customerCard(UniMoveColors c, ShadThemeData theme, String name, ProviderOrder order) {
    final phone = order.pickupPoint.contactPhone;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: c.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'K',
              style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w700, color: c.onSurface)),
                const SizedBox(height: 4),
                Text(
                  phone.isNotEmpty ? phone : 'Chưa có SĐT',
                  style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted),
                ),
                if (order.pickupPoint.notes != null && order.pickupPoint.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    order.pickupPoint.notes!,
                    style: theme.textTheme.small.copyWith(color: c.onSurface, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép số điện thoại')));
              },
              icon: Icon(Icons.phone_in_talk_outlined, color: c.primary),
              tooltip: 'Sao chép SĐT',
            ),
        ],
      ),
    );
  }

  Widget _serviceCard(UniMoveColors c, ShadThemeData theme, ProviderOrder order) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoRow(c, theme, LucideIcons.sparkles, 'Gói dịch vụ', order.serviceLabel),
          const SizedBox(height: 12),
          _infoRow(c, theme, LucideIcons.truck, 'Phương tiện', order.vehicleLabel),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (order.hasInsurance) _badge(c, 'Có bảo hiểm', c.success),
              if (order.hasPackingService) _badge(c, 'Đóng gói', c.primary),
              if (order.requiresHelpers) _badge(c, '${order.numberOfHelpers} người bốc xếp', c.primaryLight),
              if (order.hasFragileItems) _badge(c, 'Đồ dễ vỡ', Colors.orange),
              if (order.estimatedWeightKg != null)
                _badge(c, '~${order.estimatedWeightKg!.round()} kg', c.onSurfaceMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemsCard(UniMoveColors c, ShadThemeData theme, ProviderOrder order) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.itemsDescription != null && order.itemsDescription!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                order.itemsDescription!,
                style: theme.textTheme.p.copyWith(color: c.onSurface, height: 1.4),
              ),
            ),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.surfaceTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.package, size: 18, color: c.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.onSurface)),
                        Text(
                          [
                            'SL: ${item.qty}',
                            if (item.weightKg != null) '${item.weightKg!.round()} kg',
                            if (item.fragile) 'Dễ vỡ',
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: c.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricingCard(UniMoveColors c, ShadThemeData theme, ProviderOrder order) {
    final p = order.priceBreakdown;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _priceRow(c, theme, 'Giá cơ bản', p.basePrice),
          _priceRow(c, theme, 'Theo km', p.distancePrice),
          _priceRow(c, theme, 'Phí tầng / bốc xếp', p.floorPrice),
          if (p.serviceFee > 0) _priceRow(c, theme, 'Phí dịch vụ', p.serviceFee),
          if (p.discountAmount > 0)
            _priceRow(c, theme, 'Giảm giá', -p.discountAmount, valueColor: c.success),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Text('Tổng cộng', style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w800, color: c.onSurface)),
              const Spacer(),
              Text(
                ProviderOrder.formatMoney(p.totalPrice),
                style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w800, color: c.primaryLight),
              ),
            ],
          ),
          if (order.hasInsurance && order.insuranceValue != null) ...[
            const SizedBox(height: 10),
            Text(
              'Giá trị bảo hiểm: ${ProviderOrder.formatMoney(order.insuranceValue!)}',
              style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timingCard(UniMoveColors c, ShadThemeData theme, ProviderOrder order) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (order.scheduledPickupTime != null)
            _infoRow(c, theme, LucideIcons.calendar, 'Hẹn lấy hàng', ProviderOrder.formatDateTime(order.scheduledPickupTime)),
          if (order.actualPickupTime != null) ...[
            const SizedBox(height: 10),
            _infoRow(c, theme, LucideIcons.packageCheck, 'Đã lấy hàng', ProviderOrder.formatDateTime(order.actualPickupTime)),
          ],
          if (order.actualDeliveryTime != null) ...[
            const SizedBox(height: 10),
            _infoRow(c, theme, LucideIcons.mapPinCheck, 'Đã giao', ProviderOrder.formatDateTime(order.actualDeliveryTime)),
          ],
          if (order.completedAt != null) ...[
            const SizedBox(height: 10),
            _infoRow(c, theme, LucideIcons.badgeCheck, 'Hoàn tất', ProviderOrder.formatDateTime(order.completedAt)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(UniMoveColors c, ShadThemeData theme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: c.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.p.copyWith(color: c.onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(
    UniMoveColors c,
    ShadThemeData theme,
    String label,
    int amount, {
    Color? valueColor,
  }) {
    if (amount == 0 && label != 'Giá cơ bản') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
          const Spacer(),
          Text(
            amount < 0 ? '-${ProviderOrder.formatMoney(-amount)}' : ProviderOrder.formatMoney(amount),
            style: theme.textTheme.small.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? c.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(UniMoveColors c, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
