import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../booking/data/quote_progress_repository.dart';
import '../../../booking/domain/quote_models.dart';
import '../../../booking/presentation/cubit/booking_flow_cubit.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/order_status_chip.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/uni_surface_card.dart';
import '../../data/customer_orders_repository.dart';
import '../../domain/order_models.dart';

/// Tab Hoạt động — đơn gần đây + đánh giá (Grab-style, khớp `orders`).
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final _repo = CustomerOrdersRepository();
  final _quoteRepo = QuoteProgressRepository.instance;
  List<CustomerOrder> _orders = [];
  List<QuoteRequestSnapshot> _quoteTrips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.fetchOrders();
    final trips = _quoteRepo.listBookedTrips();
    if (mounted) {
      setState(() {
        _orders = list;
        _quoteTrips = trips;
        _loading = false;
      });
    }
  }

  QuoteRequestSnapshot? get _upcomingQuoteTrip {
    final active = _quoteTrips.where(
      (t) =>
          t.status == QuoteProgressStatus.depositPaid ||
          t.status == QuoteProgressStatus.providerAccepted ||
          t.status == QuoteProgressStatus.scheduled ||
          t.status == QuoteProgressStatus.inProgress,
    );
    if (active.isEmpty) return null;
    return active.first;
  }

  CustomerOrder? get _activeOrder {
    try {
      return _orders.firstWhere((o) => o.status.isActive && o.providerId != null);
    } catch (_) {
      return null;
    }
  }

  CustomerOrder? get _reviewOrder {
    try {
      return _orders.firstWhere((o) => o.status == OrderStatus.completed && !o.hasReview);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }

    return SafeArea(
      child: RefreshIndicator(
        color: c.primary,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hoạt động',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: c.onSurface,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                PressableScale(
                  onTap: () => context.push('/orders/history'),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: c.surfaceTint,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: c.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16.sp, color: c.onSurface),
                        SizedBox(width: 6.w),
                        Text(
                          'Lịch sử hoạt động',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: c.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            if (_upcomingQuoteTrip != null) ...[
              _QuoteTripCard(
                snap: _upcomingQuoteTrip!,
                onOpen: () => context.push('/booking/quotes/${_upcomingQuoteTrip!.id}/progress'),
              ),
              SizedBox(height: 16.h),
            ],
            if (_activeOrder != null) ...[
              _ActiveOrderCard(
                order: _activeOrder!,
                onTrack: () => context.push('/orders/${_activeOrder!.id}/tracking'),
                onAddLabor: () {
                  context.read<BookingFlowCubit>().startLaborAddonFromOrder(_activeOrder!);
                  context.push('/booking/labor/configure');
                },
              ),
              SizedBox(height: 16.h),
            ],
            if (_reviewOrder != null) ...[
              _ReviewPromptCard(
                order: _reviewOrder!,
                onReview: () => context.push('/orders/${_reviewOrder!.id}/review'),
              ),
              SizedBox(height: 20.h),
            ],
            if (_quoteTrips.isNotEmpty) ...[
              Text(
                'Chuyến chuyển trọ đã đặt',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: c.onSurface),
              ),
              SizedBox(height: 12.h),
              ..._quoteTrips.map(
                (trip) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _QuoteTripRow(
                    snap: trip,
                    onTap: () => context.push('/booking/quotes/${trip.id}/progress'),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
            Text(
              'Gần đây',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: c.onSurface),
            ),
            SizedBox(height: 12.h),
            ..._orders
                .where((o) {
                  final ref = o.quoteReferenceId;
                  if (ref == null) return true;
                  return !_quoteTrips.any((t) => t.id == ref);
                })
                .map((order) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _ActivityOrderRow(
                    order: order,
                    onTap: () {
                      if (order.quoteReferenceId != null) {
                        context.push('/booking/quotes/${order.quoteReferenceId}/progress');
                      } else if (order.status.isActive && order.status != OrderStatus.accepted) {
                        context.push('/orders/${order.id}/tracking');
                      }
                    },
                    onAction: () {
                      if (order.quoteReferenceId != null) {
                        context.push('/booking/quotes/${order.quoteReferenceId}/progress');
                      } else if (order.status.isActive && order.status != OrderStatus.accepted) {
                        context.push('/orders/${order.id}/tracking');
                      } else if (order.status == OrderStatus.completed && !order.hasReview) {
                        context.push('/orders/${order.id}/review');
                      } else {
                        context.push('/booking/location');
                      }
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.onTrack,
    required this.onAddLabor,
  });

  final CustomerOrder order;
  final VoidCallback onTrack;
  final VoidCallback onAddLabor;

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    return UniSurfaceCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Đơn đang chạy',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp, color: c.onSurface),
              ),
              const Spacer(),
              OrderStatusChip(status: order.status),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            '#${order.orderNumber} · ${order.packageDisplay}',
            style: TextStyle(fontSize: 13.sp, color: c.onSurfaceMuted),
          ),
          SizedBox(height: 14.h),
          PressableScale(
            onTap: onTrack,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'Theo dõi đơn →',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          PressableScale(
            onTap: onAddLabor,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: c.primary),
              ),
              child: Text(
                'Thêm người khuân vác',
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPromptCard extends StatelessWidget {
  const _ReviewPromptCard({required this.order, required this.onReview});

  final CustomerOrder order;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    return UniSurfaceCard(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Text('⭐', style: TextStyle(fontSize: 28.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hãy đánh giá chuyến chuyển trọ gần nhất!',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: c.onSurface),
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: onReview,
                  child: Text(
                    'Đánh giá và nhận xét →',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: c.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityOrderRow extends StatelessWidget {
  const _ActivityOrderRow({
    required this.order,
    required this.onTap,
    required this.onAction,
  });

  final CustomerOrder order;
  final VoidCallback onTap;
  final VoidCallback onAction;

  String get _actionLabel {
    if (order.quoteReferenceId != null && order.status == OrderStatus.accepted) {
      return 'Xem tiến trình →';
    }
    return switch (order.status) {
        OrderStatus.pending || OrderStatus.pickingUp || OrderStatus.inProgress => 'Theo dõi →',
        OrderStatus.accepted => 'Xem tiến trình →',
        OrderStatus.completed when !order.hasReview => 'Đánh giá →',
        OrderStatus.completed => 'Đặt lại →',
        OrderStatus.cancelled => 'Chi tiết →',
        _ => 'Xem →',
      };
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final time = order.completedAt ?? order.createdAt;

    return PressableScale(
      onTap: onTap,
      child: UniSurfaceCard(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: c.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: order.providerAvatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: order.providerAvatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(Icons.local_shipping_outlined, color: c.primary),
                      ),
                    )
                  : Icon(Icons.local_shipping_outlined, color: c.primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.providerName ?? order.packageDisplay,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp, color: c.onSurface),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    order.scheduledPickupAt != null
                        ? 'Lịch: ${order.scheduledPickupAt!.day}/${order.scheduledPickupAt!.month}/${order.scheduledPickupAt!.year}'
                        : '${time.day}/${time.month}/${time.year} · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      _actionLabel,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: c.primary),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              order.formattedPrice,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp, color: c.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteTripCard extends StatelessWidget {
  const _QuoteTripCard({required this.snap, required this.onOpen});

  final QuoteRequestSnapshot snap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final q = snap.confirmedQuote;

    return UniSurfaceCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, color: c.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  snap.status == QuoteProgressStatus.inProgress
                      ? 'Hôm nay là ngày chuyển'
                      : 'Chuyến chuyển trọ sắp tới',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (snap.scheduledSlotLabel != null)
            Text(snap.scheduledSlotLabel!, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          if (snap.daysUntilMoveLabel != null) ...[
            SizedBox(height: 4.h),
            Text(snap.daysUntilMoveLabel!, style: TextStyle(fontSize: 12.sp, color: c.primary)),
          ],
          if (q != null) ...[
            SizedBox(height: 6.h),
            Text('${q.providerName} · ${q.vehicleLabel}', style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted)),
          ],
          SizedBox(height: 14.h),
          PressableScale(
            onTap: onOpen,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                snap.status == QuoteProgressStatus.inProgress ? 'Theo dõi chuyến hôm nay →' : 'Xem tiến trình →',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteTripRow extends StatelessWidget {
  const _QuoteTripRow({required this.snap, required this.onTap});

  final QuoteRequestSnapshot snap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final q = snap.confirmedQuote;

    return PressableScale(
      onTap: onTap,
      child: UniSurfaceCard(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.calendar_month_rounded, color: c.primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q?.providerName ?? 'Chuyến chuyển trọ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    snap.scheduledSlotLabel ?? snap.status.label,
                    style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    snap.status.label,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: c.primary),
                  ),
                ],
              ),
            ),
            if (q != null)
              Text(
                _formatMoney(q.totalPrice),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp),
              ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }
}
