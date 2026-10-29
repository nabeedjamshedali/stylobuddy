import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../app_config_tokens.dart';

/// A one-line app-wide notice under the status bar (F25): maintenance text
/// or the soft update nudge. UI only; the caller supplies the callbacks.
class AppNoticeBanner extends StatelessWidget {
  const AppNoticeBanner({
    super.key,
    required this.message,
    required this.dismissLabel,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
    this.consumeTopInset = true,
  });

  final String message;
  final String dismissLabel;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Only the top-most banner pads for the status bar.
  final bool consumeTopInset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConfigTokens.bannerBackground,
      child: SafeArea(
        top: consumeTopInset,
        bottom: false,
        child: Padding(
          padding: AppConfigTokens.bannerPadding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  maxLines: AppConfigTokens.bannerMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.dmSans(
                    size: AppConfigTokens.bannerTextSize,
                    color: AppConfigTokens.bannerInk,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: AppConfigTokens.bannerGap),
                _BannerAction(label: actionLabel!, onTap: onAction!),
              ],
              _BannerDismiss(label: dismissLabel, onTap: onDismiss),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  const _BannerAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: AppConfigTokens.bannerActionSize,
            weight: FontWeight.w700,
            color: AppConfigTokens.bannerActionInk,
          ),
        ),
      ),
    );
  }
}

class _BannerDismiss extends StatelessWidget {
  const _BannerDismiss({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '✕',
            style: AppTextStyles.dmSans(
              size: AppConfigTokens.bannerDismissSize,
              color: AppConfigTokens.bannerInk,
            ),
          ),
        ),
      ),
    );
  }
}
