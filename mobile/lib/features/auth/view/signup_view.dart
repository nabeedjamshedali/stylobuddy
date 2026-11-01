import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../auth_tokens.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_link.dart';

/// Prototype `pages.signup`. Demo only: does not write the profile.
class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuthCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => cubit.resetForm());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final result = context.read<AuthCubit>().submitSignup(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      confirm: _confirm.text,
    );
    if (result == AuthResult.success) context.push(AppRoutes.verifyEmail);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      backRoute: AppRoutes.auth,
      title: 'Create your account.',
      subtitle:
          'Save your wardrobe, discover outfits, and keep everything in one place.',
      foot: AuthFoot(
        text: 'Already have an account?',
        linkLabel: 'Sign in',
        onLink: () => context.go(AppRoutes.login),
      ),
      children: [
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Full name',
                controller: _name,
                placeholder: 'Your name',
                invalid: state.isInvalid(AuthForm.signup, AuthFieldName.name),
                onChanged: () =>
                    context.read<AuthCubit>().clearInvalid(AuthFieldName.name),
              ),
              const SizedBox(height: 15),
              AuthField(
                label: 'Email address',
                controller: _email,
                placeholder: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                invalid: state.isInvalid(AuthForm.signup, AuthFieldName.email),
                onChanged: () =>
                    context.read<AuthCubit>().clearInvalid(AuthFieldName.email),
              ),
              const SizedBox(height: 15),
              AuthField(
                label: 'Password',
                controller: _password,
                placeholder: 'At least 8 characters',
                isPassword: true,
                invalid: state.isInvalid(
                  AuthForm.signup,
                  AuthFieldName.password,
                ),
                onChanged: () => context.read<AuthCubit>().clearInvalid(
                  AuthFieldName.password,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2, bottom: 12),
                child: Text(
                  'Use 8 or more characters for a secure password.',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: AuthTokens.helper,
                  ),
                ),
              ),
              AuthField(
                label: 'Confirm password',
                controller: _confirm,
                placeholder: 'Repeat your password',
                isPassword: true,
                invalid: state.isInvalid(
                  AuthForm.signup,
                  AuthFieldName.confirm,
                ),
                onChanged: () => context.read<AuthCubit>().clearInvalid(
                  AuthFieldName.confirm,
                ),
              ),
              if (state.errorFor(AuthForm.signup) != null) ...[
                const SizedBox(height: 15),
                AuthErrorText(state.errorFor(AuthForm.signup)),
              ],
              AuthSubmitButton(
                label: 'Create account',
                topMargin: 21,
                onPressed: _submit,
              ),
              const SizedBox(height: 15),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 290),
                  child: Text(
                    'By continuing, you agree to the Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.dmSans(
                      size: 9.4,
                      height: 1.55,
                      color: AuthTokens.legal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
