/// One of the five `/intro` slides (prototype `intro` array, app.js:288).
class IntroSlide {
  const IntroSlide({
    required this.title,
    required this.description,
    this.image,
    this.maxImageWidth = 1,
    this.heightFraction = .4,
    this.minHeight = 0,
    this.topMargin = 10,
    this.isOccasions = false,
  });

  /// May contain a newline (rendered as the prototype `<br>`).
  final String title;
  final String description;
  final String? image;

  /// Fraction of the available width the picture may use.
  final double maxImageWidth;

  /// `.ob-illustration` height as a fraction of the page height.
  final double heightFraction;
  final double minHeight;
  final double topMargin;
  final bool isOccasions;
}

const introSlides = <IntroSlide>[
  IntroSlide(
    title: 'Your wardrobe.\nSmarter.',
    description:
        'Organize every outfit and get AI-powered styling recommendations in seconds.',
    image: 'onboard-01-model.png',
    maxImageWidth: .92,
    heightFraction: .45,
    minHeight: 238,
  ),
  IntroSlide(
    title: 'Scan it once.\nFind it anytime.',
    description:
        'Store shirts, pants, shoes, watches, bags, and accessories in one organized place.',
    image: 'onboard-02-closet.png',
    maxImageWidth: .94,
    heightFraction: .43,
    minHeight: 225,
  ),
  IntroSlide(
    title: 'Let AI style you.',
    description:
        'Pick one item and receive complete outfit suggestions tailored to your wardrobe.',
    image: 'onboard-03-style.png',
    maxImageWidth: .84,
    heightFraction: .35,
    minHeight: 180,
    topMargin: 8,
  ),
  IntroSlide(
    title: 'Tell us where\nyou’re going.',
    description: 'We’ll personalize recommendations\nbased on the occasion.',
    isOccasions: true,
  ),
  IntroSlide(
    title: 'Never wonder\n“What should I wear?”',
    description: 'Smart outfits for every you.',
    image: 'onboard-04-outfit.png',
    maxImageWidth: .92,
    heightFraction: .42,
    minHeight: 220,
  ),
];

/// Occasion rows on slide 4 (glyph, name), app.js:307.
const introOccasions = <(String, String)>[
  ('▣', 'Office'),
  ('♧', 'Wedding'),
  ('♥', 'Date Night'),
  ('☼', 'Casual Day Out'),
  ('✧', 'Party'),
  ('♙', 'Interview'),
  ('⌂', 'Vacation'),
];

const personalizeStyles = <String>[
  'Minimal & clean',
  'Smart casual',
  'Elegant & polished',
  'Relaxed & comfy',
  'Colorful & bold',
];

const personalizeChips = <String>[
  'Everyday',
  'Office',
  'Wedding',
  'Party',
  'Travel',
];
