import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/booking_scaffold.dart';
import '../../../../core/widgets/smooth_cta_button.dart';
import '../../../pass_items/presentation/widgets/pass_item_image.dart';
import '../../domain/booking_models.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/booking_flow_state.dart';

/// Mô tả trọ — form báo giá minh bạch, không tự động chốt giá.
class MoveDormDetailsPage extends StatefulWidget {
  const MoveDormDetailsPage({super.key});

  @override
  State<MoveDormDetailsPage> createState() => _MoveDormDetailsPageState();
}

class _MoveDormDetailsPageState extends State<MoveDormDetailsPage> {
  final _picker = ImagePicker();
  late final TextEditingController _noteCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: context.read<BookingFlowCubit>().state.dormNote);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    return BlocBuilder<BookingFlowCubit, BookingFlowState>(
      builder: (context, state) {
        final cubit = context.read<BookingFlowCubit>();

        return BookingScaffold(
          title: 'Mô tả trọ',
          body: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 120.h),
            children: [
              _infoBanner(c),
              SizedBox(height: 16.h),
              _routeSummary(c, state),
              SizedBox(height: 20.h),
              _sectionTitle(c, 'Trọ cũ (điểm lấy đồ)'),
              SizedBox(height: 10.h),
              _floorRow(c, state.pickupFloor, state.pickupHasElevator, cubit.setPickupFloor,
                  cubit.setPickupHasElevator),
              if (state.showPickupStairPhotos) ...[
                SizedBox(height: 12.h),
                _sectionPhotoUpload(c, state, cubit, DormPhotoSection.pickupStairs),
              ],
              SizedBox(height: 12.h),
              _alleyChips(c, state.pickupAlleyAccess, cubit.setPickupAlley),
              if (state.showPickupAlleyPhotos) ...[
                SizedBox(height: 12.h),
                _sectionPhotoUpload(c, state, cubit, DormPhotoSection.pickupAlley),
              ],
              SizedBox(height: 20.h),
              _sectionTitle(c, 'Trọ mới (điểm giao)'),
              SizedBox(height: 10.h),
              _floorRow(c, state.floorCount, state.hasElevator, cubit.setFloorCount, cubit.setHasElevator),
              if (state.showDestinationStairPhotos) ...[
                SizedBox(height: 12.h),
                _sectionPhotoUpload(c, state, cubit, DormPhotoSection.destinationStairs),
              ],
              SizedBox(height: 12.h),
              _alleyChips(c, state.destinationAlleyAccess, cubit.setDestinationAlley),
              if (state.showDestinationAlleyPhotos) ...[
                SizedBox(height: 12.h),
                _sectionPhotoUpload(c, state, cubit, DormPhotoSection.destinationAlley),
              ],
              SizedBox(height: 20.h),
              _sectionTitle(c, 'Khối lượng đồ'),
              SizedBox(height: 10.h),
              _cargoChips(c, state.cargoVolume, cubit.setCargoVolume),
              if (state.showCargoPhotos) ...[
                SizedBox(height: 12.h),
                _sectionPhotoUpload(c, state, cubit, DormPhotoSection.cargo),
              ],
              SizedBox(height: 20.h),
              _sectionTitle(c, 'Ghi chú thêm'),
              SizedBox(height: 8.h),
              TextField(
                controller: _noteCtrl,
                onChanged: cubit.setDormNote,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'VD: Có tủ lớn, máy giặt; cổng hẻm cần chụp ảnh...',
                  filled: true,
                  fillColor: c.surfaceTint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _referenceLink(context, c),
            ],
          ),
          bottom: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nhà xe báo giá trên app · So sánh & chốt minh bạch',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted, height: 1.3),
                  ),
                  SizedBox(height: 10.h),
                  SmoothCtaButton(
                    label: _submitting ? 'Đang gửi...' : 'Gửi yêu cầu báo giá',
                    onPressed: _submitting
                        ? null
                        : () async {
                            setState(() => _submitting = true);
                            try {
                              final result = await cubit.submitQuoteRequest();
                              if (!context.mounted) return;
                              final photosParam =
                                  result.photoUploadFailed ? '?photos=failed' : '';
                              context.go(
                                '/booking/quotes/${result.referenceId}/progress$photosParam',
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _submitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Không gửi được yêu cầu: $e')),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoBanner(UniMoveColors c) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: c.chipBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 20.sp, color: c.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Mô tả càng rõ, báo giá càng chính xác. Các nhà xe sẽ gửi giá + '
              'bảng phụ phí lên app để bạn so sánh và chốt.',
              style: TextStyle(fontSize: 12.sp, color: c.onSurface, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeSummary(UniMoveColors c, BookingFlowState state) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          _routeLine(Icons.trip_origin, c.primary, state.pickup),
          Padding(
            padding: EdgeInsets.only(left: 11.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 20.h, color: c.border),
            ),
          ),
          _routeLine(Icons.location_on, c.accentGreen, state.destination),
        ],
      ),
    );
  }

  Widget _routeLine(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(UniMoveColors c, String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: c.onSurface),
    );
  }

  Widget _floorRow(
    UniMoveColors c,
    int floor,
    bool hasElevator,
    void Function(int) onFloor,
    void Function(bool) onElevator,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Text('Tầng', style: TextStyle(fontSize: 14.sp, color: c.onSurfaceMuted)),
            const Spacer(),
            _roundBtn(c, Icons.remove, () => onFloor(floor - 1)),
            SizedBox(width: 12.w),
            Text('$floor', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
            SizedBox(width: 12.w),
            _roundBtn(c, Icons.add, () => onFloor(floor + 1)),
          ],
        ),
        SizedBox(height: 10.h),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Có thang máy', style: TextStyle(fontSize: 14.sp)),
          value: hasElevator,
          activeThumbColor: c.primary,
          onChanged: onElevator,
        ),
      ],
    );
  }

  Widget _roundBtn(UniMoveColors c, IconData icon, VoidCallback onTap) {
    return Material(
      color: c.surfaceTint,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36.w,
          height: 36.w,
          child: Icon(icon, size: 18.sp, color: c.primary),
        ),
      ),
    );
  }

  Widget _alleyChips(UniMoveColors c, AlleyAccess selected, void Function(AlleyAccess) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đường vào', style: TextStyle(fontSize: 14.sp, color: c.onSurfaceMuted)),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: AlleyAccess.values.map((a) {
            final isSelected = selected == a;
            return ChoiceChip(
              label: Text(a.label, style: TextStyle(fontSize: 12.sp)),
              selected: isSelected,
              onSelected: (_) => onSelect(a),
              selectedColor: c.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : c.onSurface,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
        if (selected != AlleyAccess.unknown) ...[
          SizedBox(height: 6.h),
          Text(selected.hint, style: TextStyle(fontSize: 11.sp, color: c.onSurfaceMuted)),
        ],
      ],
    );
  }

  Widget _cargoChips(UniMoveColors c, CargoVolume selected, void Function(CargoVolume) onSelect) {
    return Column(
      children: CargoVolume.values.map((v) {
        final isSelected = selected == v;
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Material(
            color: isSelected ? c.primaryContainer : c.surface,
            borderRadius: BorderRadius.circular(14.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () => onSelect(v),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: isSelected ? c.primary : c.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? c.primary : c.onSurfaceMuted,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                          Text(v.examples, style: TextStyle(fontSize: 12.sp, color: c.onSurfaceMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showImageSourceSheet(DormPhotoSection section) async {
    final c = UniMoveColors.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: c.primary),
                  title: const Text('Thư viện ảnh'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera_outlined, color: c.primary),
                  title: const Text('Chụp ảnh'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null) return;
    await _pickImage(source, section);
  }

  Future<void> _pickImage(ImageSource source, DormPhotoSection section) async {
    final cubit = context.read<BookingFlowCubit>();
    final paths = cubit.state.dormImagePathsFor(section);
    if (paths.length >= BookingFlowCubit.maxImagesPerSection) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      cubit.addSectionImage(section, picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được ảnh: $e')),
      );
    }
  }

  Widget _sectionPhotoUpload(
    UniMoveColors c,
    BookingFlowState state,
    BookingFlowCubit cubit,
    DormPhotoSection section,
  ) {
    final paths = state.dormImagePathsFor(section);
    final maxImages = BookingFlowCubit.maxImagesPerSection;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_outlined, size: 16.sp, color: c.primary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  section.label,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: c.onSurface),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(section.hint, style: TextStyle(fontSize: 11.sp, color: c.onSurfaceMuted)),
          SizedBox(height: 10.h),
          if (paths.isEmpty)
            _emptyPhotoBtn(c, section)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < paths.length; i++) ...[
                    _imageThumb(c, paths[i], i, cubit, section),
                    SizedBox(width: 8.w),
                  ],
                  if (paths.length < maxImages) _addImageBtn(c, section),
                ],
              ),
            ),
          if (paths.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              '${paths.length}/$maxImages ảnh',
              style: TextStyle(fontSize: 10.sp, color: c.onSurfaceMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyPhotoBtn(UniMoveColors c, DormPhotoSection section) {
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () => _showImageSourceSheet(section),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          height: 72.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: c.border, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 22.sp, color: c.primary),
              SizedBox(width: 8.w),
              Text(
                'Thêm ảnh',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: c.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageThumb(
    UniMoveColors c,
    String path,
    int index,
    BookingFlowCubit cubit,
    DormPhotoSection section,
  ) {
    return Stack(
      children: [
        PassItemImage(
          imageUrl: path,
          width: 80.w,
          height: 80.w,
          borderRadius: BorderRadius.circular(10.r),
          fit: BoxFit.cover,
          errorPlaceholder: Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10.r)),
            child: Icon(Icons.broken_image_outlined, color: c.onSurfaceMuted, size: 24.sp),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => cubit.removeSectionImage(section, index),
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: Icon(Icons.close, size: 12.sp, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addImageBtn(UniMoveColors c, DormPhotoSection section) {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(section),
      child: Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: c.border, width: 1.5),
        ),
        child: Icon(Icons.add, size: 24.sp, color: c.primary),
      ),
    );
  }

  Widget _referenceLink(BuildContext context, UniMoveColors c) {
    return TextButton.icon(
      onPressed: () => context.push('/booking/reference-prices'),
      icon: Icon(Icons.receipt_long_outlined, size: 18.sp, color: c.primary),
      label: Text(
        'Xem bảng phụ phí tham khảo',
        style: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
