import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../auth_tokens.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/provider_button.dart';

/// Prototype `pages.auth`: provider chooser (all providers are previews).
class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: BrandMark(fontSize: 23),
              ),
              const Expanded(child: _Copy()),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                child: _Actions(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            constraints.maxHeight > 240 ? 120 : 85,
            28,
            0,
          ),
          child: Column(
            children: [
              Text(
                'Create your wardrobe.',
                textAlign: TextAlign.center,
                style: AppTextStyles.manrope(
                  size: 22,
                  weight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: -.5,
                  color: AuthTokens.chooserTitle,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 255),
                child: Text(
                  'Sign in to save your clothes, get personalized outfit suggestions, and keep your style synced across devices.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(
                    size: 11,
                    height: 1.7,
                    color: AuthTokens.chooserBody,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.googleError != current.googleError &&
          current.googleError != null,
      listener: (context, state) =>
          AppToast.show(context, state.googleError!),
      builder: (context, state) => Column(
        children: [
          ProviderButton(
            glyph: 'G',
            glyphColor: AuthTokens.google,
            label: state.isGoogleSigningIn
                ? 'Signing in…'
                : 'Continue with Google',
            onTap: state.isGoogleSigningIn
                ? () {}
                : () async {
                    final result = await context
                        .read<AuthCubit>()
                        .signInWithGoogle();
                    if (result == AuthResult.success && context.mounted) {
                      context.go(AppRoutes.home);
                    }
                  },
          ),
          ProviderButton(
            glyph: '',
            label: 'Continue with Apple',
            onTap: () =>
                AppToast.show(context, 'Apple authentication UI preview'),
          ),
          ProviderButton(
            glyph: '✉',
            label: 'Continue with Email',
            onTap: () => context.push(AppRoutes.login),
          ),
          const OrDivider(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go(AppRoutes.home),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Skip for now',
                style: AppTextStyles.dmSans(
                  size: 12,
                  color: AuthTokens.skipInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
