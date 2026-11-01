import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/shop_entry.dart';
import '../shopping_tokens.dart';
import 'sh_art.dart';

/// Prototype `shopCard`: art tile left, tag/title/tone/link body right.
class ShSuggestionCard extends StatelessWidget {
  const ShSuggestionCard({super.key, required this.entry, required this.onTap});

  final ShopEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 137,
          decoration: BoxDecoration(
            border: Border.all(color: ShoppingTokens.suggestionBorder),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 113, child: ShArt(id: entry.id)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.tag,
                        style: AppTextStyles.dmSans(
                          size: 9,
                          weight: FontWeight.w700,
                          color: ShoppingTokens.kicker,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        entry.title,
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        entry.tone,
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: ShoppingTokens.cardTone,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explore suggestion →',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: ShoppingTokens.cardLink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
