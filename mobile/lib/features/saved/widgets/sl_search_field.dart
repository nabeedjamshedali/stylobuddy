import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../saved_tokens.dart';

/// Prototype `.sl-search`: search icon + input, placeholder depends on tab.
class SlSearchField extends StatelessWidget {
  const SlSearchField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onChanged,
  });

  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 41,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: SavedTokens.searchBg,
        border: Border.all(color: SavedTokens.searchBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            '⌕',
            style: AppTextStyles.dmSans(size: 23, color: SavedTokens.searchIcon),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextFormField(
              key: ValueKey('sl-search-${value.isEmpty}'),
              initialValue: value,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              style: AppTextStyles.dmSans(size: 11, color: SavedTokens.searchInk),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: AppTextStyles.dmSans(
                  size: 11,
                  color: SavedTokens.searchIcon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
