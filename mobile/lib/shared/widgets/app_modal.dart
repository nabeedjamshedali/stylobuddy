import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

/// Prototype `modal()`: centered white card over a green-tinted backdrop.
abstract final class AppModal {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget body,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: SharedTokens.modalBackdrop,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.white,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.dmSans(
                          size: 16,
                          weight: FontWeight.w700,
                          letterSpacing: -.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: SharedTokens.modalClose,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => close(dialogContext),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            '✕',
                            style: AppTextStyles.dmSans(size: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void close(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).pop();
}
