import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/onboarding_page_data.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit()
      : super(OnboardingState(pageCount: OnboardingPageData.pages.length));

  void onPageChanged(int index) {
    emit(state.copyWith(currentPage: index));
  }

  void goToPage(int index) {
    emit(state.copyWith(currentPage: index));
  }
}
