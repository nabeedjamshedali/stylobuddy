import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/calendar/cubit/planner_cubit.dart';
import 'package:stylobuddy/shared/models/planned_entry.dart';

void main() {
  late PlannerCubit cubit;
  setUp(() => cubit = PlannerCubit());
  tearDown(() => cubit.close());

  test('initial selection and seed plan', () {
    expect(cubit.selectedKey, '2026-10-15');
    expect(cubit.state.planned['2026-10-15']!.outfitId, 1);
  });

  test('navigate clamps day to month length', () {
    cubit.select(31);
    cubit.navigate(1);
    expect(cubit.state.month, 11);
    expect(cubit.state.day, 30);
  });

  test('navigate wraps across years', () {
    cubit.navigate(3);
    expect((cubit.state.year, cubit.state.month), (2027, 1));
    cubit.navigate(-1);
    expect((cubit.state.year, cubit.state.month), (2026, 12));
  });

  test('keyFor pads and label formats', () {
    expect(PlannerCubit.keyFor(2026, 3, 5), '2026-03-05');
    expect(cubit.label('2026-10-15'), 'October 15, 2026');
  });

  test('plan and remove', () {
    cubit.plan(
        '2026-10-20', const PlannedEntry(outfitId: 2, occasion: 'Casual'));
    expect(cubit.state.planned['2026-10-20']!.outfitId, 2);
    cubit.remove('2026-10-20');
    expect(cubit.state.planned.containsKey('2026-10-20'), isFalse);
  });
}
