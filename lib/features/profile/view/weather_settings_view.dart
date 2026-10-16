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
import '../widgets/pf_choice_grid.dart';
import '../widgets/pf_form_intro.dart';
import '../widgets/pf_helper_text.dart';
import '../widgets/pf_section_title.dart';
import '../widgets/pf_toggle_row.dart';

/// Prototype `pages['weather-settings']`, `P/app.js:279`.
class WeatherSettingsView extends StatelessWidget {
  const WeatherSettingsView({super.key});

  static const climateOptions = ['Warm', 'Mild', 'Cool', 'Cold'];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final state = context.watch<ProfileCubit>().state;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Weather & Location',
            fallbackRoute: AppRoutes.settings,
          ),
          const PfFormIntro(
            title: 'Dress for your day.',
            body:
                'Use optional weather context to make outfit ideas more '
                'practical.',
          ),
          PfCard(
            children: [
              PfToggleRow(
                label: 'Use local weather',
                description:
                    'Only when permission and a forecast are available',
                value: state.weatherConsent,
                onChanged: cubit.setWeatherConsent,
              ),
            ],
          ),
          const PfSectionTitle('FALLBACK CLIMATE'),
          PfChoiceGrid(
            options: climateOptions,
            isSelected: (o) => state.climate == o,
            onTap: cubit.setClimate,
          ),
          const PfHelperText(DemoCopy.weatherHelper),
          PrimaryButton(
            label: 'Save settings',
            onPressed: () {
              context.go(AppRoutes.settings);
              AppToast.show(context, 'Weather settings saved');
            },
          ),
        ],
      ),
    );
  }
}
