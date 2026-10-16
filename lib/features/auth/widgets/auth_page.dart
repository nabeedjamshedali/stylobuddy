import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../auth_tokens.dart';

/// Prototype `authShell`: back button + brand, overline/title/subtitle, body
/// and a footer pinned to the bottom (`.auth-foot`, margin-top:auto).
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.backRoute,
    required this.title,
    required this.subtitle,
    required this.children,
    this.foot,
  });

  final String backRoute;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? foot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(29, 29, 29, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Top(backRoute: backRoute),
                    _Copy(title: title, subtitle: subtitle),
                    ...children,
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(29, 0, 29, 45),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 19, bottom: 8),
                    child: foot,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Top extends StatelessWidget {
  const _Top({required this.backRoute});

  final String backRoute;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(backRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            button: true,
            label: 'Go back',
            excludeSemantics: true,
            child: GestureDetector(
              key: const Key('auth-back'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _back(context),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AuthTokens.backBorder),
                ),
                child: Text(
                  '←',
                  style: AppTextStyles.dmSans(
                    size: 19,
                    color: AuthTokens.backInk,
                  ),
                ),
              ),
            ),
          ),
          const BrandMark(iconSize: 27, fontSize: 15),
        ],
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 45, 1, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STYLE STARTS HERE',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w700,
              color: AuthTokens.overline,
              letterSpacing: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.manrope(
              size: 29,
              weight: FontWeight.w700,
              height: 1.18,
              letterSpacing: -1.25,
              color: AuthTokens.heading,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              subtitle,
              style: AppTextStyles.dmSans(
                size: 12,
                height: 1.65,
                color: AuthTokens.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
