import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';
import 'package:stylobuddy/features/profile/cubit/profile_state.dart';

void main() {
  late ProfileCubit cubit;
  setUp(() => cubit = ProfileCubit());
  tearDown(() => cubit.close());

  test('defaults match prototype', () {
    expect(cubit.state.name, 'Alex Morgan');
    expect(cubit.state.styleSummary, 'Minimal • Smart casual');
    expect(cubit.state.plan, 'Free');
    expect(cubit.state.productNotifications, isFalse);
  });

  test('togglePreference adds then removes', () {
    cubit.togglePreference(PreferenceField.styles, 'Bold');
    expect(cubit.state.styles, contains('Bold'));
    cubit.togglePreference(PreferenceField.styles, 'Bold');
    expect(cubit.state.styles, isNot(contains('Bold')));
    cubit.togglePreference(PreferenceField.occasions, 'Travel');
    expect(cubit.state.occasions, contains('Travel'));
  });

  test('setters update state', () {
    cubit.updateDetails('Sam', 's@x.com');
    cubit.setDailyNotifications(false);
    cubit.setPlannedNotifications(false);
    cubit.setProductNotifications(true);
    cubit.setWeatherConsent(false);
    cubit.setClimate('Cold');
    cubit.setPlan('Plus');
    cubit.setBillingCycle('monthly');
    final s = cubit.state;
    expect((s.name, s.email), ('Sam', 's@x.com'));
    expect((s.dailyNotifications, s.plannedNotifications), (false, false));
    expect((s.productNotifications, s.weatherConsent), (true, false));
    expect((s.climate, s.plan, s.billingCycle), ('Cold', 'Plus', 'monthly'));
  });
}
