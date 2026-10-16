import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';

/// Editorial photograph from `assets/onboarding/`.
class ObPhoto extends StatelessWidget {
  const ObPhoto({
    super.key,
    required this.file,
    this.alignment = Alignment.center,
  });

  final String file;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.onboarding(file),
      fit: BoxFit.contain,
      alignment: alignment,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
