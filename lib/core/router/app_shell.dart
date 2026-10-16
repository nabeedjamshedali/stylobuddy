import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/shared_tokens.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_routes.dart';

/// White scaffold with the prototype `.bottom-nav` (5 tabs).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (route: AppRoutes.home, glyph: '⌂', label: 'Home'),
    (route: AppRoutes.wardrobe, glyph: '▦', label: 'Wardrobe'),
    (route: AppRoutes.stylist, glyph: '✧', label: 'AI Stylist'),
    (route: AppRoutes.saved, glyph: '♡', label: 'Saved'),
    (route: AppRoutes.profile, glyph: '♙', label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final current = AppRoutes.tabFor(location);
    final path = Uri.parse(location).path;
    // Android back is intercepted whenever we're not on /home and the inner
    // Navigator has nothing left to pop. That covers both a tab root (e.g.
    // /wardrobe, reached by tapping a tab -> go home) and a non-tab-root
    // screen left as the sole entry in its stack after a flow-reset
    // `context.go` (e.g. edit_item_view -> /clothing) -> go that path's tab
    // root instead of letting the app exit. Drill-down screens reached via
    // `context.push` still have something to pop and are left alone.
    final interceptBack =
        path != AppRoutes.home && !Navigator.of(context).canPop();
    // A tab root (tabFor(path) == path) falls back to /home, same as
    // before. Any other stranded screen (e.g. left there by a flow-reset
    // `context.go`) falls back to its own tab root instead.
    final tabRoot = AppRoutes.tabFor(path);
    final fallback = tabRoot == path ? AppRoutes.home : tabRoot;
    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(fallback);
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(bottom: false, child: child),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(5, 8, 5, 2),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: SharedTokens.navBorder)),
            ),
            child: Row(
              children: [
                for (final tab in _tabs)
                  Expanded(
                    child: _NavItem(
                      glyph: tab.glyph,
                      label: tab.label,
                      current: tab.route == current,
                      onTap: () => context.go(tab.route),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.glyph,
    required this.label,
    required this.current,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = current ? AppColors.green : SharedTokens.navInactive;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            glyph,
            style: AppTextStyles.dmSans(size: 20, color: color, height: 1),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9,
              color: color,
              weight: current ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
