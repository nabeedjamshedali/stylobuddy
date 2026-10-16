import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../../shared/widgets/select_field.dart';
import '../cubit/stylist_cubit.dart';
import '../cubit/stylist_state.dart';
import '../widgets/muted_text.dart';
import '../widgets/pref_notice.dart';
import '../widgets/stylist_page.dart';

/// Prototype `pages['styling-options']`.
class StylingOptionsView extends StatelessWidget {
  const StylingOptionsView({super.key});

  static const directions = [
    'Smart casual',
    'Relaxed minimal',
    'Classic and timeless',
    'Trendy and bold',
    'Elegant',
  ];
  static const weathers = [
    'Mild / all season',
    'Warm weather',
    'Cool weather',
    'Rainy weather',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StylistCubit, StylistState>(
      buildWhen: (a, b) =>
          a.styleDirection != b.styleDirection || a.weather != b.weather,
      builder: (context, state) {
        final cubit = context.read<StylistCubit>();
        return StylistPage(
          children: [
            const ScreenHead(
              title: 'Your Styling Preferences',
              fallbackRoute: AppRoutes.occasion,
            ),
            const MutedText(
              'A few details help us tailor your outfit suggestions.',
            ),
            SelectField(
              label: 'Style direction',
              options: directions,
              value: state.styleDirection,
              onChanged: cubit.setStyleDirection,
            ),
            SelectField(
              label: 'Weather',
              options: weathers,
              value: state.weather,
              onChanged: cubit.setWeather,
            ),
            const PrefNotice(
              'Your owned wardrobe items are the only garments used in results.',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Generate 3 looks ✧',
              onPressed: () {
                cubit.generateAutomatic();
                context.push(AppRoutes.generating);
              },
            ),
          ],
        );
      },
    );
  }
}
