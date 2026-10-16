import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_text_link.dart';

/// Prototype `pages.forgot`.
class ForgotView extends StatefulWidget {
  const ForgotView({super.key});

  @override
  State<ForgotView> createState() => _ForgotViewState();
}

class _ForgotViewState extends State<ForgotView> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final result = context.read<AuthCubit>().submitForgot(email: _email.text);
    if (result == AuthResult.success) context.push(AppRoutes.resetSent);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      backRoute: AppRoutes.login,
      title: 'Reset your password.',
      subtitle:
          'Enter your email and we’ll help you get back into your account.',
      foot: AuthFoot(
        text: 'Remembered it?',
        linkLabel: 'Back to sign in',
        onLink: () => context.go(AppRoutes.login),
      ),
      children: [
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Email address',
                controller: _email,
                placeholder: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                invalid: state.invalidFields.contains(AuthFieldName.email),
              ),
              AuthSubmitButton(
                label: 'Send reset link',
                topMargin: 21,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
