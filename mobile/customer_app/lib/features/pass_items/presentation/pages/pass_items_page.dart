import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/uni_move_colors.dart';
import '../../data/pass_item_location_prefs.dart';
import '../../data/pass_item_repository.dart';
import '../../domain/pass_item.dart';
import '../../domain/pass_item_provinces.dart';
import '../pass_item_format.dart';
import '../widgets/pass_item_image.dart';
import '../widgets/pass_item_province_picker_sheet.dart';

class PassItemsPage extends StatefulWidget {
  const PassItemsPage({super.key});

  @override
  State<PassItemsPage> createState() => _PassItemsPageState();
}

class _PassItemsPageState extends State<PassItemsPage> with SingleTickerProviderStateMixin {
  final _repo = PassItemRepository();
  late final TabController _tab = TabController(length: 3, vsync: this);
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  String _category = 'Tất cả';
  String _provinceId = PassItemProvince.defaultId;
  String _keyword = '';
  bool _loading = true;
  List<PassItemPost> _browse = const [];
  List<PassItemPost> _mine = const [];
  List<PassItemPost> _favorites = const [];

  PassItemProvince get _province => PassItemProvince.resolve(_provinceId);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final saved = await loadPassItemsProvinceId();
    if (!mounted) return;
    setState(() => _provinceId = saved);
    await _load();
  }

  Future<void> _pickProvince() async {
    final picked = await showPassItemProvincePicker(context, selectedId: _provinceId);
    if (picked == null || picked == _provinceId) return;
    await savePassItemsProvinceId(picked);
    if (!mounted) return;
    setState(() => _provinceId = picked);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repo.browse(keyword: _keyword, category: _category, provinceId: _provinceId),
      _repo.myPosts(),
      _repo.myInterests(),
    ]);
    if (!mounted) return;
    setState(() {
      _browse     = results[0];
      _mine       = results[1];
      _favorites  = results[2];
      _loading    = false;
    });
  }

  Future<void> _openCreate() async {
    final created = await context.push<bool>('/pass-items/new');
    if (created == true) {
      _tab.animateTo(2);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chợ sinh viên', style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: c.primary),
                const SizedBox(width: 3),
                Text(_province.label, style: TextStyle(color: c.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: c.primary,
          unselectedLabelColor: c.onSurfaceMuted,
          indicatorColor: c.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Khám phá'),
            Tab(text: 'Yêu thích'),
            Tab(text: 'Tin của tôi'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        elevation: 3,
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Đăng tin', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(
        controller: _tab,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _browseTab(c),
          _favoritesTab(c),
          _myTab(c),
        ],
      ),
    );
  }

  Widget _browseTab(UniMoveColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _provinceSelector(c),
              const SizedBox(height: 10),
              ShadInput(
                controller: _searchCtrl,
                placeholder: const Text('Tìm tủ, bàn, tủ lạnh, sách...'),
                leading: Icon(LucideIcons.search, size: 18, color: c.primary),
                onChanged: (v) {
                  _keyword = v;
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), _load);
                },
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Danh mục',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.onSurfaceMuted),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PassItemCategories.all.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final label = i == 0 ? 'Tất cả' : PassItemCategories.all[i - 1];
                    return _categoryChip(c, label);
                  },
                ),
              ),
            ],
          ),
        ),
        if (!_loading && _browse.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_browse.length} tin tại ${_province.label}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.onSurfaceMuted),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : _browse.isEmpty
                  ? _emptyBrowse(c)
                  : RefreshIndicator(
                      color: c.primary,
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.54,
                        ),
                        itemCount: _browse.length,
                        itemBuilder: (_, i) => _gridCard(c, _browse[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _provinceSelector(UniMoveColors c) {
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _pickProvince,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.location_on_rounded, color: c.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khu vực', style: TextStyle(fontSize: 10, color: c.onSurfaceMuted)),
                    Text(
                      _province.label,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.onSurface),
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: c.onSurfaceMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(UniMoveColors c, String label) {
    final active = _category == label;
    return GestureDetector(
      onTap: () {
        setState(() => _category = label);
        _load();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.primary : c.surfaceTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? c.primary : c.border.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : c.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _gridCard(UniMoveColors c, PassItemPost post) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: c.navBarShadow.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await context.push('/pass-items/${post.id}');
              _load();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PassItemImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorPlaceholder: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                c.surfaceTint,
                                c.primary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.photo_outlined,
                              color: c.primary.withValues(alpha: 0.45),
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _imageBadge(c, post.condition.label),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        passItemPriceLabel(post),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: post.isFree ? c.success : c.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _tag(c, post.category),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 12, color: c.onSurfaceMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              post.area,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: c.onSurfaceMuted),
                            ),
                          ),
                          Text(
                            passItemTimeAgo(post.createdAt),
                            style: TextStyle(fontSize: 10, color: c.onSurfaceMuted.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageBadge(UniMoveColors c, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _tag(UniMoveColors c, String text, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent ? c.primary.withValues(alpha: 0.12) : c.surfaceTint,
        borderRadius: BorderRadius.circular(8),
        border: accent ? Border.all(color: c.primary.withValues(alpha: 0.35)) : null,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: accent ? c.primary : c.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyBrowse(UniMoveColors c) {
    return ListView(
      children: [
        const SizedBox(height: 64),
        Icon(Icons.location_city_outlined, size: 40, color: c.onSurfaceMuted),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Chưa có tin tại ${_province.label}.\nThử đổi tỉnh/thành phố hoặc đăng tin mới.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(onPressed: _pickProvince, child: const Text('Chọn tỉnh / thành phố khác')),
        ),
      ],
    );
  }

  // ---------------- Yêu thích ----------------

  Widget _favoritesTab(UniMoveColors c) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_favorites.isEmpty) return _emptyFavorites(c);
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.54,
        ),
        itemCount: _favorites.length,
        itemBuilder: (_, i) => _favoriteCard(c, _favorites[i]),
      ),
    );
  }

  Widget _favoriteCard(UniMoveColors c, PassItemPost post) {
    final isSold = post.status == PassItemStatus.completed || post.status == PassItemStatus.hidden;
    return Stack(
      clipBehavior: Clip.antiAlias,
      children: [
        Opacity(
          opacity: isSold ? 0.55 : 1.0,
          child: _gridCard(c, post),
        ),
        if (isSold)
          Positioned(
            top: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Đã bán', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        Positioned(
          top: 6, right: 6,
          child: GestureDetector(
            onTap: () => _removeFavorite(post),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _removeFavorite(PassItemPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bỏ yêu thích?'),
        content: Text('Bỏ quan tâm "${post.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ yêu thích', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _repo.removeInterest(post.id);
      _load();
    }
  }

  Widget _emptyFavorites(UniMoveColors c) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.favorite_border, size: 48, color: c.onSurfaceMuted),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Chưa có tin yêu thích.\nNhấn "Tôi muốn nhận" trên bất kỳ tin nào để thêm vào đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Tin của tôi ----------------
  Widget _myTab(UniMoveColors c) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_mine.isEmpty) return _empty(c, 'Bạn chưa đăng tin nào');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _mine.length,
        itemBuilder: (_, i) => _myCard(c, _mine[i]),
      ),
    );
  }

  Widget _myCard(UniMoveColors c, PassItemPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _listingCardInner(c, post),
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.favorite_border, size: 15, color: c.onSurfaceMuted),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => context.push('/pass-items/${post.id}/chat'),
                  child: Text(
                    '${post.interestedCount} khách quan tâm',
                    style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                if (post.buyerTransportBooked) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Khách đã đặt xe', style: TextStyle(fontSize: 10, color: c.primary, fontWeight: FontWeight.w700)),
                  ),
                ] else if (post.dealConfirmed) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.success.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Đã chốt', style: TextStyle(fontSize: 10, color: c.success, fontWeight: FontWeight.w700)),
                  ),
                ] else ...[
                  const SizedBox(width: 6),
                  Text('· chốt đơn trong chat', style: TextStyle(fontSize: 11, color: c.onSurfaceMuted)),
                ],
                const Spacer(),
                _statusBadge(c, post.status),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: c.onSurfaceMuted),
                  onSelected: (action) async {
                    if (action == 'bump') {
                      _bumpListing(post);
                    } else {
                      final s = {
                        'reserved': PassItemStatus.reserved,
                        'completed': PassItemStatus.completed,
                        'hidden': PassItemStatus.hidden,
                        'open': PassItemStatus.open,
                      }[action];
                      if (s != null) { await _repo.updateStatus(post.id, s); _load(); }
                    }
                  },
                  itemBuilder: (_) => [
                    if (post.status == PassItemStatus.open || post.status == PassItemStatus.reserved)
                      const PopupMenuItem(
                        value: 'bump',
                        child: Row(children: [
                          Icon(Icons.rocket_launch_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Đẩy tin lên đầu'),
                        ]),
                      ),
                    const PopupMenuItem(value: 'reserved', child: Text('Đang chờ chốt đơn')),
                    const PopupMenuItem(value: 'completed', child: Text('Đã hoàn tất giao dịch')),
                    const PopupMenuItem(value: 'hidden', child: Text('Ẩn tin đăng')),
                    const PopupMenuItem(value: 'open', child: Text('Đăng lại tin')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listingCardInner(UniMoveColors c, PassItemPost post) {
    return InkWell(
      onTap: () async {
        await context.push('/pass-items/${post.id}');
        _load();
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            PassItemImage(
              imageUrl: post.imageUrl,
              width: 72,
              height: 72,
              borderRadius: BorderRadius.circular(12),
              errorPlaceholder: Container(
                width: 72,
                height: 72,
                color: c.surfaceTint,
                child: Icon(Icons.inventory_2_outlined, color: c.onSurfaceMuted),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.onSurface)),
                  const SizedBox(height: 4),
                  Text(passItemPriceLabel(post),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: post.isFree ? c.success : c.primary)),
                  const SizedBox(height: 4),
                  Text('${post.category} · ${passItemTimeAgo(post.createdAt)}',
                      style: TextStyle(fontSize: 12, color: c.onSurfaceMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(UniMoveColors c, PassItemStatus status) {
    final tint = switch (status) {
      PassItemStatus.open => c.primary,
      PassItemStatus.reserved => c.primaryLight,
      PassItemStatus.completed => c.success,
      PassItemStatus.hidden => c.onSurfaceMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(status.label, style: TextStyle(color: tint, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Future<void> _bumpListing(PassItemPost post) async {
    final err = await _repo.bumpListing(post.id);
    if (!mounted) return;
    if (err != null) {
      final msg = err.contains('too_many_requests') || err.contains('24h')
          ? 'Chỉ được đẩy tin 1 lần / 24 giờ'
          : 'Không thể đẩy tin lúc này';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚀 Đã đẩy tin lên đầu!')),
      );
      _load();
    }
  }

  Widget _empty(UniMoveColors c, String text) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.inventory_2_outlined, size: 40, color: c.onSurfaceMuted),
        const SizedBox(height: 12),
        Center(child: Text(text, style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
