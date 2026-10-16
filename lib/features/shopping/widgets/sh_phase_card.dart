import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/demo_copy.dart';
import '../shopping_tokens.dart';

/// Prototype `.sh-phase`: PHASE 1 (available) / PHASE 2 (planned) blocks.
class ShPhaseCard extends StatelessWidget {
  const ShPhaseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 21),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ShoppingTokens.phaseBg,
        border: Border.all(color: ShoppingTokens.phaseBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('PHASE 1 · AVAILABLE IN PROTOTYPE'),
          _title('Shop your wardrobe gaps'),
          _body(
            'Save useful item ideas and add purchases to your digital '
            'wardrobe.',
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 15),
            height: 1,
            color: ShoppingTokens.phaseDivider,
          ),
          _label('PHASE 2 · PLANNED'),
          _title('Explore real products'),
          _body(
            'Store availability, product links and prices will be added '
            'later. ${DemoCopy.shPhaseNoLiveProducts}',
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.dmSans(
      size: 9,
      weight: FontWeight.w800,
      color: ShoppingTokens.phaseLabel,
      letterSpacing: 1,
    ),
  );

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Text(
      text,
      style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
    ),
  );

  Widget _body(String text) => Text(
    text,
    style: AppTextStyles.dmSans(
      size: 10,
      color: ShoppingTokens.phaseBody,
      height: 1.55,
    ),
  );
}
