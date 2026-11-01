import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../../shared/widgets/select_field.dart';
import '../../stylist/cubit/stylist_cubit.dart';
import '../../stylist/cubit/stylist_state.dart';
import '../matching_tokens.dart';
import '../widgets/matching_page.dart';
import '../widgets/mm_notes.dart';
import '../widgets/mm_step_heading.dart';

/// Prototype `pages['match-options']`: occasion and accessories (step 3 of 3).
class MatchOptionsView extends StatefulWidget {
  const MatchOptionsView({super.key});

  static const occasions = [
    'Everyday',
    'Office',
    'Wedding',
    'Date Night',
    'Casual',
    'Party',
    'Vacation',
  ];

  @override
  State<MatchOptionsView> createState() => _MatchOptionsViewState();
}

class _MatchOptionsViewState extends State<MatchOptionsView> {
  late String _occasion;
  var _initialized = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StylistCubit, StylistState>(
      builder: (context, state) {
        final cubit = context.read<StylistCubit>();
        if (!_initialized) {
          // Prototype `<select>` fallback: an occasion outside the option
          // list renders as the first option until the user picks one.
          _occasion = MatchOptionsView.occasions.contains(state.occasion)
              ? state.occasion
              : MatchOptionsView.occasions.first;
          _initialized = true;
        }
        final locked = state.locked.length;
        final selected = state.selected.length;
        return MatchingPage(
          children: [
            const ScreenHead(
              title: 'Styling Preferences',
              fallbackRoute: AppRoutes.matchReview,
            ),
            const MmStepHeading(
              step: 'STEP 3 OF 3',
              title: "Let's finish the look.",
              description:
                  'Set the occasion and choose whether to complete your '
                  'looks with shoes and accessories already in your '
                  'wardrobe.',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                border: Border.all(color: MatchingTokens.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectField(
                label: 'Occasion',
                options: MatchOptionsView.occasions,
                value: _occasion,
                onChanged: (v) => setState(() => _occasion = v),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(color: MatchingTokens.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete my outfits',
                          style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use available owned footwear, watches, bags and '
                          'jewelry where suitable.',
                          style: AppTextStyles.dmSans(
                            size: 10,
                            height: 1.5,
                            color: MatchingTokens.toggleCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Switch(
                    value: state.accessories,
                    activeThumbColor: AppColors.green,
                    onChanged: cubit.setAccessories,
                  ),
                ],
              ),
            ),
            MmNote(
              headline: 'Based on $selected selected items',
              body:
                  '$locked must-wear piece${locked == 1 ? '' : 's'} will be '
                  'preserved. We will show up to three different '
                  'combinations, without inventing new clothes.',
            ),
            const SizedBox(height: 11),
            PrimaryButton(
              label: '✧ Find my best matches',
              onPressed: () {
                cubit.setOccasion(_occasion);
                cubit.generateMatches();
                context.push(AppRoutes.matchingProgress);
              },
            ),
          ],
        );
      },
    );
  }
}
