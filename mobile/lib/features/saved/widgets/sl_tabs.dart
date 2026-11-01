import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../saved_tokens.dart';

/// Prototype `.sl-tabs`: 'Saved Looks' / 'Wear History'.
class SlTabs extends StatelessWidget {
  const SlTabs({super.key, required this.tab, required this.onSelect});

  final String tab;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SavedTokens.tabsBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Saved Looks',
              active: tab == 'Saved',
              onTap: () => onSelect('Saved'),
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Wear History',
              active: tab == 'History',
              onTap: () => onSelect('History'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? SavedTokens.tabActiveBorder : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w600,
            color: active ? SavedTokens.tabActive : SavedTokens.tabInactive,
          ),
        ),
      ),
    );
  }
}
