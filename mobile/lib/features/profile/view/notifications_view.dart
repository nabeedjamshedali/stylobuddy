import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/pf_card.dart';
import '../widgets/pf_form_intro.dart';
import '../widgets/pf_helper_text.dart';
import '../widgets/pf_toggle_row.dart';

/// Prototype `pages.notifications`, `P/app.js:278`.
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final state = context.watch<ProfileCubit>().state;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(title: 'Notifications', fallbackRoute: AppRoutes.settings),
          const PfFormIntro(
            title: 'Stay in the know.',
            body: 'Choose the reminders you want to receive.',
          ),
          PfCard(
            children: [
              PfToggleRow(
                label: 'Daily outfit ideas',
                description: 'A nudge to get dressed with confidence',
                value: state.dailyNotifications,
                onChanged: cubit.setDailyNotifications,
              ),
              PfToggleRow(
                label: 'Planned outfit reminders',
                description: 'Updates for your calendar looks',
                value: state.plannedNotifications,
                onChanged: cubit.setPlannedNotifications,
              ),
              PfToggleRow(
                label: 'Product updates',
                description: 'Occasional news about StyloBuddy',
                value: state.productNotifications,
                onChanged: cubit.setProductNotifications,
              ),
            ],
          ),
          const PfHelperText(
            'System notification permissions will be requested in the real app.',
          ),
          PrimaryButton(
            label: 'Done',
            onPressed: () {
              context.go(AppRoutes.settings);
              AppToast.show(context, 'Notification preferences saved');
            },
          ),
        ],
      ),
    );
  }
}
