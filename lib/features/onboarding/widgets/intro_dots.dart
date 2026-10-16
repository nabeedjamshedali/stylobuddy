import 'package:flutter/material.dart';

import '../onboarding_tokens.dart';

/// Prototype `.ob-dots`: five dots, the active one larger and green.
class IntroDots extends StatelessWidget {
  const IntroDots({super.key, required this.active, this.count = 5});

  final int active;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 7),
            _Dot(active: i == active),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final size = active ? 6.0 : 5.0;
    return Container(
      key: Key(active ? 'intro-dot-active' : 'intro-dot'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? OnboardingTokens.dotActive : OnboardingTokens.dot,
      ),
    );
  }
}
