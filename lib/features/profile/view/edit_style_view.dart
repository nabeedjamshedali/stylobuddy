import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/pf_choice_grid.dart';
import '../widgets/pf_form_intro.dart';
import '../widgets/pf_section_title.dart';

/// Prototype `pages['edit-style']` + `togglePreference()`, `P/app.js:275-276`.
class EditStyleView extends StatelessWidget {
  const EditStyleView({super.key});

  static const styleOptions = [
    'Minimal',
    'Smart casual',
    'Classic',
    'Streetwear',
    'Elegant',
    'Bold',
  ];
  static const occasionOptions = [
    'Everyday',
    'Office',
    'Wedding',
    'Date Night',
    'Party',
    'Travel',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final state = context.watch<ProfileCubit>().state;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(title: 'Your Style', fallbackRoute: AppRoutes.profile),
          const PfFormIntro(
            title: 'What feels like you?',
            body: 'Pick your favorite styles and the occasions you dress for.',
          ),
          const PfSectionTitle('PERSONAL STYLE'),
          PfChoiceGrid(
            options: styleOptions,
            isSelected: (o) => state.styles.contains(o),
            onTap: (o) => cubit.togglePreference(PreferenceField.styles, o),
          ),
          const PfSectionTitle('YOUR OCCASIONS'),
          PfChoiceGrid(
            options: occasionOptions,
            isSelected: (o) => state.occasions.contains(o),
            onTap: (o) => cubit.togglePreference(PreferenceField.occasions, o),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save preferences',
            onPressed: () {
              context.go(AppRoutes.profile);
              AppToast.show(context, 'Preferences saved');
            },
          ),
        ],
      ),
    );
  }
}
