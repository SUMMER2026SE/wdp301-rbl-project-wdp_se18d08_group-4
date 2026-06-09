import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../../../core/widgets/theme_toggle_tile.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../orders/presentation/providers/orders_providers.dart';

class ProviderProfileTabPage extends ConsumerWidget {
  const ProviderProfileTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(providerProfileProvider);
    final ordersAsync = ref.watch(providerOrdersListProvider);
    final completedCount = ordersAsync.maybeWhen(
      data: (orders) => orders.where((o) => o.isCompleted).length,
      orElse: () => 0,
    );
    final c = UniMoveColors.of(context);

    return ShadScreenScope(
      builder: (_, theme) {
        return profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (profile) {
            final name = profile?.fullName ?? '';
            final email = profile?.email ?? '';
            final business = profile?.businessName ?? '';
            final rating = profile?.rating ?? 0.0;
            final verified = profile?.isVerified ?? false;
            final initial =
                name.isNotEmpty ? name[0].toUpperCase() : 'P';

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // ---- Hero Banner ----
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Gradient background
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [c.primary, c.primaryLight],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            top: -30,
                            right: -20,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: -10,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar with ring
                    Positioned(
                      bottom: -44,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [c.primary, c.primaryLight],
                          ),
                        ),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.surface,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    c.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: theme.textTheme.h2.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Space for avatar overflow
                const SizedBox(height: 56),

                // Name + badge
                Column(
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.h3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: c.onSurface,
                      ),
                    ),
                    if (business.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          business,
                          style: theme.textTheme.small
                              .copyWith(color: c.onSurfaceMuted),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: theme.textTheme.small
                          .copyWith(color: c.onSurfaceMuted),
                    ),
                    const SizedBox(height: 8),
                    if (verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.accentGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: c.accentGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.badgeCheck,
                                size: 14, color: c.success),
                            const SizedBox(width: 5),
                            Text(
                              'Đã xác thực',
                              style: theme.textTheme.small.copyWith(
                                color: c.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: LucideIcons.star,
                          value: '$rating',
                          label: 'Đánh giá',
                          tint: const Color(0xFFF59E0B),
                          colors: c,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: LucideIcons.circleCheck,
                          value: '$completedCount',
                          label: 'Hoàn thành',
                          tint: c.success,
                          colors: c,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: LucideIcons.truck,
                          value: 'Pro',
                          label: 'Cấp độ',
                          tint: c.primary,
                          colors: c,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu section: Cài đặt
                _SectionHeader(title: 'Tài khoản', theme: theme, c: c),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const ThemeToggleTile(),
                      const SizedBox(height: 8),
                      _MenuTile(
                        icon: LucideIcons.fileUp,
                        title: 'Giấy tờ & xác thực',
                        subtitle: '2/4 đã xác thực',
                        onTap: () => context.push('/documents'),
                        c: c,
                        theme: theme,
                      ),
                      _MenuTile(
                        icon: LucideIcons.calendarClock,
                        title: 'Lịch trực',
                        onTap: () => context.push('/schedule'),
                        c: c,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Menu section: Hỗ trợ
                _SectionHeader(title: 'Hỗ trợ', theme: theme, c: c),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _MenuTile(
                        icon: LucideIcons.bell,
                        title: 'Thông báo',
                        subtitle: 'Sắp có',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Cài đặt thông báo — sắp có')),
                        ),
                        c: c,
                        theme: theme,
                      ),
                      _MenuTile(
                        icon: LucideIcons.helpCircle,
                        title: 'Hỗ trợ đối tác',
                        subtitle: 'Hotline: 1900 1234',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Hotline hỗ trợ đối tác: 1900 1234')),
                        ),
                        c: c,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ShadButton.destructive(
                    width: double.infinity,
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.logOut, size: 16),
                        SizedBox(width: 8),
                        Text('Đăng xuất'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final UniMoveColors colors;
  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      radius: 16,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.large.copyWith(
              fontWeight: FontWeight.w800,
              color: c.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: c.onSurfaceMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.theme,
    required this.c,
  });

  final String title;
  final ShadThemeData theme;
  final UniMoveColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.small.copyWith(
              color: c.onSurfaceMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: c.border, height: 1)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.c,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final UniMoveColors c;
  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            radius: 16,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.iconBgSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: c.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.small
                              .copyWith(color: c.onSurfaceMuted),
                        ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight,
                    color: c.onSurfaceMuted, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
