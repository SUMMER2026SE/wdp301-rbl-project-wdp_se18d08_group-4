import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/mock/mock_order_tracking.dart';
import '../../../../core/mock/mock_provider_data.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../../orders/domain/provider_order.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../domain/provider_tracking_models.dart';
import '../widgets/tracking_map_preview.dart';

class ProviderOrderTrackingPage extends ConsumerStatefulWidget {
  const ProviderOrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ProviderOrderTrackingPage> createState() => _ProviderOrderTrackingPageState();
}

class _ProviderOrderTrackingPageState extends ConsumerState<ProviderOrderTrackingPage> {
  ProviderOrder? _order;
  double _routeProgress = 0.35;
  Timer? _simTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final order = await ref.read(providerOrdersRepositoryProvider).fetchById(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _routeProgress = MockOrderTracking.snapshotFor(order).routeProgress;
      _loading = false;
    });
    _startSimulationIfNeeded(order);
  }

  void _startSimulationIfNeeded(ProviderOrder order) {
    _simTimer?.cancel();
    if (!order.canSendChat) return;

    _simTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final o = _order;
      if (!mounted || o == null) return;
      setState(() {
        final cap = switch (o.status) {
          'accepted' => 0.35,
          'picking_up' => 0.55,
          'in_progress' => 0.92,
          _ => 0.5,
        };
        _routeProgress = (_routeProgress + 0.03).clamp(0.05, cap);
      });
    });
  }

  Future<void> _advanceStatus() async {
    final order = _order;
    if (order == null) return;
    final tracking = MockOrderTracking.snapshotFor(order);
    final next = tracking.nextStatus;
    if (next == null) return;

    MockProviderData.updateStatus(order.id, next);
    ref.invalidate(providerOrdersListProvider);
    ref.invalidate(providerOrderDetailProvider(widget.orderId));

    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật: ${_order!.statusLabel} (demo)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order!;
    if (!order.isActive) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          title: const Text('Theo dõi hành trình'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Chỉ bật theo dõi GPS khi đơn đã nhận và đang thực hiện.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurface),
            ),
          ),
        ),
      );
    }

    final tracking = MockOrderTracking.snapshotFor(order, routeProgressOverride: _routeProgress);
    final customer = MockProviderData.customerNameOf(order.customerId);

    return ShadScreenScope(
      builder: (_, theme) {
        return Scaffold(
          backgroundColor: c.background,
          body: Column(
            children: [
              Expanded(
                flex: 42,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TrackingMapPreview(
                      routeProgress: _routeProgress,
                      etaMinutes: _etaFromProgress(_routeProgress, tracking.etaMinutes),
                      distanceKm: (tracking.distanceKm * (1 - _routeProgress * 0.6)).clamp(0.3, 12),
                      phaseTitle: tracking.phaseTitle,
                      isSharing: tracking.isSharingLocation,
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.35),
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 58,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: c.navBarShadow.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tracking.statusHeadline,
                              style: theme.textTheme.h4.copyWith(
                                fontWeight: FontWeight.w800,
                                color: c.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: c.chipBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: theme.textTheme.small.copyWith(
                                fontWeight: FontWeight.w700,
                                color: c.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${order.orderNumber ?? order.id.substring(0, 8)} · $customer',
                        style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted),
                      ),
                      const SizedBox(height: 16),
                      if (tracking.isSharingLocation)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.iconBgTertiary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.success.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.eye, size: 18, color: c.success),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Khách hàng đang xem vị trí của bạn trên app (giao diện demo — chưa kết nối GPS thật).',
                                  style: theme.textTheme.small.copyWith(
                                    color: c.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      _TrackingStepper(steps: tracking.steps, c: c),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          children: [
                            _routeRow(c, theme, LucideIcons.circleDot, 'Điểm lấy', order.pickupAddress, true),
                            Divider(height: 20, color: c.border),
                            _routeRow(c, theme, LucideIcons.mapPin, 'Điểm giao', order.deliveryAddress, false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (tracking.nextActionLabel != null) ...[
                        ShadButton(
                          width: double.infinity,
                          onPressed: _advanceStatus,
                          leading: const Icon(LucideIcons.circleCheck, size: 18),
                          child: Text(tracking.nextActionLabel!),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ShadButton.outline(
                        width: double.infinity,
                        onPressed: () {
                          final threadId = MockProviderData.chatThreadIdForOrder(order.id);
                          if (threadId != null) context.push('/chat/$threadId');
                        },
                        leading: Icon(LucideIcons.messageCircle, size: 18, color: c.primary),
                        child: const Text('Nhắn tin khách'),
                      ),
                      const SizedBox(height: 8),
                      ShadButton.ghost(
                        width: double.infinity,
                        onPressed: () => context.push('/orders/${order.id}'),
                        child: const Text('Chi tiết đơn đầy đủ'),
                      ),
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

  int _etaFromProgress(double progress, int baseEta) {
    return ((1 - progress) * baseEta + 3).round().clamp(2, 45);
  }

  Widget _routeRow(
    UniMoveColors c,
    ShadThemeData theme,
    IconData icon,
    String label,
    String address,
    bool isPickup,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isPickup ? c.success : c.primaryLight),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
              Text(
                address,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.onSurface,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingStepper extends StatelessWidget {
  const _TrackingStepper({required this.steps, required this.c});

  final List<TrackingStepItem> steps;
  final UniMoveColors c;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: steps[i].done
                          ? c.success
                          : steps[i].active
                              ? c.primary
                              : c.chipBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: steps[i].active ? c.primary : c.border,
                      ),
                    ),
                    child: Icon(
                      steps[i].done ? LucideIcons.check : LucideIcons.circle,
                      size: 14,
                      color: steps[i].done || steps[i].active ? Colors.white : c.onSurfaceMuted,
                    ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: steps[i].done ? c.success.withValues(alpha: 0.5) : c.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    steps[i].label,
                    style: TextStyle(
                      fontWeight: steps[i].active ? FontWeight.w800 : FontWeight.w500,
                      color: steps[i].active ? c.onSurface : c.onSurfaceMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
