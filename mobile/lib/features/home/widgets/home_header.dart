import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_tokens.dart';

const _bellSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="#1A2921" stroke-width="1.7" '
    'stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/>'
    '<path d="M10 21h4"/></svg>';

/// Prototype `.h-header`: greeting / name / subtitle plus the notifications
/// bell. [name] is prototype `S.profileName`; empty falls back to "there".
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'there' : name;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Good morning ',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      color: HomeTokens.greeting,
                    ),
                  ),
                  Text(
                    '☀',
                    style: AppTextStyles.dmSans(
                      size: 12,
                      color: HomeTokens.sun,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Hi, $displayName ',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.manrope(
                        size: 21,
                        weight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.65,
                        color: HomeTokens.ink,
                      ),
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Make the most of your wardrobe today.',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: HomeTokens.subtitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _Bell(onTap: () => context.push(AppRoutes.notifications)),
      ],
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'View notifications',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: HomeTokens.bellBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SvgPicture.string(_bellSvg, width: 20, height: 20),
              Positioned(
                right: -1,
                top: -2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: HomeTokens.bellDot,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
