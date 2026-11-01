import '../../../shared/models/genders.dart';

/// One of the five `/intro` slides (prototype `intro` array, app.js:288).
///
/// F24: image-bearing slides carry their male values in [title] /
/// [description] / [image] and their female values in [femaleTitle] /
/// [femaleDescription] / [femaleImage]. Layout fields are shared per index.
/// Resolve a slide for a gender with [forGender] or [introSlidesFor].
class IntroSlide {
  const IntroSlide({
    required this.title,
    required this.description,
    this.image,
    this.femaleTitle,
    this.femaleDescription,
    this.femaleImage,
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

  /// Female-path overrides (F24, D4/D6). `null` = same as the male value
  /// (the shared occasion slide carries none of them).
  final String? femaleTitle;
  final String? femaleDescription;
  final String? femaleImage;

  /// Fraction of the available width the picture may use.
  final double maxImageWidth;

  /// `.ob-illustration` height as a fraction of the page height.
  final double heightFraction;
  final double minHeight;
  final double topMargin;
  final bool isOccasions;

  /// This slide resolved for [gender] (male values, or female values where
  /// set). Throws [ArgumentError] if [gender] is not in [Genders.values].
  IntroSlide forGender(String gender) {
    if (!Genders.values.contains(gender)) {
      throw ArgumentError.value(gender, 'gender', 'must be one of ${Genders.values}');
    }
    final female = gender == Genders.female;
    return IntroSlide(
      title: female ? (femaleTitle ?? title) : title,
      description: female ? (femaleDescription ?? description) : description,
      image: female ? (femaleImage ?? image) : image,
      maxImageWidth: maxImageWidth,
      heightFraction: heightFraction,
      minHeight: minHeight,
      topMargin: topMargin,
      isOccasions: isOccasions,
    );
  }
}

/// All five slides resolved for [gender]; throws [ArgumentError] like
/// [IntroSlide.forGender].
List<IntroSlide> introSlidesFor(String gender) =>
    [for (final slide in introSlides) slide.forGender(gender)];

const introSlides = <IntroSlide>[
  IntroSlide(
    title: 'Your wardrobe.\nSmarter.',
    description:
        'Organize every outfit and get AI-powered styling recommendations in seconds.',
    image: 'onboard-01-model.png',
    femaleTitle: 'Your style.\nYour rules.',
    femaleDescription:
        'Turn the pieces you already own into standout looks, styled by AI in seconds.',
    femaleImage: 'onboard-f01-wardrobe.png',
    maxImageWidth: .92,
    heightFraction: .45,
    minHeight: 238,
  ),
  IntroSlide(
    title: 'Scan it once.\nFind it anytime.',
    description:
        'Store shirts, pants, shoes, watches, bags, and accessories in one organized place.',
    image: 'onboard-02-closet.png',
    femaleTitle: 'Scan it once.\nStyle it forever.',
    femaleDescription:
        'Dresses, tops, trousers, shoes, bags and jewelry, beautifully organized in one place.',
    femaleImage: 'onboard-f02-closet.png',
    maxImageWidth: .94,
    heightFraction: .43,
    minHeight: 225,
  ),
  IntroSlide(
    title: 'Let AI style you.',
    description:
        'Pick one item and receive complete outfit suggestions tailored to your wardrobe.',
    image: 'onboard-03-style.png',
    femaleTitle: 'Effortless looks,\non demand.',
    femaleDescription:
        'Pick one piece you love and get complete outfits built around it.',
    femaleImage: 'onboard-f03-style.png',
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
    femaleTitle: 'Dress for how\nyou want to feel.',
    femaleDescription: 'Outfits for every version of you.',
    femaleImage: 'onboard-f04-outfit.png',
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
