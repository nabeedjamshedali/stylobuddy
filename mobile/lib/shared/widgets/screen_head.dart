import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

/// Prototype `.screen-head`: back button, centered title, 31px trailing slot.
class ScreenHead extends StatelessWidget {
  const ScreenHead({
    super.key,
    required this.title,
    required this.fallbackRoute,
    this.action,
  });

  final String title;
  final String fallbackRoute;
  final Widget? action;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 31),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Material(
                color: SharedTokens.headButtonBg,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => _back(context),
                  child: SizedBox(
                    width: 31,
                    height: 31,
                    child: Center(
                      child: Text(
                        '‹',
                        style: AppTextStyles.dmSans(
                          size: 20,
                          color: SharedTokens.headButtonInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 9),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 31),
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: 1,
              child: action,
            ),
          ),
        ],
      ),
    );
  }
}
