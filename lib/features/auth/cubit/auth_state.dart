/// Outcome of a demo submit. [failure] means "stay on the screen".
enum AuthResult { success, failure }

/// Form fields that can be flagged invalid.
enum AuthFieldName { name, email, password, confirm }

/// The auth forms that own transient error state.
enum AuthForm { login, signup, forgot }

class AuthState {
  const AuthState({
    this.email = '',
    this.form,
    this.error,
    this.invalidFields = const {},
  });

  /// Email entered on the last successful submit; empty when none yet.
  final String email;

  /// Which form [error]/[invalidFields] belong to; null when none.
  final AuthForm? form;

  /// Inline form error, null when hidden.
  final String? error;

  /// Fields that blocked the last submit (red border, no message).
  final Set<AuthFieldName> invalidFields;

  /// Error text for [target]; other screens never see it.
  String? errorFor(AuthForm target) => form == target ? error : null;

  bool isInvalid(AuthForm target, AuthFieldName field) =>
      form == target && invalidFields.contains(field);

  AuthState copyWith({
    String? email,
    AuthForm? form,
    String? error,
    bool clearError = false,
    Set<AuthFieldName>? invalidFields,
  }) => AuthState(
    email: email ?? this.email,
    form: form ?? this.form,
    error: clearError ? null : (error ?? this.error),
    invalidFields: invalidFields ?? this.invalidFields,
  );
}
