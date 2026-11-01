import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-info`: trip name with a dates/days line underneath.
class PkInfoCard extends StatelessWidget {
  const PkInfoCard({super.key, required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        border: Border.all(color: PackingTokens.infoBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: AppTextStyles.dmSans(size: 10, color: PackingTokens.infoSub),
          ),
        ],
      ),
    );
  }
}
