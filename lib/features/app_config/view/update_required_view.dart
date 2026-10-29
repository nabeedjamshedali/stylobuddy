import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../app_config_tokens.dart';
import '../cubit/app_config_cubit.dart';
import '../cubit/app_config_state.dart';

/// Blocking full-screen "Update required" (F25 §2.3). Rendered by
/// `AppConfigGate` in place of the whole app; it has no close, back, skip or
/// later control.
class UpdateRequiredView extends StatelessWidget {
  const UpdateRequiredView({super.key});

  static const title = 'Update required';
  static const body =
      'This version of StyloBuddy is no longer supported. '
      'Update to the latest version to keep using the app.';
  static const buttonLabel = 'Update now';
  static const storeError =
      "Couldn't open Google Play. Please update StyloBuddy from the Play Store.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('update-required-view'),
      backgroundColor: AppConfigTokens.updateBackground,
      body: SafeArea(
        child: Padding(
          padding: AppConfigTokens.updatePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: Alignment.centerLeft, child: BrandMark()),
              const Spacer(),
              const _UpdateCopy(),
              const SizedBox(height: AppConfigTokens.updateGapLarge),
              PrimaryButton(
                label: buttonLabel,
                onPressed: () => context.read<AppConfigCubit>().openStore(),
              ),
              const _StoreErrorLine(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateCopy extends StatelessWidget {
  const _UpdateCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UpdateRequiredView.title,
          style: AppTextStyles.manrope(size: AppConfigTokens.updateTitleSize),
        ),
        const SizedBox(height: AppConfigTokens.updateGapSmall),
        Text(
          UpdateRequiredView.body,
          style: AppTextStyles.dmSans(
            size: AppConfigTokens.updateBodySize,
            color: AppConfigTokens.updateBodyInk,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _StoreErrorLine extends StatelessWidget {
  const _StoreErrorLine();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppConfigCubit, AppConfigState, bool>(
      selector: (state) => state.storeLaunchFailed,
      builder: (context, failed) => failed
          ? Padding(
              padding: const EdgeInsets.only(
                top: AppConfigTokens.updateGapSmall,
              ),
              child: Text(
                UpdateRequiredView.storeError,
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans(
                  size: AppConfigTokens.updateErrorSize,
                  color: AppConfigTokens.updateErrorInk,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
