import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../stylist/cubit/stylist_cubit.dart';
import '../widgets/matching_page.dart';
import '../widgets/mm_intro.dart';

/// Prototype `pages.matching`: the Match My Clothes intro screen.
class MatchingView extends StatelessWidget {
  const MatchingView({super.key});

  @override
  Widget build(BuildContext context) {
    return MatchingPage(
      children: [
        const ScreenHead(
          title: 'Match My Clothes',
          fallbackRoute: AppRoutes.stylist,
        ),
        const MmIntro(),
        const MmSteps(),
        PrimaryButton(
          label: 'Choose from my wardrobe →',
          onPressed: () {
            context.read<StylistCubit>().startMatching();
            context.push(AppRoutes.matchSelect);
          },
        ),
      ],
    );
  }
}
