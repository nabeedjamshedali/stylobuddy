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
    final isHome = Uri.parse(location).path == AppRoutes.home;
    final router = GoRouter.of(context);
    // Android back: pop real history if any, else leave /home to exit the app
    // and send every other screen to /home first.
    return PopScope(
      canPop: isHome || router.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
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
          Text(glyph,
              style: AppTextStyles.dmSans(size: 20, color: color, height: 1)),
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
