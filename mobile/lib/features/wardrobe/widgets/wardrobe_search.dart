import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../wardrobe_tokens.dart';

/// Prototype `.w-search`: search icon, input and the `⌘ F` hint.
class WardrobeSearchField extends StatelessWidget {
  const WardrobeSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: WardrobeTokens.searchBg,
        border: Border.all(color: WardrobeTokens.searchBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Text(
            '⌕',
            style: AppTextStyles.dmSans(size: 15, color: WardrobeTokens.searchIcon),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextFormField(
              // Rebuilt (not just updated) whenever the search is cleared
              // externally (e.g. by "Clear search"), so the field's own text
              // actually resets instead of keeping stale `initialValue`.
              key: ValueKey('wardrobe-search-${value.isEmpty}'),
              initialValue: value,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              style: AppTextStyles.dmSans(
                size: 11,
                color: WardrobeTokens.searchInk,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search by item name...',
                hintStyle: AppTextStyles.dmSans(
                  size: 11,
                  color: WardrobeTokens.searchIcon,
                ),
              ),
            ),
          ),
          Text(
            '⌘ F',
            style: AppTextStyles.dmSans(
              size: 9,
              color: WardrobeTokens.searchShortcut,
            ),
          ),
        ],
      ),
    );
  }
}
