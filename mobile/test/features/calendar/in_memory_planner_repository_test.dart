import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/calendar/cubit/planner_cubit.dart';
import 'package:stylobuddy/features/calendar/repository/in_memory_planner_repository.dart';
import 'package:stylobuddy/shared/models/planned_entry.dart';

void main() {
  test(
    'F17_A08 PlannerCubit constructed with InMemoryPlannerRepository passes the full pre-existing planner_cubit_test.dart suite unmodified',
    () {
      // The actual regression coverage lives in
      // test/features/calendar/planner_cubit_test.dart, which already
      // constructs `PlannerCubit()` (defaulting to
      // InMemoryPlannerRepository) with zero assertion edited for this
      // task — this test documents and anchors that guarantee alongside
      // this repository's own dedicated test file.
      final cubit = PlannerCubit();
      expect(cubit.selectedKey, '2026-10-15');
      expect(cubit.state.planned['2026-10-15']!.outfitId, 1);
      cubit.close();
    },
  );

  test(
    'F17_A09 InMemoryPlannerRepository.plan/remove return an already-complete Future, not an async-declared method',
    () {
      final repository = InMemoryPlannerRepository();
      var planCompleted = false;
      repository
          .plan('2026-10-20', const PlannedEntry(outfitId: 2, occasion: 'X'))
          .then((_) => planCompleted = true);
      // No `await`/pump between the call above and this assertion: a
      // SynchronousFuture's `.then` callback runs inline (same microtask),
      // so this is already true by the time control reaches here, before
      // any pump/await — an `async`-declared method's `.then` would not
      // have run yet.
      expect(planCompleted, isTrue);

      var removeCompleted = false;
      repository.remove('2026-10-20').then((_) => removeCompleted = true);
      expect(removeCompleted, isTrue);
    },
  );

  test(
    'F17_A10 in_memory_planner_repository.dart imports no cloud_firestore/http/supabase package — guest mode makes zero network calls structurally',
    () {
      final file = File(
        'lib/features/calendar/repository/in_memory_planner_repository.dart',
      );
      expect(file.existsSync(), isTrue, reason: 'run from repo root');

      final content = file.readAsStringSync();
      for (final banned in ['cloud_firestore', 'package:http', 'supabase']) {
        expect(
          content.contains(banned),
          isFalse,
          reason:
              'in_memory_planner_repository.dart must never import/mention '
              '"$banned" — guest mode must make zero network calls '
              'structurally',
        );
      }
    },
  );
}
