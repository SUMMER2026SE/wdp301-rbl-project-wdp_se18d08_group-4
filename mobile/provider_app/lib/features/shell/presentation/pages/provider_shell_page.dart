import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/uni_move_colors.dart';
import '../../../../core/widgets/shad_screen_scope.dart';
import '../../../earnings/presentation/pages/earnings_tab_page.dart';
import '../../../home/presentation/pages/provider_dashboard_page.dart';
import '../../../messages/presentation/pages/messages_tab_page.dart';
import '../../../orders/presentation/pages/orders_inbox_page.dart';
import '../../../profile/presentation/pages/provider_profile_tab_page.dart';

class ProviderShellPage extends StatefulWidget {
  const ProviderShellPage({super.key});

  @override
  State<ProviderShellPage> createState() => _ProviderShellPageState();
}

class _ProviderShellPageState extends State<ProviderShellPage> {
  int _index = 0;

  static const _icons = [
    LucideIcons.layoutDashboard,
    LucideIcons.inbox,
    LucideIcons.wallet,
    LucideIcons.messageCircle,
    LucideIcons.user,
  ];

  static const _labels = [
    'Trang chủ',
    'Đơn hàng',
    'Thu nhập',
    'Tin nhắn',
    'Hồ sơ',
  ];

  Widget _pageAt(int index) {
    return switch (index) {
      0 => const ProviderDashboardPage(),
      1 => const OrdersInboxPage(embedded: true),
      2 => const EarningsTabPage(),
      3 => const MessagesTabPage(),
      4 => const ProviderProfileTabPage(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = UniMoveColors.of(context);

    return ShadScreenScope(
      builder: (_, theme) {
        return Scaffold(
          backgroundColor: c.background,
          body: IndexedStack(
            index: _index,
            children: List.generate(_icons.length, _pageAt),
          ),
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              decoration: BoxDecoration(
                color: c.glassCard,
                border: Border(top: BorderSide(color: c.glassBorder)),
                boxShadow: [
                  BoxShadow(
                    color: c.navBarShadow,
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                  child: Row(
                    children: List.generate(_icons.length, (i) {
                      final active = i == _index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _index = i),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? c.primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _icons[i],
                                  color: active ? c.primary : c.onSurfaceMuted,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.small.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color:
                                      active ? c.primary : c.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Active dot indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: active ? 18 : 0,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
