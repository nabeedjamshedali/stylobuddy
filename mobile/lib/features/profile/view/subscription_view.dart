import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/demo_copy.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/pf_card.dart';
import '../widgets/pf_current_plan_card.dart';
import '../widgets/pf_helper_text.dart';
import '../widgets/pf_menu_row.dart';
import '../widgets/pf_section_title.dart';

/// Prototype `pages.subscription`, `P/app.js:287`.
class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<ProfileCubit>().state.plan;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Subscription',
            fallbackRoute: AppRoutes.settings,
          ),
          PfCurrentPlanCard(
            plan: plan,
            onExplore: () => context.push(AppRoutes.premium),
          ),
          const PfSectionTitle('MANAGE'),
          PfCard(
            children: [
              PfMenuRow(
                symbol: '✦',
                title: 'Plan options',
                subtitle: 'Compare planned subscription periods',
                onTap: () => context.push(AppRoutes.plan),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SecondaryButton(
            label: DemoCopy.subscriptionRestoreLabel,
            onPressed: () =>
                AppToast.show(context, DemoCopy.subscriptionRestoreToast),
          ),
          const PfHelperText(DemoCopy.subscriptionHelper),
        ],
      ),
    );
  }
}
