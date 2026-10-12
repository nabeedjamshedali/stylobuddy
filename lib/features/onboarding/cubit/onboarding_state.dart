class OnboardingState {
  final int currentPage;
  final int pageCount;

  const OnboardingState({
    this.currentPage = 0,
    required this.pageCount,
  });

  bool get isLastPage => currentPage == pageCount - 1;

  OnboardingState copyWith({
    int? currentPage,
    int? pageCount,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      pageCount: pageCount ?? this.pageCount,
    );
  }
}
