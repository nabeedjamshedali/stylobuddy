import 'package:flutter/material.dart';

import '../packing_tokens.dart';

/// Prototype `.pk-trip-progress`/`.pk-progress`: `value` is 0..1. Packing's
/// own fill (`#087f62`) differs from the shared `AppProgressBar`'s.
class PkProgressBar extends StatelessWidget {
  const PkProgressBar({super.key, required this.value, this.height = 5});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: PackingTokens.progressTrack,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: PackingTokens.progressFill,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
