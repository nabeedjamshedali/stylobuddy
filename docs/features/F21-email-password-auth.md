# F21 — Real Email/Password Auth

> Replaces the demo-only email/password forms (login, signup, forgot) with real
> Firebase Auth calls — `signInWithEmailAndPassword`,
> `createUserWithEmailAndPassword`, `sendPasswordResetEmail` — behind the
> existing `AuthCubit` / `AuthResult` / `AuthState.error` / `invalidFields`
> contract that F02 established. Task 8 of
> `docs/superpowers/plans/2026-10-19-backend-wiring.md`. `AuthRepository` is
> **extended, not replaced**: the Google path (`signInWithGoogle`, `signOut`)
> is untouched. Every client-side validation rule F02 defined still runs first
> and still short-circuits before any network call. Unlike F15-F20 there is no
> dual-mode (in-memory vs Firestore) split here: Firebase Auth is the only auth
> backend, and the guest/signed-in split is already handled downstream by
> F14's `uidChanges()` keyed rebuild in `lib/app.dart`. Depends on F14 (uid
> stream, auth-gated reconstruction) and preserves F02's assertions. Grounded
> in `docs/foundation/07-security.md` §1-2,
> `docs/superpowers/specs/2026-10-19-backend-architecture.md` D3, and
> `docs/superpowers/specs/2026-10-19-firestore-schema.md` §1 (`email`) and §7
> (`AuthState` is transient, never stored).

**Status:** DEFERRED — user decision 2026-10-20: "google auth is fine for now, don't do manually email password login." Task 8 is skipped; this doc is kept for future reference only, not pursued further in the backend-wiring pass. · **Milestone:** 2 · **Depends on:** F14 (preserves F02)

---

## 1. Goal

Let a user create a real StyloBuddy account with an email and password, sign
back into it later (on this or another device), and ask for a real
password-reset email. Today those three forms only validate input locally and
navigate. No credential leaves the device and no account exists afterwards,
so an email user can never reach the Firestore-backed data that Tasks 2-7
wired. Once this ships, a successful email sign-up or sign-in produces a real
Firebase user. F14's existing `uidChanges()` stream then picks that user up
exactly as it picks up a Google user today, and the signed-in, Firestore-backed
subtree is built for them. No new wiring in `lib/app.dart` is needed for that
part (see §5 and §13 Q3).

## 2. MVP scope

- `lib/features/auth/repository/auth_repository.dart`: **additive only**.
  Three new public methods (names proposed in §6), each a thin delegate to the
  already-injected, lazily-resolved `FirebaseAuth`:
  - email sign-in -> `FirebaseAuth.signInWithEmailAndPassword`
  - account creation -> `FirebaseAuth.createUserWithEmailAndPassword`
  - password reset -> `FirebaseAuth.sendPasswordResetEmail`

  Like `signInWithGoogle()`, these methods **throw**: they pass
  `FirebaseAuthException` through unchanged, and throw `StateError` for a
  credential with a null `user`. They never map errors to messages. Mapping
  is the Cubit's job, as it is for Google today. The constructor, the lazy
  `_firebaseAuth` / `_googleSignIn` getters, `currentUser`,
  `signInWithGoogle()` and `signOut()` are byte-for-byte unchanged.
