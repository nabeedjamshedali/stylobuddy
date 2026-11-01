import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/option_tile.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/stylist_cubit.dart';
import '../cubit/stylist_state.dart';
import '../widgets/muted_text.dart';
import '../widgets/stylist_page.dart';

/// Prototype `pages.occasion`.
class OccasionView extends StatelessWidget {
  const OccasionView({super.key});

  static const occasions = [
    'Everyday',
    'Office',
    'Wedding',
    'Date Night',
    'Casual Day Out',
    'Party',
    'Interview',
    'Vacation',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StylistCubit, StylistState>(
      buildWhen: (a, b) => a.occasion != b.occasion,
      builder: (context, state) {
        return StylistPage(
          children: [
            const ScreenHead(
              title: 'Select Occasion',
              fallbackRoute: AppRoutes.stylist,
            ),
            const MutedText(
              'Where are you going? We will style you with your own clothes.',
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < occasions.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              OptionTile(
                label: occasions[i],
                selected: state.occasion == occasions[i],
                onTap: () =>
                    context.read<StylistCubit>().setOccasion(occasions[i]),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Next →',
              onPressed: () => context.push(AppRoutes.stylingOptions),
            ),
          ],
        );
      },
    );
  }
}
