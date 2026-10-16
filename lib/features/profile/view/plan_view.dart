import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/pf_form_intro.dart';
import '../widgets/pf_plan_card.dart';
import '../widgets/pf_warning_box.dart';

/// Prototype `pages.plan`, `P/app.js:285`.
class PlanView extends StatelessWidget {
  const PlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final cycle = context.watch<ProfileCubit>().state.billingCycle;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Choose a Plan',
            fallbackRoute: AppRoutes.premium,
          ),
          const PfFormIntro(
            title: 'Choose your rhythm.',
            body:
                'These are illustrative plan periods; prices have not '
                'been approved.',
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PfPlanCard(
                    title: 'Monthly',
                    subtitle: 'Pay month to month',
                    selected: cycle == 'monthly',
                    onTap: () => cubit.setBillingCycle('monthly'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: PfPlanCard(
                    title: 'Yearly',
                    subtitle: 'A longer-term option',
                    selected: cycle == 'yearly',
                    onTap: () => cubit.setBillingCycle('yearly'),
                  ),
                ),
              ],
            ),
          ),
          const PfWarningBox(
            'No purchase is available in this prototype. Final plans depend '
            'on AI operating costs.',
          ),
          PrimaryButton(
            label: 'Continue · Preview only',
            onPressed: () => context.push(AppRoutes.purchase),
          ),
        ],
      ),
    );
  }
}