- `lib/features/auth/cubit/auth_cubit.dart`:
  - `submitLogin`, `submitSignup` and `submitForgot` keep their names,
    parameters and **every existing validation rule, in the existing order,
    with the existing error strings** (`shortPasswordError`, `mismatchError`,
    the silent `_block` red-border path). Only once validation passes do they
    call the repository.
  - A successful backend call ends in today's `_accept` shape: `email` set,
    `error` cleared, `invalidFields` emptied, `AuthResult.success` returned.
  - A failed backend call ends in today's `_reject` shape for the submitting
    form: `form` set, `error` set to a fixed user-readable message,
    `invalidFields` emptied, `AuthResult.failure` returned.
  - The catch structure mirrors `signInWithGoogle()`'s: `on
    FirebaseAuthException` -> mapped message, `on StateError` -> generic
    message, catch-all -> generic message. Nothing is rethrown; no crash.
  - The return type changes from `AuthResult` to `Future<AuthResult>`. This
    is unavoidable for network I/O, but it is **not** free. See §13 Q1: it
    forces edits outside `cubit/` and `repository/`.
  - New `static const` error-message strings, one per mapped Firebase error
    group (§6, §10), alongside the existing `shortPasswordError` /
    `mismatchError`.
- `docs/foundation/07-security.md` §1 (and §2's role table, subject to §13
  Q11): updated in this task to say email/password is real, per the plan's
  global constraint that a task updates the foundation docs whose reality it
  changes.
- Firebase project `stylobuddy-b7e46`: the **Email/Password sign-in provider
  must be enabled**. The plan lists only Google as enabled. See §8 and §13
  Q9.

## 3. Later scope

- Email verification: sending `sendEmailVerification` on signup, gating
  anything on `User.emailVerified`, making "Resend verification email" real.
  See §13 Q8.
- Apple sign-in (iOS) — `07-security.md` §1's existing "later" item.
- A production caller for `AuthRepository.signOut()`. Today **no** `lib/`
  code calls it, and Settings' "Sign out" is demo copy. That gap applies
  equally to Google users and is not opened or closed by this task (§13 Q10).
- Flipping `kShowDemoNotes` / rewriting `DemoCopy`'s auth strings ("Signed in
  to demo account", "No email has been sent by this prototype", "Verification
  simulated"). Those are view-facing copy covered by F02's assertions (§13
  Q7).
- Account linking (the same email used with Google and with a password),
  "change password", "delete account".
- Any loading or disabled state on the email submit buttons. A new widget
  would have to read it, and widget changes are frozen (§13 Q12 covers
  double-submit without a widget).
- Firestore rules (Task 9). This task writes nothing to Firestore itself.

## 4. Roles and permissions

These are `docs/foundation/07-security.md` §2's roles.

- **guest**: unchanged. "Skip for now" still enters `/home` with `uid ==
  null` and in-memory repositories, and never touches Firebase.
- **authenticated user**: now reachable by email/password as well as
  Google. Once Firebase reports the user, F14's `uidChanges()` emits their
  uid and every Firestore-backed repository is scoped to `users/<uid>/...`
  (F14-A11). This task adds no new permission surface beyond that.
- **demo user**: today, a successful demo email login. After this task, a
  successful email login is a real authenticated user, so this role's
  meaning changes. Whether the row is removed or reworded is §13 Q11.

No client-side gate is added. Firebase Auth itself decides who can sign in,
and the Firestore rules (Task 9) decide what they can read.

## 5. Main flows

```text
Validation fails (any form) — unchanged from F02, no network:
  view -> AuthCubit.submitX(...) -> existing checks fail ->
     _block (red borders, no text) or _reject (shortPasswordError /
     mismatchError) -> AuthResult.failure
  FirebaseAuth is never resolved (lazy getter never read), so the
  repository makes zero calls

Login, happy path:
  /login "Sign in" -> AuthCubit.submitLogin(email, password)
     -> validation passes -> AuthRepository email sign-in
        (email.trim(), password as typed) -> FirebaseAuth.
        signInWithEmailAndPassword resolves with a User
     -> emit _accept shape (email = trimmed input, error null,
        invalidFields {}) -> AuthResult.success
  in parallel, outside this feature: FirebaseAuth.authStateChanges() emits
     the user -> F14 uidChanges() emits uid -> lib/app.dart's uid-keyed
     MultiBlocProvider is torn down and rebuilt with Firestore repositories
     and a fresh GoRouter at /home (D3). That teardown includes the auth
     ShellRoute's AuthCubit. See §13 Q3 for what that means for the view's
     own post-success navigation and toast.

