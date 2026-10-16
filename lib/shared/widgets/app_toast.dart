import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

/// Prototype `toast()`: dark pill at the bottom, replaced by the next toast,
/// removed after 2200 ms.
abstract final class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, String message) {
    _dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(builder: (_) => _ToastView(message));
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 2200), _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
    entry?.dispose();
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 25 + MediaQuery.viewPaddingOf(context).bottom,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: SharedTokens.toastBg,
            elevation: 8,
            shadowColor: SharedTokens.toastShadow,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans(size: 12, color: AppColors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
