import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylobuddy/features/auth/cubit/auth_cubit.dart';
import 'package:stylobuddy/features/auth/cubit/auth_state.dart';
import 'package:stylobuddy/features/auth/repository/auth_repository.dart';
import 'package:stylobuddy/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';
import 'package:stylobuddy/features/profile/repository/firestore_profile_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/backend/pending_onboarding_selections.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class _MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

/// Builds an [AuthCubit] whose `signInWithGoogle()` succeeds against fully
/// faked Firebase Auth/Google Sign-In plugin objects (no real network, no
/// real plugin channel) — the production call path
/// (`AuthRepository.signInWithGoogle` -> `GoogleSignIn.signIn` ->
/// `FirebaseAuth.signInWithCredential`) runs for real against these fakes.
AuthCubit _authCubitWithSuccessfulGoogleSignIn({required String email}) {
  final account = _MockGoogleSignInAccount();
  final authTokens = _MockGoogleSignInAuthentication();
  when(() => authTokens.accessToken).thenReturn('access-token');
  when(() => authTokens.idToken).thenReturn('id-token');
  when(() => account.authentication).thenAnswer((_) async => authTokens);
  final googleSignIn = _MockGoogleSignIn();
  when(() => googleSignIn.signIn()).thenAnswer((_) async => account);

  final user = _MockUser();
  when(() => user.email).thenReturn(email);
  final credential = _MockUserCredential();
  when(() => credential.user).thenReturn(user);
  final firebaseAuth = _MockFirebaseAuth();
  when(
    () => firebaseAuth.signInWithCredential(any()),
  ).thenAnswer((_) async => credential);

  return AuthCubit(
    repository: AuthRepository(
      firebaseAuth: firebaseAuth,
      googleSignIn: googleSignIn,
    ),
  );
}

/// Polls [action] until it returns true or [timeout] elapses — mirrors the
/// implementer contract's "Known gotcha" bounded-polling pattern (a bare
/// Future delay here, since this is a plain `test`, not `testWidgets`).
Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
  });

  setUp(PendingOnboardingSelections.clear);
  tearDown(PendingOnboardingSelections.clear);

  /// F18-A05/A06: toggles at least one occasion on intro slide 4 and at
  /// least one chip on /personalize, completes Google sign-in through
  /// `AuthCubit.signInWithGoogle()`, then builds the uid's
  /// `FirestoreProfileRepository`/`ProfileCubit` exactly as
  /// `lib/app.dart`'s signed-in branch does (bootstrap + consume-and-clear
  /// the pending-selections holder) — proving the onboarding choices really
  /// reach `ProfileState.occasions`.
  ///
  /// Before Task 5's implementation lands, this test cannot even compile
  /// (no `PendingOnboardingSelections`, no `FirestoreProfileRepository`,
  /// no `ProfileRepository`-taking `ProfileCubit` constructor exist on
  /// `main` yet) — that failure-to-build is this task's required RED
  /// evidence (pasted into the completion block/report), since there is no
  /// pre-existing forwarding mechanism at all to assert against.
  test(
    'F18_A05_A06 onboarding occasions/chips reach the bootstrap-seeded ProfileCubit after Google sign-in, surviving a simulated relaunch re-read',
    () async {
      final onboarding = OnboardingCubit();
      onboarding.toggleOccasion('Wedding'); // intro slide 4
      onboarding.toggleChip('Travel'); // /personalize chip
      addTearDown(onboarding.close);

      final auth = _authCubitWithSuccessfulGoogleSignIn(
        email: 'new.user@example.com',
      );
      addTearDown(auth.close);
      final result = await auth.signInWithGoogle();
      expect(result, AuthResult.success);

      // Mirrors lib/app.dart's signed-in branch: construct the Firestore
      // repository for this brand-new uid, consume-and-clear the pending
      // holder, and run the bootstrap exactly once.
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);
      const uid = 'uid-new-signup';
      final repository = FirestoreProfileRepository(service, uid);
      final pending = PendingOnboardingSelections.consume();
      await repository.bootstrapIfNeeded(pendingOccasions: pending);

      final profileCubit = ProfileCubit(repository: repository);
      addTearDown(profileCubit.close);
      await _waitUntil(
        () => profileCubit.state.occasions.contains('Wedding'),
      );

      expect(profileCubit.state.occasions, containsAll(['Wedding', 'Travel']));

      // The holder must have been cleared by `consume()` so it cannot leak
      // into a later, unrelated sign-up in the same process.
      expect(PendingOnboardingSelections.consume(), isEmpty);

      // Re-read via watchProfile() (not just the first optimistic emit) —
      // simulate a relaunch/re-sign-in by constructing a brand-new
      // ProfileCubit against the same uid's document.
      final relaunchCubit = ProfileCubit(
        repository: FirestoreProfileRepository(service, uid),
      );
      addTearDown(relaunchCubit.close);
      await _waitUntil(
        () => relaunchCubit.state.occasions.contains('Wedding'),
      );
      expect(
        relaunchCubit.state.occasions,
        containsAll(['Wedding', 'Travel']),
      );
    },
  );

  /// F18-A07: a user who toggles nothing during onboarding still bootstraps
  /// with ProfileState()'s hardcoded default occasions — "didn't choose"
  /// must never be confused with "chose to clear everything".
  test(
    'F18_A07 no onboarding selections falls back to the hardcoded default occasions, never an empty list',
    () async {
      final pending = PendingOnboardingSelections.consume();
      expect(pending, isEmpty);

      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);
      final repository = FirestoreProfileRepository(service, 'uid-no-choice');
      await repository.bootstrapIfNeeded(pendingOccasions: pending);

      final cubit = ProfileCubit(repository: repository);
      addTearDown(cubit.close);
      await _waitUntil(() => cubit.state.name.isNotEmpty);

      expect(cubit.state.occasions, ['Everyday', 'Office']);
    },
  );
}
