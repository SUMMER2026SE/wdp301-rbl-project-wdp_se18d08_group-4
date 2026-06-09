import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/smooth_cta_button.dart';
import '../../data/quote_progress_repository.dart';
import '../../domain/quote_models.dart';
import '../widgets/provider_reviews_panel.dart';

/// Tiến trình báo giá — nhận báo giá, so sánh, chốt nhà xe trên app.
class QuoteProgressPage extends StatefulWidget {
  const QuoteProgressPage({
    super.key,
    required this.referenceId,
    this.photosUploadFailed = false,
  });

  final String referenceId;
  final bool photosUploadFailed;

  @override
  State<QuoteProgressPage> createState() => _QuoteProgressPageState();
}

class _QuoteProgressPageState extends State<QuoteProgressPage> {
  final _repo = QuoteProgressRepository.instance;
  QuoteRequestSnapshot? _snapshot;
  bool _loading = true;
  int _sortIndex = 0;
  Timer? _statusPoll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _statusPoll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final snap = await _repo.fetch(widget.referenceId);
    if (!mounted) return;

    // Đã chốt nhà xe nhưng chưa chọn lịch → chuyển thẳng sang bước lịch.
    if (snap?.status == QuoteProgressStatus.providerConfirmed) {
      context.go('/booking/quotes/${widget.referenceId}/schedule');
      return;
    }

