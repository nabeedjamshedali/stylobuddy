import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/trip.dart';
import '../packing_format.dart';
import '../packing_tokens.dart';
import 'pk_progress_bar.dart';

/// Prototype `pkListCard`: a trip row on `/packing`.
class PkTripCard extends StatelessWidget {
  const PkTripCard({super.key, required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final packed = trip.items.where((i) => i.packed).length;
    final total = trip.items.length;
    final percent = total == 0 ? 0.0 : packed / total;
    final meta = trip.destination.isNotEmpty ? trip.destination : trip.type;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: PackingTokens.tripBorder),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 43,
                height: 53,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PackingTokens.tripIconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '✈',
                  style: AppTextStyles.dmSans(
                    size: 20,
                    color: PackingTokens.tripIconInk,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$meta · ${pkDateLabel(trip.start)} – '
                      '${pkDateLabel(trip.end)}',
                      style: AppTextStyles.dmSans(
                        size: 9,
                        color: PackingTokens.tripMeta,
                      ),
                    ),
                    const SizedBox(height: 5),
                    PkProgressBar(value: percent),
                    const SizedBox(height: 5),
                    Text(
                      '$packed of $total packed',
                      style: AppTextStyles.dmSans(
                        size: 9,
                        color: PackingTokens.tripMeta,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '›',
                style: AppTextStyles.dmSans(
                  size: 22,
                  color: PackingTokens.chevron,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
