import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylobuddy/shared/backend/auth_session.dart';

class _MockUser extends Mock implements User {}

User _userWithUid(String uid) {
  final user = _MockUser();
  when(() => user.uid).thenReturn(uid);
  return user;
}

void main() {
  test(
    'F14_currentUid returns null synchronously when FirebaseAuth is not initialized',
    () {
      // Mirrors F14_A14: no Firebase.initializeApp() call in this test, so
      // FirebaseAuth.instance throws synchronously; currentUid() must catch
      // that and return null rather than propagate.
      expect(currentUid(), isNull);
    },
  );

  test('F14_A01 uidChanges emits null as its first event for a signed-out source', () async {
    final source = Stream<User?>.value(null);

    final first = await uidChanges(authStateChanges: source).first;

    expect(first, isNull);
  });

  test('F14_A02 uidChanges emits the signed-in uid after the source emits a User', () async {
    final source = Stream<User?>.fromIterable([_userWithUid('uid-1')]);

    final first = await uidChanges(authStateChanges: source).first;

    expect(first, 'uid-1');
  });

  test(
    'F14_A03 uidChanges covers signed-out -> signed-in -> signed-out in one cycle',
    () async {
      final controller = StreamController<User?>();
      final events = <String?>[];
      final sub = uidChanges(
        authStateChanges: controller.stream,
      ).listen(events.add);

      controller.add(null);
      await pumpEventQueue();
      controller.add(_userWithUid('uid-1'));
      await pumpEventQueue();
      controller.add(null);
      await pumpEventQueue();

      expect(events, [null, 'uid-1', null]);
      await sub.cancel();
      await controller.close();
    },
  );

  test(
    'F14_A04 uidChanges does not re-emit for a duplicate consecutive User',
    () async {
      final controller = StreamController<User?>();
      final events = <String?>[];
      final sub = uidChanges(
        authStateChanges: controller.stream,
      ).listen(events.add);

      final user = _userWithUid('uid-1');
      controller.add(user);
      await pumpEventQueue();
      controller.add(user);
      await pumpEventQueue();
      controller.add(_userWithUid('uid-1')); // same uid, different instance
      await pumpEventQueue();

      expect(events, ['uid-1']);
      await sub.cancel();
      await controller.close();
    },
  );

  test(
    'F14_edge empty-string uid is treated the same as null',
    () async {
      final source = Stream<User?>.value(_userWithUid(''));

      final first = await uidChanges(authStateChanges: source).first;

      expect(first, isNull);
    },
  );

  test(
    'F14_A14 uidChanges() with no injected stream never throws even when FirebaseAuth is not initialized',
    () async {
      // This test never calls Firebase.initializeApp(); uidChanges() must
      // still resolve to a signed-out-only stream rather than throwing
      // synchronously out of FirebaseAuth.instance.
      final first = await uidChanges().first;

      expect(first, isNull);
    },
  );

  test(
    'F14_degradation an error from the underlying stream becomes a signed-out (null) event, not a thrown error',
    () async {
      final controller = StreamController<User?>();
      final events = <String?>[];
      final errors = <Object>[];
      final sub = uidChanges(authStateChanges: controller.stream).listen(
        events.add,
        onError: errors.add,
      );

      controller.add(_userWithUid('uid-1'));
      await pumpEventQueue();
      controller.addError(StateError('plugin failure'));
      await pumpEventQueue();

      expect(events, ['uid-1', null]);
      expect(errors, isEmpty);
      await sub.cancel();
      await controller.close();
    },
  );
}