    setState(() {
      _snapshot = snap;
      _loading = false;
    });
    _syncStatusPoll(snap?.status);
  }

  void _syncStatusPoll(QuoteProgressStatus? status) {
    _statusPoll?.cancel();
    if (status == QuoteProgressStatus.scheduled ||
        status == QuoteProgressStatus.depositPaid) {
      _statusPoll = Timer.periodic(const Duration(seconds: 3), (_) => _load(silent: true));
    }
  }

  List<ProviderQuoteResponse> get _sortedQuotes {
    final quotes = [...?_snapshot?.quotes];
    if (_sortIndex == 1) {
      quotes.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      quotes.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    }
    return quotes;
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

    final snap = _snapshot;
    if (snap == null) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('Tiến trình báo giá')),
        body: Center(child: Text('Không tìm thấy yêu cầu', style: TextStyle(color: c.onSurface))),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Tiến trình báo giá', style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: c.primary), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
          children: [
            _refCard(c, snap),
            if (snap.hasScheduledMove) ...[
              SizedBox(height: 12.h),
              _scheduleHeroCard(c, snap),
            ],
            if (widget.photosUploadFailed) ...[
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: c.chipBg,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: c.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Ảnh chưa tải lên được. Bạn có thể gửi ảnh qua chat khi đơn bắt đầu vận chuyển.',
                  style: TextStyle(fontSize: 12.sp, color: c.onSurface, height: 1.35),
                ),
              ),
            ],
            SizedBox(height: 16.h),
            _timeline(c, snap.status),
            SizedBox(height: 20.h),
            _statusContent(c, snap),
          ],
        ),
      ),
    );
  }

  Widget _refCard(UniMoveColors c, QuoteRequestSnapshot snap) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mã: ${snap.id}', style: TextStyle(fontWeight: FontWeight.w700, color: c.primary)),
          SizedBox(height: 8.h),
          Text('${snap.pickup} → ${snap.destination}', style: TextStyle(fontSize: 13.sp, color: c.onSurface)),
        ],
      ),
    );
  }

  Widget _scheduleHeroCard(UniMoveColors c, QuoteRequestSnapshot snap) {
    final countdown = snap.daysUntilMoveLabel;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primary.withValues(alpha: 0.9), c.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded, color: Colors.white, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                'Lịch chuyển trọ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            snap.scheduledSlotLabel ?? '',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17.sp),
          ),
          if (countdown != null) ...[
            SizedBox(height: 6.h),
            Text(
              countdown,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.sp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeline(UniMoveColors c, QuoteProgressStatus current) {
    final idx = quoteTimelineIndex(current);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < quoteTimelineSteps.length; i++) ...[
            if (i > 0)
              Container(
                width: 20.w,
                height: 2,
                margin: EdgeInsets.only(bottom: 22.h),
                color: i <= idx ? c.primary : c.border,
              ),
            Column(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: i <= idx ? c.primary : c.surfaceTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    i < idx ? Icons.check : Icons.circle,
                    size: i < idx ? 16.sp : 8.sp,
                    color: i <= idx ? AppColors.onPrimary : c.onSurfaceMuted,
                  ),
                ),
                SizedBox(height: 4.h),
                SizedBox(
                  width: 58.w,
                  child: Text(
                    quoteTimelineSteps[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: i == idx ? FontWeight.w700 : FontWeight.w500,
                      color: i == idx ? c.primary : c.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusContent(UniMoveColors c, QuoteRequestSnapshot snap) {
    return switch (snap.status) {
      QuoteProgressStatus.waitingQuotes => _waitingBox(c),
      QuoteProgressStatus.quotesReady => _quotesSection(c, snap),
      QuoteProgressStatus.providerConfirmed => _pickScheduleSection(c, snap),
      QuoteProgressStatus.scheduled => _awaitingProviderSection(c, snap),
      QuoteProgressStatus.providerAccepted => _providerAcceptedSection(c, snap),
      QuoteProgressStatus.depositPaid => _depositPaidSection(c, snap),
      QuoteProgressStatus.inProgress => _inProgressSection(c, snap),
      QuoteProgressStatus.completed => _completedSection(c),
    };
  }

  Widget _waitingBox(UniMoveColors c) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(14.r)),
      child: Column(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 40.sp, color: c.primary),
          SizedBox(height: 10.h),
          Text(
            'Đang chờ nhà xe báo giá',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            'Các provider đã xác minh sẽ gửi giá + bảng phụ phí lên app. '
            'Bạn sẽ được thông báo ngay khi có báo giá.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _quotesSection(UniMoveColors c, QuoteRequestSnapshot snap) {
    final quotes = _sortedQuotes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${quotes.length} nhà xe đã báo giá',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6.h),
        Text(
          'So sánh giá, đánh giá và phụ phí minh bạch trước khi chốt.',
          style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _sortChip(c, 'Giá thấp nhất', 0),
            SizedBox(width: 8.w),
            _sortChip(c, 'Đánh giá cao', 1),
          ],
        ),
        SizedBox(height: 14.h),
        ...quotes.map((q) => _quoteCard(c, q, showAction: true)),
      ],
    );
  }

  Widget _sortChip(UniMoveColors c, String label, int index) {
    final active = _sortIndex == index;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
      selected: active,
      onSelected: (_) => setState(() => _sortIndex = index),
      selectedColor: c.primary,
      labelStyle: TextStyle(color: active ? Colors.white : c.onSurface, fontWeight: FontWeight.w600),
    );
  }

  Widget _quoteCard(UniMoveColors c, ProviderQuoteResponse q, {bool showAction = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(q.providerName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp)),
              ),
              Text(_money(q.totalPrice), style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, fontSize: 16.sp)),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              InkWell(
                onTap: () => _openReviews(context, q),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 16.sp),
                      Text(
                        ' ${q.rating} (${q.reviewCount} đánh giá)',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: c.primary),
                      ),
                      Icon(Icons.chevron_right, size: 16.sp, color: c.primary),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  q.vehicleLabel,
                  style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (q.surcharges.isNotEmpty) ...[
            SizedBox(height: 8.h),
            ...q.surcharges.map(
              (s) => Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(
                  '· ${s.label}: ${_money(s.amount)}',
                  style: TextStyle(fontSize: 11.sp, color: c.onSurfaceMuted),
                ),
              ),
            ),
          ],
          if (showAction) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/booking/quotes/${widget.referenceId}/offer/${q.id}'),
                child: const Text('Xem chi tiết & chốt'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pickScheduleSection(UniMoveColors c, QuoteRequestSnapshot snap) {
    final q = snap.confirmedQuote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đã chốt nhà xe', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 12.h),
        if (q != null) _quoteCard(c, q),
        SizedBox(height: 8.h),
        Text(
          'Bước tiếp: chọn ngày chuyển trọ theo lịch trống của nhà xe.',
          style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted, height: 1.35),
        ),
        SizedBox(height: 16.h),
        SmoothCtaButton(
          label: 'Chọn ngày chuyển trọ',
          onPressed: () => context.go('/booking/quotes/${widget.referenceId}/schedule'),
        ),
      ],
    );
  }

  Widget _awaitingProviderSection(UniMoveColors c, QuoteRequestSnapshot snap) {
    final q = snap.confirmedQuote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đã gửi lịch chuyển trọ', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 12.h),
        if (q != null) _quoteCard(c, q),
        if (snap.scheduledSlotLabel != null) ...[
          SizedBox(height: 10.h),
          _scheduleInfoCard(c, snap.scheduledSlotLabel!),
        ],
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(14.r)),
          child: Column(
            children: [
              Icon(Icons.hourglass_top_rounded, size: 40.sp, color: c.primary),
              SizedBox(height: 10.h),
              Text(
                'Đang chờ nhà xe xác nhận',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                'Nhà xe sẽ xem lịch bạn chọn và phản hồi trên app. '
                'Sau khi được xác nhận, bạn có thể nhắn tin và đặt cọc.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Kiểm tra trạng thái'),
        ),
      ],
    );
  }

  Widget _providerAcceptedSection(UniMoveColors c, QuoteRequestSnapshot snap) {
    final q = snap.confirmedQuote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nhà xe đã xác nhận lịch', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 12.h),
        if (q != null) _quoteCard(c, q),
        if (snap.scheduledSlotLabel != null) ...[
          SizedBox(height: 10.h),
          _scheduleInfoCard(c, snap.scheduledSlotLabel!),
        ],
        SizedBox(height: 12.h),
        Text(
          'Trao đổi chi tiết qua chat. Đặt cọc để giữ chỗ — vận chuyển bắt đầu vào ngày đã hẹn.',
          style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted, height: 1.35),
        ),
        SizedBox(height: 16.h),
        OutlinedButton.icon(
          onPressed: () => _openChat(snap.conversationId),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Nhắn tin với nhà xe'),
        ),
        SizedBox(height: 10.h),
        SmoothCtaButton(
          label: 'Đặt cọc giữ chỗ',
          onPressed: _payDeposit,
        ),
      ],
    );
  }

  Widget _depositPaidSection(UniMoveColors c, QuoteRequestSnapshot snap) {
    final q = snap.confirmedQuote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đã đặt cọc — chờ ngày chuyển', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 12.h),
        if (q != null) _quoteCard(c, q),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(14.r)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chuyến đã sẵn sàng',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                'Nhà xe sẽ đến đúng khung giờ đã hẹn. '
                'Bạn sẽ nhận thông báo khi đến ngày và giờ chuyển.',
                style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        OutlinedButton.icon(
          onPressed: () => _openChat(snap.conversationId),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Nhắn tin với nhà xe'),
        ),
        SizedBox(height: 10.h),
        OutlinedButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Về trang chủ'),
        ),
      ],
    );
  }

  Future<void> _payDeposit() async {
    try {
      final snap = await _repo.payDeposit(widget.referenceId);
      if (!mounted) return;
      await _showDepositSuccess(snap);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showDepositSuccess(QuoteRequestSnapshot snap) async {
    final c = UniMoveColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: c.primary, size: 56.sp),
            SizedBox(height: 16.h),
            Text(
              'Đặt cọc thành công!',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 10.h),
            Text(
              'Chuyến chuyển ${snap.scheduledSlotLabel ?? ''} đã được giữ. '
              'Theo dõi tại tab Hoạt động — bạn sẽ được nhắc khi đến ngày chuyển.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: c.onSurfaceMuted, height: 1.45),
            ),
            SizedBox(height: 24.h),
            SmoothCtaButton(
              label: 'Về trang chủ',
              showArrow: false,
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
              },
            ),
            SizedBox(height: 10.h),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ở lại tiến trình'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleInfoCard(UniMoveColors c, String label) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: c.chipBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available, color: c.primary, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Lịch chuyển: $label',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inProgressSection(UniMoveColors c, QuoteRequestSnapshot snap) {
    final q = snap.confirmedQuote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hôm nay là ngày chuyển', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
        if (q != null) ...[
          SizedBox(height: 12.h),
          Text('${q.providerName} · ${_money(q.totalPrice)}', style: TextStyle(fontSize: 14.sp)),
        ],
        if (snap.scheduledSlotLabel != null) ...[
          SizedBox(height: 10.h),
          _scheduleInfoCard(c, snap.scheduledSlotLabel!),
        ],
        SizedBox(height: 16.h),
        if (snap.conversationId != null) ...[
          SmoothCtaButton(
            label: 'Nhắn tin với tài xế',
            onPressed: () => context.push('/chat/${snap.conversationId}'),
          ),
          SizedBox(height: 10.h),
        ],
        SmoothCtaButton(
          label: 'Theo dõi tiến trình',
          onPressed: () {
            if (snap.orderId != null) {
              context.push('/orders/${snap.orderId}/tracking');
            }
          },
        ),
      ],
    );
  }

  Widget _completedSection(UniMoveColors c) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: c.border)),
      child: Text(
        'Chuyến đã hoàn thành. Không thể nhắn tin thêm để giao dịch được bảo vệ trên app.',
        style: TextStyle(fontSize: 13.sp, color: c.onSurfaceMuted, height: 1.4),
      ),
    );
  }

  Future<void> _openChat(String? conversationId) async {
    var convId = conversationId;
    if (convId == null) {
      final refreshed = await _repo.fetch(widget.referenceId);
      convId = refreshed?.conversationId;
    }
    if (!mounted) return;
    if (convId != null) {
      context.push('/chat/$convId');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat chưa sẵn sàng — kéo xuống để làm mới')),
    );
  }

  void _openReviews(BuildContext context, ProviderQuoteResponse q) {
    showProviderReviewsSheet(
      context,
      providerName: q.providerName,
      subtitle: q.vehicleLabel,
      stats: ProviderReviewStats.from(
        averageRating: q.rating,
        totalCount: q.reviewCount,
        reviews: q.recentReviews,
      ),
    );
  }

  String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }
}
