import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/uni_surface_card.dart';
import '../../../chat/domain/active_chat_context.dart';
import '../../../orders/data/customer_orders_repository.dart';
import '../../../orders/domain/order_models.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final _repo = CustomerOrdersRepository();
  TrackingSnapshot? _tracking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await _repo.fetchTracking(widget.orderId);
    if (mounted) setState(() {
      _tracking = t;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.primary)),
      );
    }

    final t = _tracking!;
    final order = t.order;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.onSurface, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        title: Text('UniMove', style: TextStyle(color: c.primary, fontWeight: FontWeight.w800, fontSize: 20.sp)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: c.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusHero(snapshot: t, colors: c),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(color: c.navBarShadow, blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                children: [
                  Row(
                    children: [
                      Text(
                        _statusTitle(t.statusLabel),
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: c.onSurface),
                      ),
                      const Spacer(),
                      ShadBadge(
                        child: Text(t.statusLabel, style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Theo dõi qua trạng thái đơn — không cần bản đồ realtime',
                    style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted),
                  ),
                  SizedBox(height: 16.h),
                  _TrackingStepper(steps: t.steps, colors: c),
                  SizedBox(height: 20.h),
                  UniSurfaceCard(
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28.r,
                              backgroundImage: order.providerAvatarUrl != null
                                  ? NetworkImage(order.providerAvatarUrl!)
                                  : null,
                              child: order.providerAvatarUrl == null
                                  ? Icon(Icons.person, color: c.primary)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14.w,
                                height: 14.w,
                                decoration: BoxDecoration(
                                  color: c.accentGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: c.surface, width: 2),
                                ),
                                child: Icon(Icons.check, size: 8.sp, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order.providerName ?? 'Tài xế',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
                                  ),
                                  SizedBox(width: 6.w),
                                  Icon(Icons.star, color: Colors.amber, size: 16.sp),
                                  Text(
                                    '${order.providerRating ?? 4.9}',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp),
                                  ),
                                ],
                              ),
                              Text(
                                '${order.vehicleLabel} • BKS ${order.providerPlate ?? ''}',
                                style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          onTap: () {},
                          child: _actionBtn(Icons.call, 'Gọi điện', c.primary, AppColors.onPrimary),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: PressableScale(
                          onTap: () {
                            if (ActiveChatContext.orderAllowsChat(order) &&
                                order.conversationId != null) {
                              context.push('/chat/${order.conversationId}');
                            }
                          },
                          child: _actionBtn(
                            Icons.chat_bubble_outline,
                            'Nhắn tin',
                            c.primaryContainer,
                            c.primary,
                            outlined: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _statusTitle(String label) {
    if (label.contains('Chờ') || label.contains('Đã đặt')) return 'Theo dõi đơn hàng';
    if (label.contains('nhận') || label.contains('chốt')) return 'Đã chốt giá';
    return 'Tiến độ chuyển trọ';
  }

  Widget _actionBtn(IconData icon, String label, Color bg, Color fg, {bool outlined = false}) {
    return Container(
      height: 48.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(14.r),
        border: outlined ? Border.all(color: fg, width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fg, size: 20.sp),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14.sp)),
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.snapshot, required this.colors});

  final TrackingSnapshot snapshot;
  final UniMoveColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final order = snapshot.order;
    final isPending = snapshot.statusLabel.contains('Chờ') || order.status.dbValue == 'pending';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primaryContainer, c.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.local_shipping_outlined,
            size: 48.sp,
            color: c.primary,
          ).animate().fadeIn(duration: 300.ms),
          SizedBox(height: 12.h),
          Text(
            snapshot.statusLabel,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: c.onSurface),
          ),
          SizedBox(height: 6.h),
          Text(
            isPending
                ? 'Đội vận hành đang xem yêu cầu và báo giá'
                : '${order.providerName ?? 'Nhà xe'} · ${order.vehicleLabel}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: c.onSurfaceMuted),
          ),
          if (!isPending && snapshot.etaMinutes > 0) ...[
            SizedBox(height: 10.h),
            UniSurfaceCard(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, color: c.primary, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Dự kiến ~${snapshot.etaMinutes} phút',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingStepper extends StatelessWidget {
  const _TrackingStepper({required this.steps, required this.colors});

  final List<TrackingStep> steps;
  final UniMoveColors colors;

  @override
  Widget build(BuildContext context) {
    final last = steps.length - 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _stepCell(
              steps[i],
              isFirst: i == 0,
              isLast: i == last,
              nextReached: i < last && _reached(steps[i + 1]),
            ),
          ),
      ],
    );
  }

  bool _reached(TrackingStep step) => step.done || step.active;

  Widget _stepCell(
    TrackingStep step, {
    required bool isFirst,
    required bool isLast,
    required bool nextReached,
  }) {
    final active = step.active;
    final done = step.done;
    final reached = active || done;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hàng đường nối + chấm: line trái/phải nằm đúng giữa chấm.
        Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: !isFirst && reached ? colors.primary : Colors.transparent,
              ),
            ),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: reached ? colors.primary : colors.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done
                    ? Icons.check
                    : step.key == 'pending'
                        ? Icons.request_quote_outlined
                        : step.key == 'accepted'
                            ? Icons.handshake_outlined
                            : step.key == 'in_progress'
                                ? Icons.local_shipping_outlined
                                : Icons.inventory_2_outlined,
                color: reached ? AppColors.onPrimary : colors.onSurfaceMuted,
                size: 16.sp,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: !isLast && nextReached ? colors.primary : Colors.transparent,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Text(
            step.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: active ? colors.primary : colors.onSurfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}