Signup, happy path:
  /signup "Create account" -> AuthCubit.submitSignup(name, email,
     password, confirm) -> validation (name, email, blanks, length >= 8,
     match) passes -> AuthRepository account creation (email.trim(),
     password) -> FirebaseAuth.createUserWithEmailAndPassword resolves.
     Firebase signs the new user in automatically as part of this call;
     there is no separate sign-in step.
     -> emit _accept shape -> AuthResult.success
  same uid flip as login -> new user's D5 bootstrap runs (F18):
     currentUserProfileHint() reads displayName (null for a fresh
     email user, see §13 Q4) and email (the new account's email)

Forgot, happy path:
  /forgot "Send reset link" -> AuthCubit.submitForgot(email)
     -> validation passes -> AuthRepository password reset (email.trim())
     -> FirebaseAuth.sendPasswordResetEmail resolves
     -> emit _accept shape -> AuthResult.success -> view pushes /reset-sent
  no auth state change, no uid flip. With Firebase email-enumeration
  protection on, an unregistered address also resolves successfully. That
  is intended (§10).

Backend failure (any of the three):
  FirebaseAuthException(code) -> code mapped to a fixed message (§10)
     -> emit _reject shape on that form (form = login/signup/forgot,
        error = message, invalidFields {}) -> AuthResult.failure
     -> state.email is NOT changed (F02-A07: a failed submit leaves the
        stored email untouched); googleError / isGoogleSigningIn untouched
  StateError (credential with null user) or any other throwable
     (PlatformException, FirebaseException core/no-app, ...) -> generic
     message, same _reject shape -> AuthResult.failure. Nothing escapes
     to the zone; nothing is rethrown.

Cubit closed while a call is in flight (the uid flip above disposed it):
  the repository Future resolves or throws after AuthCubit.close() ->
     the Cubit performs no emit (no "emit after close" StateError) and
     returns the outcome; nothing surfaces as an unhandled error

Google path — untouched:
  /auth "Continue with Google" -> AuthCubit.signInWithGoogle() ->
     AuthRepository.signInWithGoogle() — identical code, identical tests
```

## 6. Interface surface

Proposed names. The plan fixes the Firebase methods but not the repository
method names, so a reviewer may rename these. The behaviour in §11 is what
binds.

```text
AuthRepository  (lib/features/auth/repository/auth_repository.dart)
  -- unchanged --
  AuthRepository({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
  User? get currentUser
  Future<User> signInWithGoogle()
  Future<void> signOut()
  -- added --
  Future<User> signInWithEmail({required String email, required String password})
      delegates to FirebaseAuth.signInWithEmailAndPassword; throws
      FirebaseAuthException as-is; StateError if UserCredential.user is null
  Future<User> createAccountWithEmail({required String email, required String password})
      delegates to FirebaseAuth.createUserWithEmailAndPassword; same throws
  Future<void> sendPasswordReset({required String email})
      delegates to FirebaseAuth.sendPasswordResetEmail; throws
      FirebaseAuthException as-is

AuthCubit  (lib/features/auth/cubit/auth_cubit.dart)
  -- unchanged --
  static isValidEmail, shortPasswordError, mismatchError
  resetForm(), clearInvalid(field), signInWithGoogle()
  -- return type changes (see §13 Q1) --
  Future<AuthResult> submitLogin({required String email, required String password})
  Future<AuthResult> submitSignup({required String name, required String email,
                                   required String password, required String confirm})
  Future<AuthResult> submitForgot({required String email})
  -- added (proposed copy, §13 Q6) --
  static const emailInUseError        'An account already exists for this email. Try signing in instead.'
  static const badCredentialsError    'Email or password is incorrect. Please try again.'
  static const weakPasswordError      'Choose a stronger password.'
  static const invalidEmailError      'Enter a valid email address.'
  static const userDisabledError      'This account has been disabled.'
  static const tooManyRequestsError   'Too many attempts. Please wait a moment and try again.'
  static const networkError           'No connection. Check your internet and try again.'
  static const genericAuthError       'Something went wrong. Please try again.'

AuthState / AuthResult / AuthForm / AuthFieldName  (auth_state.dart)
  unchanged; no new field (in-flight guard, if ruled in by §13 Q12, is a
  private Cubit field, not state)
```

Arguments passed to Firebase: `email.trim()` (the same trim `isValidEmail` and
`_accept` already apply) and `password` **exactly as typed**. A password is
never trimmed, because a leading or trailing space is a legal password
character.

## 7. Domain model usage

- No entity in `docs/foundation/03-domain-model.md` is read or written
  directly. `AuthState`, `AuthResult`, `AuthForm` and `AuthFieldName` are
  F02's feature-local UI types. `firestore-schema.md` §7 lists `AuthState`
  as transient ("`email` already comes from `FirebaseAuth.currentUser`,
  never a separate store"), and this task keeps it that way.
- `ProfileState.name` / `ProfileState.email` (03 §1) are affected only
  **indirectly**: a new email user's uid flip triggers F18's D5 bootstrap,
  which seeds `users/{uid}.email` from `currentUserProfileHint()` (schema
  doc §1: "mirrors `FirebaseAuth.currentUser.email` at sign-in") and
  `users/{uid}.name` from `displayName`, which is null for a fresh email
  account. This task does not change that bootstrap. Whether the signup
  form's name should reach it is §13 Q4.
- No new domain field is needed or invented.

## 8. Data changes

- **Firebase Auth (project `stylobuddy-b7e46`)**: enable the Email/Password
  sign-in provider. Per `CLAUDE.md` this is done programmatically (Identity
  Toolkit admin config, using the service account at
  `~/.secrets/stylobuddy/firebase-service-account.json`), not through
  console steps handed to the owner. It is a prerequisite for F21-A21 [L],
  not for the unit or integration gates (those use a faked `FirebaseAuth`).
  Record the state of **email-enumeration protection** (on or off) at that
  time, because it changes which error codes the live run sees (§10, §13 Q9).
- Firestore: none written by this task. A new email user's
  `users/{uid}` document is created by F18's existing bootstrap, unchanged.
- `docs/foundation/07-security.md` §1: remove "Create account, Forgot
  password ... are still demo flows ... no credentials leave the device";
  state that email/password sign-in, sign-up and password reset are real via
  Firebase Auth, and that verification email is still not sent (§3). §2's
  role table follows §13 Q11's ruling.
- No change to `03-domain-model.md` or `firestore-schema.md`.
- No migration. Existing Google users are unaffected. No email/password
  users exist before this task.

## 9. Background work and events

- None scheduled. Each submit is one request to Firebase Auth.
- Event emitted (by the Firebase SDK, not this code): `authStateChanges()`
  fires on a successful sign-in or sign-up. F14's `uidChanges()` already
  consumes it. This task adds no listener.
- Password-reset email: sent by Firebase's own mailer using the project's
  default template. There is no retry from the app; the user can submit
  again.
- No analytics event and no audit record (`07-security.md` §5: analytics
  stays "Later").
- Idempotency: calling `sendPasswordResetEmail` twice sends two emails,
  which is acceptable. `createUserWithEmailAndPassword` twice fails the
  second time with `email-already-in-use` (§12; §13 Q12 covers the
  same-device double tap).

## 10. Degradation and failure

Every path ends with a stated `AuthResult` and a stated `AuthState`. None
silently returns `success` and none crashes.

| Condition | Result | State after |
|---|---|---|
| Any F02 validation failure | `failure`, **no network call** | exactly as today (`_block` red borders, or `_reject` with `shortPasswordError` / `mismatchError`) |
| `email-already-in-use` (signup) | `failure` | signup `error = emailInUseError` |
| `invalid-credential`, `wrong-password`, `user-not-found`, `INVALID_LOGIN_CREDENTIALS` (login) | `failure` | login `error = badCredentialsError`. It is one message on purpose, so the app never reveals whether an account exists. With enumeration protection on, Firebase only returns `invalid-credential` anyway. |
| `weak-password` (signup) | `failure` | signup `error = weakPasswordError`. Normally unreachable (the client minimum of 8 is above Firebase's default of 6) unless a stricter project password policy is configured. |
| `invalid-email` (server rejects what the client regex accepted) | `failure` | that form's `error = invalidEmailError` |
| `user-disabled` | `failure` | `error = userDisabledError` |
| `too-many-requests` | `failure` | `error = tooManyRequestsError` |
| `network-request-failed` (offline) | `failure` | `error = networkError` |
| `operation-not-allowed` (provider not enabled, §8) or any unlisted code | `failure` | `error = genericAuthError`. The raw `e.code` / `e.message` is never shown. |
| `StateError` (credential with null user), `PlatformException`, `FirebaseException` (e.g. `core/no-app` when Firebase is not initialized), anything else | `failure` | `error = genericAuthError`, no rethrow |
| `sendPasswordResetEmail` for an unregistered address, enumeration protection on | `success` | `_accept`; `/reset-sent` shown. Intended: the app must not reveal registration. |
| Same, enumeration protection off (`user-not-found`) | proposed: `success` (treated like the above, for the same non-disclosure reason) | `_accept`; see §13 Q5 |
| Forgot failure of any other kind | `failure` | forgot `error` set. **Today `forgot_view.dart` renders no error text**, so this is invisible on screen. See §13 Q5. |
| Cubit closed before the call settles | outcome returned, no emit | unchanged (closed Cubit); no uncaught "emit after close" error |

Missing versus empty values this feature consumes:

- `FirebaseAuthException.message`: **missing (null), empty (`''`) and
  non-empty all lead to the same fixed mapped message**. The message comes
  from `e.code`, never from `e.message`, so a null message can never produce
  blank error text and a non-empty one can never leak raw SDK wording.
- `FirebaseAuthException.code` unrecognised or empty: `genericAuthError`,
  never an empty `error` (an empty string would render as a blank error
  line).
- `UserCredential.user` missing (null): `failure` + `genericAuthError`,
  never `success` with no user.
- `User.email` on the returned user: `AuthState.email` comes from the
  **trimmed input**, so `User.email` being null, `''` or a differently-cased
  value never blanks or alters `AuthState.email` (proposal, §13 Q2).

## 11. Validation assertions

> Written before implementation. A Firebase-facing `[U]` test uses a `mocktail`
> `FirebaseAuth` / `UserCredential` / `User` double injected through
> `AuthRepository(firebaseAuth: ...)`, the same technique
> `test/features/profile/onboarding_handoff_test.dart` already uses. "Unchanged
> pre-existing test" means: no expected value, error string, `invalidFields`
> set, route or copy string is edited. The only call-mechanics accommodation
> allowed is whatever §13 Q1/Q1b rules.

```
F21-A01  [U]  submitLogin(email: ' you@example.com ', password: ' abc ') with valid input calls FirebaseAuth.signInWithEmailAndPassword exactly once with email 'you@example.com' and password ' abc ' (untrimmed), never calls createUserWithEmailAndPassword/sendPasswordResetEmail/signInWithCredential, and on a resolved credential with a non-null user resolves to AuthResult.success with state.email == 'you@example.com', state.error == null, state.invalidFields == {}
F21-A02  [U]  submitSignup with valid name/email/password/confirm calls FirebaseAuth.createUserWithEmailAndPassword exactly once with the trimmed email and the untrimmed password, makes no separate signInWithEmailAndPassword call, and on success resolves to AuthResult.success with state.email == trimmed input, error null, invalidFields {}
F21-A03  [U]  submitForgot(email: ' a@b.co ') calls FirebaseAuth.sendPasswordResetEmail exactly once with email 'a@b.co', and on completion resolves to AuthResult.success with state.email == 'a@b.co' (F02-A07 parity) and error null
F21-A04  [U]  Validation short-circuits before any network call: for every F02 failure input — login email '', 'abc', 'a@b'; login blank password; signup name '', 'J', '  '; signup blank email/password/confirm; signup password 'short'; signup mismatch; signup 'short'+mismatch (length error wins); forgot email '' and 'nope' — the result is AuthResult.failure, state.error/invalidFields are exactly what F02-A03/A04/A06/A21 specify, and the injected mock FirebaseAuth records zero interactions (verifyZeroInteractions)
F21-A05  [U]  Lazy resolution preserved: AuthCubit() built with no arguments (default AuthRepository, no Firebase.initializeApp in the test) and driven only through validation-failing submits never resolves FirebaseAuth.instance — no exception is thrown and each result is AuthResult.failure with F02's state
F21-A06  [U]  Pre-existing suite non-regression: every test in test/features/auth/auth_cubit_test.dart and test/features/auth/auth_screens_test.dart, plus F18_A17 in test/features/profile/profile_repository_test.dart, passes with zero expected values edited; any edit to those files is limited to the call-mechanics accommodation §13 Q1/Q1b rules (awaiting the Future, injecting a fake repository), and the completion block lists every such edit by test name
F21-A07  [U]  submitSignup where createUserWithEmailAndPassword throws FirebaseAuthException(code: 'email-already-in-use') resolves to AuthResult.failure (no exception escapes) with state.errorFor(AuthForm.signup) == AuthCubit.emailInUseError, state.errorFor(AuthForm.login) == null, state.invalidFields == {}
F21-A08  [U]  submitLogin where signInWithEmailAndPassword throws FirebaseAuthException with each of the codes 'invalid-credential', 'wrong-password', 'user-not-found', 'INVALID_LOGIN_CREDENTIALS' resolves to AuthResult.failure with state.errorFor(AuthForm.login) == AuthCubit.badCredentialsError — the same string for all four (no account-existence disclosure)
F21-A09  [U]  submitSignup with code 'weak-password' sets errorFor(signup) == weakPasswordError; any form with 'invalid-email' sets invalidEmailError; 'user-disabled' sets userDisabledError; 'too-many-requests' sets tooManyRequestsError; 'network-request-failed' sets networkError; 'operation-not-allowed', '' and 'some-unknown-code' each set genericAuthError — each a failure, none rethrown
F21-A10  [U]  The mapped message ignores FirebaseAuthException.message: for code 'email-already-in-use' with message null, message '' and message 'The email address is already in use by another account.', state.error is emailInUseError in all three cases, never null, never '', never the raw SDK text
F21-A11  [U]  A non-FirebaseAuthException thrown by the repository — StateError('no user'), PlatformException(code: 'x'), FirebaseException(plugin: 'core', code: 'no-app') — makes submitLogin/submitSignup/submitForgot resolve to AuthResult.failure with errorFor(<that form>) == genericAuthError; the error is caught (mirroring signInWithGoogle's catch-all) and no uncaught error reaches the test zone
F21-A12  [U]  A UserCredential whose user is null (missing) from signInWithEmailAndPassword or createUserWithEmailAndPassword yields AuthResult.failure + genericAuthError, never AuthResult.success
F21-A13  [U]  AuthState.email after a successful login/signup is the trimmed input regardless of the returned User.email: tested separately with User.email == null (missing), User.email == '' (empty) and User.email == 'YOU@EXAMPLE.COM' (different case); in all three, state.email == trimmed input [subject to §13 Q2; amend with a dated note if ruled otherwise]
F21-A14  [U]  A backend failure leaves state.email untouched: after a successful submitForgot('keep@x.io'), a submitLogin that fails with 'invalid-credential' leaves state.email == 'keep@x.io' (F02-A07 failed-submit parity on the backend path)
F21-A15  [U]  A backend error clears on a later success: submitSignup failing with 'email-already-in-use' then a successful submitSignup leaves state.error == null and invalidFields == {} (F02-A21 parity); and a backend error set on the signup form is not visible via errorFor(AuthForm.login)
F21-A16  [U]  Email-path failures never touch the Google channel: after any F21-A07..A12 failure, state.googleError == null and state.isGoogleSigningIn == false (so /auth's googleError toast listener never fires for an email error)
F21-A17  [U]  Cubit closed mid-flight: when the repository Future resolves (success) or throws (FirebaseAuthException) only after AuthCubit.close() has been called, the submit method completes without throwing, performs no emit, and no "Cannot emit new states after calling close" StateError reaches the test zone
F21-A18  [U]  AuthRepository's new methods delegate exactly: signInWithEmail/createAccountWithEmail/sendPasswordReset each call only the matching FirebaseAuth method once with the given arguments, rethrow a FirebaseAuthException with its code unchanged (no mapping in the repository), and never call any GoogleSignIn method (verifyZeroInteractions on an injected mock GoogleSignIn)
F21-A19  [U]  Google path untouched: `git diff` of auth_repository.dart shows no changed line inside the constructor, the _firebaseAuth/_googleSignIn getters, currentUser, signInWithGoogle() or signOut(); `git diff` of auth_cubit.dart shows no changed line inside signInWithGoogle(); the pre-existing Google tests (F02_A15 in auth_screens_test.dart, the signInWithGoogle cases in test/features/profile/onboarding_handoff_test.dart) pass with zero lines of their test files changed
F21-A20  [I]  Uid flip just works: uidChanges(authStateChanges: <mock FirebaseAuth.authStateChanges()>) emits null, then — after AuthCubit.submitLogin succeeds against that same mock FirebaseAuth, whose authStateChanges then emits the signed-in User(uid: 'email-uid-1') — emits 'email-uid-1'; the same for submitSignup; this passes with lib/app.dart and lib/shared/backend/auth_session.dart unmodified by this task
F21-A21  [L]  Live, Android emulator against project stylobuddy-b7e46 with the Email/Password provider enabled (§8): (1) sign up a fresh test address -> the app lands on /home signed-in, and the Admin API / Firebase console lists that user; users/{uid} exists with seeded == true and email == that address; (2) kill and relaunch -> still signed in (Firestore-backed data, not seed-reset guest data); (3) sign up again with the same address -> stays on /signup showing emailInUseError; (4) /login with a wrong password -> stays on /login showing badCredentialsError; (5) /forgot with the test address -> /reset-sent shown and a reset email arrives in that inbox. Record the enumeration-protection setting observed and the exact commands/steps in the completion block
F21-A22  [I]  Widget path, login error visible: through the full app (pumpApp or its §13 Q1b successor) with a faked FirebaseAuth whose signInWithEmailAndPassword throws 'invalid-credential', entering a valid email + non-empty password and tapping "Sign in" leaves the route at /login, renders the badCredentialsError text once under the form, and shows no 'Signed in to demo account' toast
F21-A23  [I]  Widget path, signup error visible: same harness, createUserWithEmailAndPassword throwing 'email-already-in-use' -> route stays /signup, emailInUseError rendered once, no navigation to /verify-email
F21-A24  [U]  Double submit (subject to §13 Q12): calling submitSignup twice without awaiting the first, while the first createUserWithEmailAndPassword is still pending, results in exactly one createUserWithEmailAndPassword call; the second call resolves to AuthResult.failure without changing state
F21-A25  [U]  docs/foundation/07-security.md §1 no longer contains the phrase "no credentials leave the device" and states email/password sign-in, sign-up and password reset are real via Firebase Auth (doc check, run as part of the task's gate, not a Dart test)
```

## 12. Edge cases

- **Email with surrounding whitespace** (`' a@b.co '`): validated trimmed (as
  today) and sent to Firebase trimmed (F21-A01/A03). Firebase never sees the
  spaces.
- **Password with leading or trailing spaces**: sent exactly as typed
  (F21-A01). On signup the length rule counts those spaces, as it does today.
- **Login password shorter than 8**: still accepted client-side (F02-A05, no
  length rule on login). Firebase decides. A real account can never have a
  password under 8 if it was created through this app, but one created
  elsewhere could.
- **Mixed-case email at signup, different case at login**: Firebase treats
  emails case-insensitively, so login succeeds. `AuthState.email` shows
  whatever the user typed this time (F21-A13).
- **Signing up with an email already used for Google sign-in**: Firebase
  returns `email-already-in-use` (with the default one-account-per-email
  setting) -> `emailInUseError`. The message suggests signing in, but the
  password login will then fail because that account has no password. A
  known rough edge, deferred with account linking (§3).
- **Device offline**: `network-request-failed` -> `networkError`, stays on
  the form, can retry (F21-A09).
- **Firebase not initialised** (widget tests, or a broken boot):
  `FirebaseException(core/no-app)` from the lazy getter -> `genericAuthError`,
  no crash (F21-A11). Only reached once validation passes (F21-A05).
- **Uid flip disposes the auth subtree before the view reacts**: the view's
  own `context.go` / `push` / toast after `await` must be `mounted`-guarded
  (the same pattern `auth_view.dart`'s Google button already uses), and the
  Cubit must not emit after close (F21-A17). The product consequence (the
  user lands on `/home` from the rebuild, not from the view, and
  `/verify-email` is effectively skipped after a real signup) is §13 Q3.
- **Reset requested twice**: two emails. Firebase invalidates the older link
  by its own rules. No app-side handling.
- **Signed-in Google user opens /login and signs in with email**: Firebase
  replaces the current user. `uidChanges()` emits the new uid and D3 rebuilds
  the subtree. No bleed-through, per F14's existing guarantee.

## 13. Open questions

**These need a controller ruling before implementation. Q1-Q3 block the
build.**

- **Q1: the "same `AuthResult` return contract" cannot be kept literally.
  The three view files must change. (BLOCKING)** Today `submitLogin`,
  `submitSignup` and `submitForgot` return `AuthResult` **synchronously**,
  and `login_view.dart:43-50`, `signup_view.dart:47-53` and
  `forgot_view.dart:38-39` do `final result = cubit.submitX(...); if (result
  == AuthResult.success) ...` with no `await`. A network call makes the
  return type `Future<AuthResult>`. If the views stay as they are, the
  `==` comparison of a `Future` against an enum is always false, so
  navigation and the toast **never** happen, and `flutter analyze` flags
  `unrelated_type_equality_checks`. Every workable design therefore
  touches the views, which conflicts with the plan's global constraint "no
  widget (`view/`, `widgets/`) changes anywhere in this plan".
  - (a) **Proposed:** a narrow, explicitly-ruled exception. Make the three
    `_submit` methods `async`, `await` the Cubit, and guard navigation and
    toast with `context.mounted`, mirroring `auth_view.dart:112-118`'s
    existing Google handler. No layout, copy or widget-tree change.
  - (b) Rejected: keep the sync signatures returning the validation
    outcome, fire the network call in the background, and report the
    result via state. The views would navigate to `/home` and toast
    "Signed in" **before** Firebase answers, including for a wrong
    password.
  - (c) Rejected: `FutureOr<AuthResult>` (sync for validation failures,
    `Future` otherwise). It still breaks every typed call site, the views
    still need `await`, and it is harder to read.

- **Q1b: pre-existing tests cannot all pass with zero file changes
  either. (BLOCKING)**
  - `test/features/auth/auth_cubit_test.dart` declares `AuthResult
    _signup(...) => c.submitSignup(...)`. With a `Future` return type that
    is a compile error, so the **whole file** fails, including the
    validation-only tests the plan says "still pass unchanged".
  - The pre-existing **happy-path** tests construct `AuthCubit()` with no
    fake and expect `AuthResult.success`: F02_A05, F02_A06's `'Jo'` case,
    F02_A07, F02_A21's success case, and F18_A17's `accepted` case in
    `test/features/profile/profile_repository_test.dart`. Against real
    Firebase in a test (no `initializeApp`) these now get `failure`.
  - The widget happy paths through `test/features/support/f02_harness.dart`
    `pumpApp` have **no seam** to inject a fake: F02_A17, F02_A21's valid
    signup, F02_A22, F02_A23, F02_A24 and F02_A28. `auth_routes.dart:18`
    hard-codes `AuthCubit()`, and `StyloBuddyApp` has no auth override (it
    has `firestoreOverride` / `uidStream`, but nothing for auth).

  Ruling needed on:
  - (i) whether mechanical edits are allowed: `await`, injecting a mock
    repository, keeping every expected value. F21-A06 is written to allow
    exactly that, and nothing more.
  - (ii) where the widget-test seam lives. One option is an
    `authRepository` override on `StyloBuddyApp` passed down to
    `auth_routes`. That touches `lib/app.dart`, a Task 1/F14-owned shared
    file ("a later task reports a needed shared change instead of making
    it"), and `f02_harness.dart`.

  Plan Review Focus #1 ("no existing test changed its assertions") is
  satisfiable under (i), but "unchanged files" is not.

- **Q2: should a successful email sign-in update `AuthState.email` the way
  `signInWithGoogle` does?** It does update it, but from what source:
  - **Proposed:** the trimmed input. This matches `_accept` and F02-A07
    exactly, and `/verify-email` shows what the user typed.
  - Alternative: the returned `User.email`, mirroring the Google branch's
    `user.email ?? ''`. That could change case, and a null would blank the
    field.

  F21-A13 encodes the proposal.

- **Q3: what happens to Task 1's uid-stream wiring once an email user signs
  in? (BLOCKING for the signup UX.)**
  - Mechanically it **already just works**. `uidChanges()`
    (`lib/shared/backend/auth_session.dart`) wraps
    `FirebaseAuth.instance.authStateChanges()`, which fires for every
    provider. `createUserWithEmailAndPassword` signs in automatically and
    fires it as well. **No change to `lib/app.dart` is needed for the flip
    itself** (F21-A20).
  - The **consequence** is not neutral. D3 tears down the whole uid-keyed
    subtree, including the router and the auth `ShellRoute`'s `AuthCubit`,
    and builds a fresh `GoRouter` at `/home`. So:
    - (1) after a real signup the user is taken to `/home`, and the
      `/verify-email` screen F02 routes to is never seen, or flashes for at
      most one frame;
    - (2) after login, the view's "Signed in" toast may fire on a disposed
      context or be lost;
    - (3) the Cubit may be closed when the Firebase call resolves (handled
      by F21-A17).
  - The Google path already lives with (1) and (2). Ruling needed:
    - accept "successful email auth lands on `/home` via the rebuild", the
      **proposal**, consistent with Google;
    - or keep `/verify-email` reachable after signup, which needs router or
      `app.dart` work owned by Task 1/F14 and is not this task's to make.

- **Q4: does `submitSignup`'s success also sign the user in, and what
  happens to the Full name field?**
  - Sign-in: yes, unavoidably. Firebase's `createUserWithEmailAndPassword`
    signs the new user in as part of the call. **Proposed:** accept and
    rely on it. Do not call `signOut` to force a separate login step.
  - Name: the Full name the user typed is currently **discarded**. A fresh
    email user has no `displayName`, so F18's bootstrap
    (`currentUserProfileHint()`) seeds `users/{uid}.name` with the
    `ProfileState` default `'Alex Morgan'`. Calling `User.updateDisplayName`
    after creation does not reliably fix this: `authStateChanges` fires as
    soon as the account exists, so the bootstrap can read `displayName`
    before the update lands.
  - F02-A28 ("signup leaves `ProfileState` untouched") was resolved on
    2026-10-16 for the demo era.
  - Ruling needed: keep discarding the name (the **proposal** for this
    task, minimal scope), or carry it through. Carrying it would need
    either a handoff holder like F18's `PendingOnboardingSelections`
    (shared infra owned by Task 1/F18) or an `updateDisplayName` plus a
    profile write that F02-A28 would have to be amended for.

- **Q5: forgot-password failures and unregistered emails.**
  - `forgot_view.dart` has **no `AuthErrorText`**, so a `submitForgot`
    failure (offline, `too-many-requests`) sets `error` but nothing is
    shown: the user taps and nothing happens. Options: the view-exception
    route from Q1(a) adds an error line, or the failure also sets
    `invalidFields {email}` so the existing red border shows. The latter
    is misleading for a network error.
  - Separately, with enumeration protection **off**, an unregistered
    address throws `user-not-found`. **Proposed:** treat it as success
    (show `/reset-sent`) so the app never discloses registration (§10).
    Needs a ruling because it deliberately reports success on an error.

- **Q6: error copy and mapping source.** The `signInWithGoogle` precedent
  surfaces `e.message ?? fallback`, which is raw SDK English, sometimes
  developer-facing and sometimes account-disclosing. This document instead
  proposes a fixed `e.code` -> constant mapping (§6, §10) and asserts it
  (F21-A08..A10). The proposed strings need product sign-off. If they
  change, amend F21-A07..A11 with a dated note.

- **Q7: demo copy is now untrue.** `DemoCopy.loginSuccessToast` ("Signed in
  to demo account"), `resetSentNoticeAfter` ("No email has been sent by
  this prototype", even though one now is), and the verify-email strings
  are all gated by `kShowDemoNotes = true` (`lib/shared/widgets/
  demo_note.dart`). Flipping that flag changes copy on Profile, Packing,
  Wardrobe and Shopping screens too, and breaks F02-A17/A23/A24 and F13's
  copy assertions. **Proposed:** out of scope here, left for Task 11's docs
  and copy pass. Ruling needed on whether that is acceptable for an
  interim build.

- **Q8: email verification.** Should signup also call
  `sendEmailVerification`, and should anything be gated on
  `emailVerified`? The plan doesn't ask for it. **Proposed:** out of scope
  (§3). `/verify-email` is unreachable after a real signup anyway (Q3).

- **Q9: who enables the Email/Password provider, and is enumeration
  protection on?** The plan lists only Google Auth as enabled on
  `stylobuddy-b7e46`. Without the provider, every real call returns
  `operation-not-allowed` (-> `genericAuthError`). **Proposed:** this
  task's implementer enables it programmatically per `CLAUDE.md` (service
  account, Identity Toolkit config) before F21-A21, and records the
  enumeration-protection state.

- **Q10: `signOut()` for email users.** It is left untouched, per the
  constraint. It calls `_googleSignIn.signOut()` **before**
  `_firebaseAuth.signOut()`. If the Google call throws for a session that
  never used Google (platform or Play Services quirks), Firebase sign-out
  never runs and an email user stays signed in. There is also no
  production caller of `signOut()` today. **Flagged, not fixed:** fixing
  it means changing the Google path this task must not touch.

- **Q11: `07-security.md`'s "demo user" role.** After this task, an email
  login is a real authenticated user. Should the "demo user" row be removed
  or reworded, given that the onboarding chooser still offers "Skip for
  now" (guest)? `03-domain-model.md` §2 also lists "Roles: guest / demo
  user". Ruling needed so both foundation docs change consistently in this
  task.

- **Q12: double-submit guard.** There is no in-flight flag and no widget
  can show one, since widgets are frozen. A double tap on "Create account"
  can create the account and then show `emailInUseError` from the second
  call. **Proposed:** a private in-flight guard in `AuthCubit` (no
  `AuthState` change): a second `submitX` while one is pending returns
  `failure` without a Firebase call or a state change (F21-A24). If
  rejected, drop the guard and amend F21-A24 with a dated note. Do not
  delete the assertion.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: DEFERRED — skipped by explicit user decision (2026-10-20): keep Google auth only for now, do not implement real email/password login. Not pursued further.

[ ] Gate 1  Interface documented
[ ] Gate 2  Unit
[ ] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 0/25 PASS
Regression: —
```
