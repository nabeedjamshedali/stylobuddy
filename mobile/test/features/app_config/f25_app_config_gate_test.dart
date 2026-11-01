import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/app_config/cubit/app_config_cubit.dart';
import 'package:stylobuddy/features/app_config/widgets/app_config_gate.dart';
import 'package:stylobuddy/shared/models/app_config.dart';

import '../../support/fake_remote_config.dart';

const _appKey = Key('app-child');

Future<AppConfigCubit> _loadedCubit({
  String? installed = '1.0.0',
  String min = '',
  String latest = '',
  String message = '',
  Future<bool> Function()? openStore,
}) async {
  final cubit = AppConfigCubit(
    remoteConfig: FakeRemoteConfig(
      initial: AppConfig.defaults.copyWith(
        minSupportedVersion: min,
        latestVersion: latest,
        maintenanceMessage: message,
      ),
    ),
    installedVersion: () async => installed,
    openStore: openStore,
  );
  await cubit.load();
  return cubit;
}

/// A MaterialApp whose Navigator is wrapped by the gate, as in app.dart.
Future<int Function()> _pumpApp(WidgetTester tester, AppConfigCubit cubit) async {
  var taps = 0;
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        builder: (context, child) => AppConfigGate(child: child!),
        home: Scaffold(
          body: Center(
            child: TextButton(
              key: _appKey,
              onPressed: () => taps++,
              child: const Text('APP-BUTTON'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return () => taps;
}

void main() {
  testWidgets('F25_A29 default state returns the child itself, with nothing wrapped around it', (
    tester,
  ) async {
    final cubit = await _loadedCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const AppConfigGate(child: SizedBox(key: _appKey)),
      ),
    );
    final wrappers = <Type>[];
    tester.element(find.byKey(_appKey)).visitAncestorElements((element) {
      if (element.widget is AppConfigGate) return false;
      wrappers.add(element.widget.runtimeType);
      return true;
    });
    for (final forbidden in [Stack, Column, Offstage, Expanded, MediaQuery]) {
      expect(wrappers, isNot(contains(forbidden)));
    }
    expect(find.byKey(const Key('update-required-view')), findsNothing);
    expect(find.byKey(const Key('maintenance-banner')), findsNothing);
    expect(find.byKey(const Key('update-nudge-banner')), findsNothing);
  });

  testWidgets('F25_A30 forced update hides the app offstage and offers no way past', (
    tester,
  ) async {
    final cubit = await _loadedCubit(min: '2.0.0');
    addTearDown(cubit.close);
    final taps = await _pumpApp(tester, cubit);

    expect(find.byKey(const Key('update-required-view')), findsOneWidget);
    expect(find.text('Update required'), findsOneWidget);
    expect(
      find.text(
        'This version of StyloBuddy is no longer supported. '
        'Update to the latest version to keep using the app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Update now'), findsOneWidget);

    expect(find.text('APP-BUTTON'), findsNothing);
    expect(find.text('APP-BUTTON', skipOffstage: false), findsOneWidget);
    final offstage = tester.widget<Offstage>(
      find.ancestor(
        of: find.text('APP-BUTTON', skipOffstage: false),
        matching: find.byType(Offstage, skipOffstage: false),
      ).last,
    );
    expect(offstage.offstage, isTrue);

    for (final escape in ['Later', 'Skip', 'Close', 'Not now', '✕']) {
      expect(find.text(escape), findsNothing, reason: escape);
    }

    await tester.tapAt(tester.getCenter(find.byType(MaterialApp)));
    await tester.pumpAndSettle();
    expect(taps(), 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('update-required-view')), findsOneWidget);
  });

  testWidgets('F25_A31 Update now calls openStore once and shows the failure line when it cannot open', (
    tester,
  ) async {
    var calls = 0;
    final cubit = await _loadedCubit(
      min: '2.0.0',
      openStore: () async {
        calls++;
        return false;
      },
    );
    addTearDown(cubit.close);
    await _pumpApp(tester, cubit);
    const error =
        "Couldn't open Google Play. Please update StyloBuddy from the Play Store.";
    expect(find.text(error), findsNothing);

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text(error), findsOneWidget);
    expect(find.byKey(const Key('update-required-view')), findsOneWidget);
  });

  testWidgets('F25_A32 maintenance banner sits above a working app and can be dismissed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final cubit = await _loadedCubit(message: 'Back at 9');
    addTearDown(cubit.close);
    final taps = await _pumpApp(tester, cubit);

    final banner = find.byKey(const Key('maintenance-banner'));
    expect(banner, findsOneWidget);
    expect(find.descendant(of: banner, matching: find.text('Back at 9')), findsOneWidget);
    expect(
      tester.getBottomLeft(banner).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text('APP-BUTTON')).dy),
    );

    await tester.tap(find.text('APP-BUTTON'));
    expect(taps(), 1);

    await tester.tap(find.bySemanticsLabel('Dismiss notice'));
    await tester.pumpAndSettle();
    expect(banner, findsNothing);
    expect(find.text('APP-BUTTON'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('F25_A33 update nudge offers Update and can be dismissed; maintenance sits above it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var calls = 0;
    final cubit = await _loadedCubit(
      installed: '1.0.1',
      latest: '1.0.3',
      openStore: () async {
        calls++;
        return true;
      },
    );
    addTearDown(cubit.close);
    await _pumpApp(tester, cubit);

    final nudge = find.byKey(const Key('update-nudge-banner'));
    expect(nudge, findsOneWidget);
    expect(find.text('A new version of StyloBuddy is available.'), findsOneWidget);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.tap(find.bySemanticsLabel('Dismiss update notice'));
    await tester.pumpAndSettle();
    expect(nudge, findsNothing);

    final both = await _loadedCubit(
      installed: '1.0.1',
      latest: '1.0.3',
      message: 'Back at 9',
    );
    addTearDown(both.close);
    await _pumpApp(tester, both);
    expect(
      tester.getTopLeft(find.byKey(const Key('maintenance-banner'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('update-nudge-banner'))).dy),
    );
    semantics.dispose();
  });
}
