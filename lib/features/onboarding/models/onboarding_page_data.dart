/// Which visual layout an onboarding page uses. Each maps to a distinct
/// widget under `widgets/` since the three reference screens have
/// different content shapes (hero portrait+card, product carousel,
/// product detail card).
enum OnboardingLayout { heroUpload, aiStylist, curatedPicks }

class OnboardingPageData {
  final OnboardingLayout layout;
  final String headline;
  final String headlineAccentWord;
  final String subtitle;
  final String ctaLabel;

  const OnboardingPageData({
    required this.layout,
    required this.headline,
    required this.headlineAccentWord,
    required this.subtitle,
    required this.ctaLabel,
  });

  /// Splits [headline] into the parts before/after [headlineAccentWord] so
  /// the widget can render the accent word in the brand color, matching
  /// the reference ("Redefine Your **Style** with AI").
  List<String> get headlineParts => headline.split(headlineAccentWord);

  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      layout: OnboardingLayout.heroUpload,
      headline: 'Redefine Your Style with AI',
      headlineAccentWord: 'Style',
      subtitle: 'Smart recommendations. Tailored to you.',
      ctaLabel: 'Next',
    ),
    OnboardingPageData(
      layout: OnboardingLayout.aiStylist,
      headline: 'Meet Your Personal AI Stylist',
      headlineAccentWord: 'AI Stylist',
      subtitle:
          'Try on looks in 360°, mix pieces, and describe the vibe you want.',
      ctaLabel: 'Next',
    ),
    OnboardingPageData(
      layout: OnboardingLayout.curatedPicks,
      headline: 'Shop Your Perfect Match',
      headlineAccentWord: 'Perfect Match',
      subtitle: 'Curated pieces picked for your fit, color, and budget.',
      ctaLabel: 'Get Started',
    ),
  ];
}
