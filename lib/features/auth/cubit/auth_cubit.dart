import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_state.dart';

/// Demo-only auth: validates like the prototype's `authSubmit` and remembers
/// the entered email. No backend, no email is sent.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  static const shortPasswordError =
      'Use at least 8 characters for your password.';
  static const mismatchError = 'Passwords do not match. Please try again.';

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String value) =>
      _emailPattern.hasMatch(value.trim());

  /// No length rule on login; email and password are only required.
  AuthResult submitLogin({required String email, required String password}) {
    final invalid = <AuthFieldName>{
      if (!isValidEmail(email)) AuthFieldName.email,
      if (password.isEmpty) AuthFieldName.password,
    };
    if (invalid.isNotEmpty) return _block(AuthForm.login, invalid);
    return _accept(email);
  }

  AuthResult submitSignup({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) {
    final invalid = <AuthFieldName>{
      if (name.trim().length < 2) AuthFieldName.name,
      if (!isValidEmail(email)) AuthFieldName.email,
      if (password.isEmpty) AuthFieldName.password,
      if (confirm.isEmpty) AuthFieldName.confirm,
    };
    if (invalid.isNotEmpty) return _block(AuthForm.signup, invalid);
    if (password.length < 8) {
      return _reject(AuthForm.signup, shortPasswordError);
    }
    if (password != confirm) return _reject(AuthForm.signup, mismatchError);
    return _accept(email);
  }

  AuthResult submitForgot({required String email}) {
    if (!isValidEmail(email)) {
      return _block(AuthForm.forgot, {AuthFieldName.email});
    }
    return _accept(email);
  }

  /// Drops transient form state; called when a form screen is entered.
  void resetForm() =>
      emit(state.copyWith(clearError: true, invalidFields: const {}));

  /// The user edited [field]: its red state goes away.
  void clearInvalid(AuthFieldName field) {
    if (!state.invalidFields.contains(field)) return;
    emit(
      state.copyWith(invalidFields: {...state.invalidFields}..remove(field)),
    );
  }

  /// Required-field failure: nothing shown inline except the red border.
  AuthResult _block(AuthForm form, Set<AuthFieldName> invalid) {
    emit(state.copyWith(form: form, clearError: true, invalidFields: invalid));
    return AuthResult.failure;
  }

  AuthResult _reject(AuthForm form, String message) {
    emit(state.copyWith(form: form, error: message, invalidFields: const {}));
    return AuthResult.failure;
  }

  AuthResult _accept(String email) {
    emit(
      state.copyWith(
        email: email.trim(),
        clearError: true,
        invalidFields: const {},
      ),
    );
    return AuthResult.success;
  }
}
