import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState());

  void updateDetails(String name, String email) =>
      emit(state.copyWith(name: name, email: email));

  void togglePreference(PreferenceField field, String value) {
    final current = field == PreferenceField.styles
        ? state.styles
        : state.occasions;
    final next = current.contains(value)
        ? current.where((v) => v != value).toList()
        : [...current, value];
    emit(
      field == PreferenceField.styles
          ? state.copyWith(styles: next)
          : state.copyWith(occasions: next),
    );
  }

  void setDailyNotifications(bool v) =>
      emit(state.copyWith(dailyNotifications: v));
  void setPlannedNotifications(bool v) =>
      emit(state.copyWith(plannedNotifications: v));
  void setProductNotifications(bool v) =>
      emit(state.copyWith(productNotifications: v));
  void setWeatherConsent(bool v) => emit(state.copyWith(weatherConsent: v));
  void setClimate(String v) => emit(state.copyWith(climate: v));
  void setPlan(String v) => emit(state.copyWith(plan: v));
  void setBillingCycle(String v) => emit(state.copyWith(billingCycle: v));
}
