import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/mock/mock_provider_data.dart';
import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const _dayLabels = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
  static const _districts = [
    'Quận Ngũ Hành Sơn',
    'Quận Hải Châu',
    'Quận Thanh Khê',
    'Quận Sơn Trà',
    'Quận Liên Chiểu',
    'Quận Cẩm Lệ',
    'Huyện Hòa Vang',
  ];

  bool _online = true;
  int _selectedDay = 0;
  late final Map<int, _DaySchedule> _daySchedules = {
    for (var i = 0; i < _dayLabels.length; i++)
      i: _DaySchedule(
        enabled: i <= 4,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 0),
      ),
  };
  final Set<String> _areas = {};

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);
    final monday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final today = DateTime.now().weekday - 1;
    final todayHours = _hoursLabel(_daySchedules[today] ?? _daySchedules[0]!);
    final earnings = MockProviderData.orders
        .where((o) => o.isCompleted)
        .fold<int>(0, (s, o) => s + o.totalPrice);

    return ShadScreenScope(
      builder: (_, theme) {
        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            backgroundColor: c.background,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            iconTheme: IconThemeData(color: c.onSurface),
            title: Text('Lịch làm việc', style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _statusCard(theme, c),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statCard(theme, c, LucideIcons.clock, todayHours, 'GIỜ LÀM VIỆC HÔM NAY')),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard(theme, c, LucideIcons.wallet, _compact(earnings), 'THU NHẬP HÔM NAY (VND)')),
                ],
              ),
              const SizedBox(height: 24),
              _sectionRow(theme, c, 'Lịch làm việc hàng tuần', 'Thiết lập thời gian bạn sẵn sàng nhận đơn.'),
              const SizedBox(height: 12),
              SizedBox(
                height: 144,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dayLabels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _dayCard(theme, c, i, monday.add(Duration(days: i))),
                ),
              ),
              const SizedBox(height: 12),
              _dayEditor(theme, c),
              const SizedBox(height: 24),
              _sectionRow(theme, c, 'Khu vực hoạt động ưu tiên',
                  'Chọn quận tại Đà Nẵng bạn muốn nhận đơn — ưu tiên khu vực gần làng đại học.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._districts.map((d) => _areaChip(theme, c, d)),
                  _addAreaChip(theme, c),
                ],
              ),
              const SizedBox(height: 20),
              _mapPreview(theme, c),
            ],
          ),
        );
      },
    );
  }

  // ---------- Status ----------
  Widget _statusCard(ShadThemeData theme, UniMoveColors c) {
    return _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trạng thái hiện tại',
              style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w800, color: c.onSurface)),
          const SizedBox(height: 4),
          Text('Bật để bắt đầu nhận đơn vận chuyển mới.',
              style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _online ? c.iconBgTertiary : c.surfaceHigh,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _online ? c.success : c.border),
            ),
            child: Row(
              children: [
                Icon(_online ? LucideIcons.circleCheck : LucideIcons.circleDashed,
                    size: 16, color: _online ? c.success : c.onSurfaceMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_online ? 'Đang hoạt động' : 'Đang nghỉ',
                      style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w700, color: _online ? c.success : c.onSurfaceMuted)),
                ),
                Switch.adaptive(
                  value: _online,
                  activeThumbColor: c.primary,
                  onChanged: (v) => setState(() => _online = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(ShadThemeData theme, UniMoveColors c, IconData icon, String value, String label) {
    return _card(
      c,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: c.primary, size: 22),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.w800, color: c.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sectionRow(ShadThemeData theme, UniMoveColors c, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w800, color: c.onSurface)),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted, height: 1.35)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (title.startsWith('Lịch'))
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chạm vào từng ngày để chỉnh giờ riêng')),
            ),
            icon: const Icon(LucideIcons.pencil, size: 15),
            label: const Text('Chỉnh sửa'),
          ),
      ],
    );
  }

  Widget _dayCard(ShadThemeData theme, UniMoveColors c, int i, DateTime date) {
    final schedule = _daySchedules[i]!;
    final working = schedule.enabled;
    final selected = _selectedDay == i;
    return GestureDetector(
      onTap: () => setState(() => _selectedDay = i),
      onLongPress: () => setState(() => _daySchedules[i] = schedule.copyWith(enabled: !working)),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: working ? c.surface : c.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c.primary : (working ? c.primary.withValues(alpha: 0.4) : c.border),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_dayLabels[i], style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: working ? c.primary : c.border,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${date.day}',
                  style: theme.textTheme.p.copyWith(
                      color: working ? Colors.white : c.onSurfaceMuted, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 6),
            Text(
              working ? '${_timeText(schedule.start)}\n${_timeText(schedule.end)}' : 'Nghỉ',
              textAlign: TextAlign.center,
              style: theme.textTheme.small.copyWith(
                color: working ? c.onSurface : c.onSurfaceMuted,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayEditor(ShadThemeData theme, UniMoveColors c) {
    final schedule = _daySchedules[_selectedDay]!;
    return _card(
      c,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Thiết lập ${_dayLabels[_selectedDay]}',
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w800, color: c.onSurface),
              ),
              const Spacer(),
              Switch.adaptive(
                value: schedule.enabled,
                activeThumbColor: c.primary,
                onChanged: (v) => setState(() => _daySchedules[_selectedDay] = schedule.copyWith(enabled: v)),
              ),
            ],
          ),
          Text(
            schedule.enabled ? 'Bạn có thể chỉnh giờ làm riêng cho ngày này.' : 'Ngày này đang tắt nhận đơn.',
            style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _timeButton(
                  theme,
                  c,
                  label: 'Bắt đầu',
                  value: _timeText(schedule.start),
                  enabled: schedule.enabled,
                  onTap: () => _pickTime(_selectedDay, isStart: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timeButton(
                  theme,
                  c,
                  label: 'Kết thúc',
                  value: _timeText(schedule.end),
                  enabled: schedule.enabled,
                  onTap: () => _pickTime(_selectedDay, isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeButton(
    ShadThemeData theme,
    UniMoveColors c, {
    required String label,
    required String value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final tint = enabled ? c.primary : c.onSurfaceMuted;
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: enabled ? c.primary.withValues(alpha: 0.45) : c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.small.copyWith(color: c.onSurfaceMuted)),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.p.copyWith(color: tint, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Future<void> _pickTime(int day, {required bool isStart}) async {
    final schedule = _daySchedules[day]!;
    final initial = isStart ? schedule.start : schedule.end;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Giờ bắt đầu' : 'Giờ kết thúc',
    );
    if (!mounted || picked == null) return;

    final next = isStart ? schedule.copyWith(start: picked) : schedule.copyWith(end: picked);
    if (_toMinutes(next.end) <= _toMinutes(next.start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ kết thúc phải lớn hơn giờ bắt đầu')),
      );
      return;
    }
    setState(() => _daySchedules[day] = next);
  }

  Widget _areaChip(ShadThemeData theme, UniMoveColors c, String label) {
    final selected = _areas.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _areas.remove(label);
        } else {
          _areas.add(label);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: theme.textTheme.small.copyWith(
                    color: selected ? Colors.white : c.onSurface, fontWeight: FontWeight.w700)),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(LucideIcons.circleCheck, size: 15, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addAreaChip(ShadThemeData theme, UniMoveColors c) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm khu vực — chọn trên bản đồ (sắp có)')),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: c.primaryLight, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 15, color: c.primaryLight),
            const SizedBox(width: 6),
            Text('Thêm khu vực',
                style: theme.textTheme.small.copyWith(color: c.primaryLight, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _mapPreview(ShadThemeData theme, UniMoveColors c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surfaceTint, c.surfaceHigh],
          ),
          border: Border.all(color: c.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapGridPainter(c.border))),
            const Positioned(top: 36, left: 50, child: Icon(LucideIcons.mapPin, color: Color(0xFF2563EB), size: 26)),
            const Positioned(top: 80, left: 140, child: Icon(LucideIcons.mapPin, color: Color(0xFF2563EB), size: 22)),
            const Positioned(top: 54, right: 60, child: Icon(LucideIcons.mapPin, color: Color(0xFF2563EB), size: 24)),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.map, size: 14, color: c.primary),
                    const SizedBox(width: 6),
                    Text('Bản đồ khu vực ưu tiên',
                        style: theme.textTheme.small.copyWith(color: c.onSurface, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: c.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mở bản đồ chọn khu vực (sắp có)')),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(LucideIcons.plus, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(UniMoveColors c, {required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }

  static String _compact(int amount) {
    if (amount < 1000) return '$amount';
    final k = amount / 1000;
    final s = (k == k.roundToDouble() ? k.toInt().toString() : k.toStringAsFixed(0));
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}k';
  }

  static int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  static String _timeText(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String _hoursLabel(_DaySchedule s) {
    if (!s.enabled) return '0';
    final mins = _toMinutes(s.end) - _toMinutes(s.start);
    if (mins <= 0) return '0';
    final h = mins / 60;
    return h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1);
  }
}

class _DaySchedule {
  const _DaySchedule({
    required this.enabled,
    required this.start,
    required this.end,
  });

  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  _DaySchedule copyWith({
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return _DaySchedule(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    const step = 34.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => oldDelegate.color != color;
}
