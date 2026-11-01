import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-menu,.pf-settings-card`: white bordered card with a thin
/// divider between rows (not after the last one).
class PfCard extends StatelessWidget {
  const PfCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: ProfileTokens.cardBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Container(height: 1, color: ProfileTokens.rowDivider),
          ],
        ],
      ),
    );
  }
}
