# F24 — Gender-Segregated Onboarding + `Profile.gender`

> Adds a required gender-choice screen (`/gender`, `GenderChoiceView`) between
> `/welcome` and `/intro`. The four image-bearing intro slides (indices 0, 1, 2
> and 4) become gender-parametrized: the same five-slide list, with female
> art and a more confident, self-expression copy register on the female
> path. The occasion slide (index 3) stays shared. The choice is carried
> across sign-in by the existing `PendingOnboardingSelections` holder and
> lands on a new nullable `ProfileState.gender` field through the existing
> D5 bootstrap seed write (`FirestoreProfileRepository.bootstrapIfNeeded`).
> The male path's images and copy do not change. Guest mode and "Skip
> introduction" keep working with no gender asked. Source of truth for scope
> and decisions D1-D8:
> `docs/superpowers/specs/2026-10-22-gender-onboarding-design.md`. Depends on
> F02 (onboarding routes, `OnboardingCubit`, `IntroView`,
> `OnboardingBackScope`), F18 (`ProfileRepository` dual mode,
> `PendingOnboardingSelections`, bootstrap seeding) and F22 (the
> `users/{uid}` key allowlist in `firestore.rules`, which must admit the new
> key or the bootstrap transaction is denied as a whole). Foundation: 03
> (amendment required, §13 P1), 05, 06, 07.

**Status:** DONE (gates 1-3; gate 4 — A39/A40 `[L]` — pending) · **Milestone:** 3 · **Depends on:** F02, F18, F22

---

## 1. Goal

Today a woman opening StyloBuddy sees only menswear art and reads it as a
men's app. This feature lets the user say who they are styling for in one
tap before the intro. Every intro picture after that point then matches the
choice. A signed-in user's profile remembers the choice so a later feature
(not this one) can tune recommendations by it. The male path stays exactly
as it is. The female path must be at least as polished: four distinct,
clean images and copy written to sell confidence, not only storage.

## 2. MVP scope

- **New route** `AppRoutes.gender = '/gender'`, added to
  `AppRoutes.noNavRoutes` and registered inside the existing onboarding
  `ShellRoute` (`onboarding_routes.dart`) between `welcome` and `intro`, so
  it shares the one `OnboardingCubit` instance.
- **New screen** `GenderChoiceView` (`lib/features/onboarding/view/gender_choice_view.dart`)
  plus a `GenderCard` widget (`lib/features/onboarding/widgets/gender_card.dart`).
  Exact copy (adapted from prototype `app.js:307-311`):

  | Element | Text |
  |---|---|
  | Overline | `YOUR STYLE PROFILE` |
  | Title | `Who are you\nstyling for?` |
  | Body | `Choose your wardrobe profile for relevant outfits and clothing categories.` |
  | Card 1 (`Key('gender-card-male')`) | `Male` / `Menswear and outfit inspiration` / image `onboard-gender-male.png` |
  | Card 2 (`Key('gender-card-female')`) | `Female` / `Womenswear and outfit inspiration` / image `onboard-gender-female.png` |
  | Primary button | `Continue`, semantics label `Continue →` (same `ObPrimaryButton` arrow convention as Welcome) |
  | Text button | `Back` |
  | Toast when Continue is tapped with no choice | `Choose Male or Female to continue` |

  Cards are single-select. Tapping a card selects it and never navigates.
  Tapping the selected card again keeps it selected (radio, not toggle).
  The layout follows the existing onboarding visual language
  (`ObPrimaryButton`, `ObTextButton`, `OnboardingTokens`). The exact card
  layout is an implementation call (design doc, "what's left to the
  builder"). It must give the two cards identical size, weight and
  treatment (anti-goal: female path not visually weaker).
- **Required choice (D7).** The gender screen cannot be skipped. "Skip
  introduction" on `/welcome` still bypasses the whole flow and never
  reaches `/gender`.
- **`OnboardingCubit` / `OnboardingState` (D2, D3).**
  - `OnboardingState.gender: String?`, default `null`.
  - `OnboardingCubit.setGender(String gender)` accepts only `Genders.male`
    / `Genders.female`. It emits the new state and forwards the value to
    `PendingOnboardingSelections.setGender`. Any other value throws
    `ArgumentError` and changes nothing.
  - `start()` is unchanged: it resets `slide` to 0 and `exit` to `none`, and
    it does **not** clear `gender`.
  - `OnboardingExit.backToWelcome` is **renamed** `backToGender`. `back()` on
    slide 0 now emits `backToGender`, and `IntroView` navigates to
    `/gender` for it (prototype `app.js:330`: intro Back on slide 1 goes to
    `gender`). This resolves the design doc's one open UX item. F02-A01 and
    F02-A11 are amended accordingly (dated 2026-10-22).
- **One parametrized slide list (D4).** `intro_slide.dart` keeps exactly one
  `const introSlides` list of 5 entries. Each image-bearing entry carries
  its male values in the existing `title`/`description`/`image` fields and
  its female values in new `femaleTitle`/`femaleDescription`/`femaleImage`
  fields. The occasion entry carries none of them. Layout fields
  (`maxImageWidth`, `heightFraction`, `minHeight`, `topMargin`) are shared
  per index. New public API: `IntroSlide.forGender(String gender)` returns
  a resolved `IntroSlide`, and `List<IntroSlide> introSlidesFor(String
  gender)` returns all 5 resolved slides. `IntroView` renders
  `introSlidesFor(state.gender!)[state.slide]`. `IntroIllustration` and
  `IntroHeadline` are unchanged.
- **Female copy (D6), drafted here for batch review.** The male copy stays
  byte-identical to today's.

  | Index (counter) | Male (unchanged) title / description / image | Female title / description / image |
  |---|---|---|
  | 0 (`1/5`) | `Your wardrobe.\nSmarter.` / `Organize every outfit and get AI-powered styling recommendations in seconds.` / `onboard-01-model.png` | `Your style.\nYour rules.` / `Turn the pieces you already own into standout looks, styled by AI in seconds.` / `onboard-f01-wardrobe.png` |
  | 1 (`2/5`) | `Scan it once.\nFind it anytime.` / `Store shirts, pants, shoes, watches, bags, and accessories in one organized place.` / `onboard-02-closet.png` | `Scan it once.\nStyle it forever.` / `Dresses, tops, trousers, shoes, bags and jewelry, beautifully organized in one place.` / `onboard-f02-closet.png` |
  | 2 (`3/5`) | `Let AI style you.` / `Pick one item and receive complete outfit suggestions tailored to your wardrobe.` / `onboard-03-style.png` | `Effortless looks,\non demand.` / `Pick one piece you love and get complete outfits built around it.` / `onboard-f03-style.png` |
  | 3 (`4/5`) | `Tell us where\nyou’re going.` / `We’ll personalize recommendations\nbased on the occasion.` / none (`isOccasions`) | **shared, identical to male** |
  | 4 (`5/5`) | `Never wonder\n“What should I wear?”` / `Smart outfits for every you.` / `onboard-04-outfit.png` | `Dress for how\nyou want to feel.` / `Outfits for every version of you.` / `onboard-f04-outfit.png` |

  Tone parity check: each female line keeps the male line's shape (two
  short title lines, one description of roughly 45-90 characters). It
  replaces functional wording with the D6 register: "your style, your
  rules", "effortless", "dress for how you want to feel". Every female
  description is no longer than its male counterpart plus 5 characters, so
  the existing layout fractions hold without per-gender tuning.
- **Assets (D5), filenames locked.** See §8 for sources and the spot-check
  result that changed two of D5's picks.
- **Null-gender guard on `/intro`.** If `IntroView` builds with
  `state.gender == null` (a cold deep link, or a test pumping `/intro`
  directly), it renders an empty white `Scaffold`, navigates to `/gender`
  once after the first frame, and never renders a slide. This is a routing
  guard, not a fallback rendering path, so D7's "no null rendering path"
  holds.
- **Hardware back (D8).** `OnboardingBackScope` gains a `/gender` branch:
  `context.go(AppRoutes.welcome)`. `canPop` stays `true` only for
  `/welcome`.
- **`ProfileState.gender: String?` (D1)**, default `null`, with no setter in
  `ProfileCubit` and no method on `ProfileRepository`. It is written only by
  the bootstrap seed and read by `watchProfile()`.
- **`PendingOnboardingSelections`** gains a separate gender slot:
  `setGender(String)`, `String? consumeGender()` (read then clear the gender
  slot only), `@visibleForTesting String? get genderForTest`. The existing
  `consume()` keeps its exact signature and behaviour: it returns the
  occasions/chips union, clears occasions/chips, and leaves gender
  untouched. `clear()` resets all three slots.
- **`FirestoreProfileRepository`.**
  - `_fromFirestore` reads `gender` with a nullable variant of
    `_stringField`. A missing key or explicit `null` reads as `null`. Any
    present string, including `''`, reads back verbatim.
  - `_toFirestore` includes `'gender'` **only when** `state.gender` is
    non-null.
  - `bootstrapIfNeeded` gains a named `String? gender` parameter. A value
    outside `Genders.values` is treated as `null`, meaning the key is
    omitted. Writing it would make the `firestore.rules` allowlist deny the
    whole 27-write bootstrap transaction, so the value is dropped rather
    than written. The existing absent-keys-only rule (F18 Important #5)
    applies to `gender` unchanged.
- **`lib/app.dart`.** The signed-in `ProfileCubit` branch calls
  `PendingOnboardingSelections.consumeGender()` exactly once, next to the
  existing `consume()`, and passes the result as `gender:` to
  `bootstrapIfNeeded`. The guest branch calls neither, which is unchanged.
- **`firestore.rules`.** The `users/{uid}` `hasOnly` list gains `'gender'`
  plus the check `(!('gender' in request.resource.data) ||
  request.resource.data.gender in ['male', 'female'])`.
- **Shared constants** `lib/shared/models/genders.dart`:
  `abstract final class Genders { static const male = 'male'; static const
  female = 'female'; static const values = <String>{male, female}; }`. Both
  the onboarding feature and the profile repository use these, so neither
  feature imports the other.

## 3. Later scope

- Editing gender after onboarding (e.g. on `/edit-style` or `/profile`).
  The prototype's "You can change this later." line is therefore
  **dropped** from the body copy, because promising an edit path that does
  not exist would be a false claim (§12).
- Backfilling `gender` onto an already-seeded (returning) user. The
  bootstrap is a no-op for them, the same as occasions today (F18 §8 "no
  migration").
- Writing a chosen gender into a **guest's** in-memory `ProfileState`.
  Guests stay `gender == null`. D2 scopes consumption to the Firestore
  bootstrap only.
- Any consumer of `ProfileState.gender` (recommendation tuning, gendered
  seed wardrobe, theming). Non-goal in the design doc.
- A gender-neutral Welcome hero. `/welcome` keeps `onboard-00-rack.png`; the
  prototype's `neutral-landing.png` is a candidate for a later pass.
- Firebase Analytics events for the gender choice. Not added. Gender is
  personal data, so any analytics use needs its own decision.
- Any third option ("prefer not to say" / non-binary). The design doc fixes
  `'male' | 'female' | null` (D1). Flagged in §13 Q1 as a product question,
  not decided here.

## 4. Roles and permissions

Uses the guest and authenticated roles from `docs/foundation/07-security.md`.
Guests and authenticated users see the same onboarding screens. Only the
`uid != null` branch persists gender, and only into the owner's own
`users/{uid}` document (F14-A11 path isolation, F22 owner-only rules). No
user can read or write another user's `gender`: the F22-A09/A10 cross-user
and signed-out denials cover the whole document, the new key included. No
new permission surface.

## 5. Main flows

```text
Female path, new user, signs in with Google:
  /welcome "Get Started" -> OnboardingCubit.start() -> context.go('/gender')
  /gender: no card selected; tap Continue -> toast 'Choose Male or Female to continue', stay
  tap Female card -> OnboardingCubit.setGender('female')
       -> state.gender = 'female'; PendingOnboardingSelections.setGender('female'); stay on /gender
  tap Continue -> context.go('/intro') -> slide 0 renders introSlidesFor('female')[0]
  Continue x3 (slide 3 = shared occasion picker) -> slide 4 "Create My Wardrobe"
       -> exit finished -> /personalize -> Continue -> /auth -> Google sign-in succeeds
  uid flips -> app.dart signed-in subtree -> ProfileCubit create:
       pendingOccasions = PendingOnboardingSelections.consume()      (unchanged)
       pendingGender    = PendingOnboardingSelections.consumeGender() (new, clears the slot)
       repository.bootstrapIfNeeded(pendingOccasions:, gender: pendingGender, name:, email:, seedWriter:)
       -> runBootstrapIfNeeded tx: users/{uid} gets the 13-key payload + gender:'female' + seeded:true
  ProfileCubit's first watchProfile() emission: gender == 'female'

Male path: identical with 'male'; slides render today's exact images and copy.

Back navigation (in-app Back and Android hardware back behave the same at every step):
  /welcome      hardware back: PopScope canPop = true (leaves the app, unchanged)
  /gender       Back -> /welcome           (gender kept in OnboardingCubit; Get Started again shows it selected)
  /intro s>0    Back -> slide s-1          (unchanged)
  /intro s=0    Back -> cubit.back() -> exit backToGender -> /gender (previous card still selected)
  /personalize  ‹ / hardware -> /intro     (unchanged; slide and gender kept)

Skip paths:
  /welcome "Skip introduction" -> /auth; /gender never shown; holder gender untouched
       (null unless set earlier in this same process; see §12)
  /intro "Skip" -> /personalize; gender already set (Skip is only reachable after /gender)

Guest finishes onboarding then "Skip for now":
  uid stays null -> guest ProfileCubit(InMemoryProfileRepository) -> ProfileState.gender == null
  holder gender NOT consumed (guest branch never consumes; unchanged F18 behaviour)

Returning (already seeded) user picks a gender on a fresh install, then signs in:
  consumeGender() still clears the holder -> bootstrapIfNeeded -> seeded already true -> no write
  -> users/{uid} keeps whatever gender it had (absent stays absent; no backfill)

Null-gender guard:
  /intro built with state.gender == null -> blank white Scaffold -> post-frame context.go('/gender')

Failure: bootstrap transaction fails (offline, rules) -> existing catchError in app.dart logs in
  debug; gender is lost together with occasions (same failure surface as F18, not new)
```

## 6. Interface surface

```text
AppRoutes.gender = '/gender'                     (in AppRoutes.noNavRoutes)
GoRoute(path: AppRoutes.gender, builder: GenderChoiceView)   inside onboarding ShellRoute

Genders { male = 'male'; female = 'female'; values = {male, female} }   lib/shared/models/genders.dart

OnboardingState { ...; String? gender }                   copyWith(gender:) keeps `gender ?? this.gender`
enum OnboardingExit { none, finished, backToGender }      (backToWelcome removed)
OnboardingCubit
  void setGender(String gender)        throws ArgumentError if gender ∉ Genders.values
  void back()                          slide 0 -> exit backToGender (was backToWelcome)
  void start()                         unchanged (slide 0, exit none; gender preserved)

IntroSlide { ...existing; String? femaleTitle; String? femaleDescription; String? femaleImage;
             IntroSlide forGender(String gender) }       throws ArgumentError if gender ∉ Genders.values
List<IntroSlide> introSlidesFor(String gender)           5 resolved slides; same ArgumentError
const introSlides                                        still the single source list (5 entries)

PendingOnboardingSelections
  static void setGender(String value)
  static String? consumeGender()                          returns then clears the gender slot only
  static Set<String> consume()                            UNCHANGED (does not touch gender)
  static void clear()                                     resets occasions, chips AND gender
  @visibleForTesting static String? get genderForTest

ProfileState { ...existing 11; String? gender = null }   copyWith(gender:) keeps `gender ?? this.gender`
ProfileRepository                                        UNCHANGED (no gender method)
FirestoreProfileRepository.bootstrapIfNeeded({..., String? gender})
firestore.rules users/{uid}: hasOnly + 'gender'; gender in ['male','female'] when present
```

Widget keys and semantics (binding for tests): `Key('gender-card-male')` and
`Key('gender-card-female')` each wrap a `Semantics(button: true, selected:
<isChosen>, label: '<Male|Female>')` node. On `/gender`, the `Continue`
button's semantics node has `enabled: false` while `state.gender == null`
and `enabled: true` otherwise. `ObPrimaryButton` may gain an optional
`enabled` flag (default `true`) to express this. Tapping it while disabled
still runs the "show toast, stay" path. No existing call site changes.

## 7. Domain model usage

- `ProfileState`: adds `gender: String? = null` (`'male' | 'female' | null`;
  `null` = never chosen). Added to `docs/foundation/03-domain-model.md`
  2026-10-22 per §13 P1 before implementation began, satisfying 03 §5.
- `OnboardingState`: adds `gender: String?`. `OnboardingState` is
  feature-local and not listed in 03, the same status as `chosenOccasions`
  today.
- All other `ProfileState` fields are read and written unchanged.
- Missing versus empty for `ProfileState.gender` (proposed new row for 03
  §4): a missing key or explicit `null` means "never chosen" and reads as
  `null`. `''` is never produced by any write path (`setGender` and the
  rules reject it). If it is present anyway (rules bypass or legacy), it is
  read back verbatim as `''` and is not coerced to `null`, matching the
  `climate`/`plan` precedent (F18-A19).

## 8. Data changes

- **Firestore `users/{uid}`:** new optional key `gender` (string, `'male'`
  or `'female'`). It is written only by the D5 bootstrap seed when a valid
  gender was pending. No migration and no backfill. Existing documents
  without the key read as `gender == null`.
- **`firestore.rules`:** the `users/{uid}` allowlist grows from 13 to 14
  keys, and the new key gets the value-set check. The production deploy
  stays deferred under F22-A50..A53. When that deploy happens it must ship
  the F24-amended file, and F22's pre-deploy audit (A50) must treat
  `gender` as an allowed key. A dated note is added to F22 §7.
- **Schema doc** `docs/superpowers/specs/2026-10-19-firestore-schema.md` §1
  needs the same one-line addition. It is listed under §13 P1 with the
  foundation amendment.
- **Assets.** Copied into this project's `assets/onboarding/` folder, which
  is already declared in `pubspec.yaml`, so no pubspec change is needed.
  Files are referenced through `AppAssets.onboarding(file)`. Naming
  follows the existing `onboard-NN-<subject>.png` convention, with an `f`
  prefix on the number for the female variants:

  | Asset (new, `assets/onboarding/`) | Source (`stylobuddy-prototype/assets/onboarding/`) | Treatment |
  |---|---|---|
  | `onboard-f01-wardrobe.png` | `v25/female-wardrobe.png` | copy as-is (clean rack composition, opaque white background) |
  | `onboard-f02-closet.png` | `v27/female-closet.png` | copy as-is (transparent RGBA) |
  | `onboard-f03-style.png` | `v26/female-match.png` | crop away the top band carrying the baked-in caption fragment ("…suggestions tailored to your wardrobe."). The crop line sits below the lowest caption pixel and above the blazer/trouser tops (roughly the top 6% of the height). Keep everything else, preserve aspect, no rescale needed |
  | `onboard-f04-outfit.png` | `v27/female-finale.png` | copy as-is (transparent RGBA) |
  | `onboard-gender-male.png` | `v27/male-card.png` | copy as-is |
  | `onboard-gender-female.png` | `v27/female-card.png` | copy as-is |

  Optional optimisation: any file may be downscaled (aspect preserved) to
  no less than 900 px on its long edge, or losslessly recompressed. No
  other edits are allowed. The crop is a one-off file operation using
  whatever tool the implementer has. No cropping code is committed.

  **Why two of D5's v27 picks were replaced (spot-check, 2026-10-22).**
  `v27/ASSET-MAP.md` shows the v27 female set was built from only two
  source images. Viewing the files confirms it: `female-style.png` is the
  same picture as `female-closet.png`, and `female-match.png` is the same
  picture as `female-finale.png` (and as `female-card.png`). Using v27
  as-is would show each picture twice across four slides, which breaks the
  "female path not visually weaker" anti-goal. `v26/female-wardrobe.png`
  has the progress dots baked into its bottom edge, so the identical but
  clean `v25/female-wardrobe.png` is used for slide 0. `v26/female-match.png`
  is the only distinct "AI matching" female composition (a blouse at the
  centre with arrows to blazer, jeans, trousers, bag and accessories). It
  needs the caption crop. `v27/female-finale.png` was already approved in
  the design doc. `v27/female-closet.png` is clean. F24-A19 enforces the
  distinctness mechanically. F24-A39 checks halos and crop quality on a
  device.
- **`docs/image-prompts.md`:** gains two contingency prompts. One is an
  upgrade for `onboard-f03-style.png`, in case the cropped screenshot-
  derived art looks soft on device. The other is a replacement for
  `onboard-f04-outfit.png`, in case its v27 edge halos (the known V26/V27
  QA caveat) show at in-app size. Neither prompt blocks the build. They are
  for the user to run if F24-A39 fails visually.

## 9. Background work and events

None new. The gender rides inside the existing single `runBootstrapIfNeeded`
transaction, so it has the same retry, idempotency and `seeded`-guard
behaviour as F14/F18. No analytics event is emitted (§3).

## 10. Degradation and failure

- **Continue tapped with no choice:** no navigation, toast `Choose Male or
  Female to continue`, state unchanged (A10).
- **`setGender` with an invalid value:** `ArgumentError` is thrown and
  neither the state nor the holder changes (A04). The UI can only pass the
  two constants, so this guards programmer error only.
- **`/intro` reached with `gender == null`:** redirect to `/gender` and no
  slide rendered (A20).
- **A gender asset fails to load:** `ObPhoto`'s existing `errorBuilder`
  renders `SizedBox.shrink()` and the copy still shows. This is unchanged
  behaviour. A19 guarantees at test time that every file exists.
- **Bootstrap given an invalid or `''` gender:** the key is omitted and the
  rest of the seed proceeds (A29). The value is dropped so that it cannot
  get the whole transaction denied by the rules.
- **Bootstrap transaction fails:** the existing `catchError` in `app.dart`
  logs in debug. Gender is lost exactly like the pending occasions. This is
  the existing F18 failure surface, not a new one.
- **Returning user:** no backfill. `gender` stays absent and reads `null`
  (A30, A34).
- **Legacy or rules-bypass document with `gender: ''`:** read back as `''`,
  not `null` (A28). With `gender: 7` (non-string), the read throws inside
  the `watchProfile()` mapping, the same as `climate: 7` today, and
  `ProfileCubit`'s existing `onError` handler (F18-A15) absorbs it. No new
  handling is added.

## 11. Validation assertions

```
F24-A01  [U]  Genders.male == 'male', Genders.female == 'female', Genders.values == {'male', 'female'} (exactly two members)
F24-A02  [U]  A fresh OnboardingCubit has state.gender == null; after PendingOnboardingSelections.clear(), genderForTest == null
F24-A03  [U]  setGender('female') sets state.gender to 'female' and PendingOnboardingSelections.genderForTest to 'female'; a following setGender('male') sets both to 'male' (last wins); neither call changes state.slide, state.exit, state.chosenOccasions or state.chosenChips, nor the holder's chosenOccasionsForTest/chosenChipsForTest
F24-A04  [U]  setGender('') , setGender('Female') and setGender('other') each throw ArgumentError; after each, state.gender and genderForTest equal their prior value (null on a fresh cubit; 'male' when setGender('male') ran first) and no new state is emitted
F24-A05  [U]  start() preserves gender: setGender('female'), next() twice, start() -> slide == 0, exit == OnboardingExit.none, gender == 'female'
F24-A06  [U]  OnboardingExit.values is exactly [none, finished, backToGender]; back() on slide 0 emits exit == OnboardingExit.backToGender with slide still 0; back() on slide 2 moves to slide 1 with exit none
F24-A07  [U]  PendingOnboardingSelections slot independence: after setChosenOccasions({'Office'}) and setGender('female'): consume() returns {'Office'} and genderForTest is still 'female'; consumeGender() then returns 'female' and a second consumeGender() returns null; consumeGender() never alters chosenOccasionsForTest/chosenChipsForTest; clear() after setting all three slots leaves all three empty/null; consumeGender() on a never-set holder returns null
F24-A08  [U]  AppRoutes.gender == '/gender' and AppRoutes.noNavRoutes contains it; pumping /gender renders 'YOUR STYLE PROFILE', 'Who are you\nstyling for?', 'Choose your wardrobe profile for relevant outfits and clothing categories.', 'Male', 'Menswear and outfit inspiration', 'Female', 'Womenswear and outfit inspiration', 'Continue' (semantics label 'Continue →'), 'Back'; the text 'You can change this later.' is absent; none of the bottom-nav labels (Home, Wardrobe, AI Stylist, Saved, Profile) is present
F24-A09  [U]  From /welcome, tapping 'Get Started' navigates to /gender (not /intro); on arrival with no earlier choice, the semantics nodes under Key('gender-card-male') and Key('gender-card-female') both report selected == false and OnboardingCubit.state.gender == null
F24-A10  [U]  On /gender with no choice, Continue's semantics node reports enabled == false; tapping 'Continue' leaves the location at /gender, shows the toast 'Choose Male or Female to continue', and leaves state.gender null; after a card is chosen, Continue's semantics node reports enabled == true
F24-A11  [U]  Tapping Key('gender-card-female') sets state.gender 'female', marks female selected == true and male selected == false, and the location stays /gender; tapping Key('gender-card-male') next flips both flags (exactly one selected at any time); tapping the already-selected card again leaves it selected and gender unchanged (radio, never toggle-off)
F24-A12  [U]  After choosing Female, 'Continue' navigates to /intro showing '1/5' and 'Your style.\nYour rules.'; after choosing Male instead, the same tap shows '1/5' and 'Your wardrobe.\nSmarter.'
F24-A13  [U]  The male card renders an Image whose AssetImage name is 'assets/onboarding/onboard-gender-male.png' and the female card one named 'assets/onboarding/onboard-gender-female.png'
F24-A14  [U]  introSlidesFor('male') returns 5 slides whose (title, description, image) are exactly: ('Your wardrobe.\nSmarter.', 'Organize every outfit and get AI-powered styling recommendations in seconds.', 'onboard-01-model.png'), ('Scan it once.\nFind it anytime.', 'Store shirts, pants, shoes, watches, bags, and accessories in one organized place.', 'onboard-02-closet.png'), ('Let AI style you.', 'Pick one item and receive complete outfit suggestions tailored to your wardrobe.', 'onboard-03-style.png'), ('Tell us where\nyou’re going.', 'We’ll personalize recommendations\nbased on the occasion.', null), ('Never wonder\n“What should I wear?”', 'Smart outfits for every you.', 'onboard-04-outfit.png'); slide index 3 has isOccasions == true (male path unchanged)
F24-A15  [U]  introSlidesFor('female') returns 5 slides whose (title, description, image) are exactly: ('Your style.\nYour rules.', 'Turn the pieces you already own into standout looks, styled by AI in seconds.', 'onboard-f01-wardrobe.png'), ('Scan it once.\nStyle it forever.', 'Dresses, tops, trousers, shoes, bags and jewelry, beautifully organized in one place.', 'onboard-f02-closet.png'), ('Effortless looks,\non demand.', 'Pick one piece you love and get complete outfits built around it.', 'onboard-f03-style.png'), ('Tell us where\nyou’re going.', 'We’ll personalize recommendations\nbased on the occasion.', null), ('Dress for how\nyou want to feel.', 'Outfits for every version of you.', 'onboard-f04-outfit.png'); slide index 3 has isOccasions == true
F24-A16  [U]  For every index 0-4, introSlidesFor('female')[i] and introSlidesFor('male')[i] have equal maxImageWidth, heightFraction, minHeight, topMargin and isOccasions, and the female description's length is <= the male description's length + 5; introSlidesFor('other') and IntroSlide.forGender('') throw ArgumentError; the source of lib/features/onboarding/models/intro_slide.dart contains exactly one '<IntroSlide>[' list literal (one parametrized list, not two, per the anti-drift anti-goal)
F24-A17  [U]  Widget test, per gender, at slide indices 0, 1, 2 and 4: the rendered title and description Text equal that gender's A14/A15 values, and the only onboarding Image on screen has AssetImage name 'assets/onboarding/<that gender's file>'; on the female path no male title or male slide asset name (onboard-01..04) appears at any slide, and on the male path no female title or onboard-f0x asset appears
F24-A18  [U]  On the female path, slide index 3 renders 'Tell us where\nyou’re going.', the identical description, and the same 7 occasion rows with the same glyphs as F02-A12, and no onboarding Image; tapping 'Office' there adds it to state.chosenOccasions and PendingOnboardingSelections.chosenOccasionsForTest exactly as on the male path
F24-A19  [U]  Every file named by introSlidesFor('male'), introSlidesFor('female') (non-null images) and the two card images exists on disk under assets/onboarding/; the four female slide files (f01-f04) are pairwise non-identical by byte content, and none is byte-identical to any of onboard-01-model.png, onboard-02-closet.png, onboard-03-style.png, onboard-04-outfit.png
F24-A20  [U]  Pumping the app directly at /intro (fresh shell, state.gender == null) ends, after pumpAndSettle, at /gender; at no frame does an IntroIllustration or IntroHeadline widget exist, and no exception is thrown. The same guard fires one hop later: pumping directly at /personalize (gender still null) and tapping '‹' also ends at /gender, not /intro (amends F02-A14, §13 P2)
F24-A21  [U]  In-app 'Back' on /gender navigates to /welcome; state.gender is kept (Female chosen before -> still 'female'); tapping 'Get Started' again lands on /gender with Female selected == true and Continue enabled == true
F24-A22  [U]  In-app 'Back' on intro slide 1/5 navigates to /gender with the earlier choice still selected; 'Back' on slides 5/5 -> 4/5 -> 3/5 -> 2/5 steps one slide each with the counter matching; state.gender never changes during any Back
F24-A23  [U]  Android hardware back (tester.binding.handlePopRoute) on the female path: on intro 3/5 -> 2/5 -> 1/5 -> /gender (Female still selected) -> /welcome; on /personalize -> /intro (unchanged F02-A14 behaviour) with state.gender unchanged
F24-A24  [U]  OnboardingBackScope's PopScope reports canPop == true for location '/welcome' and canPop == false for '/gender', '/intro' and '/personalize'
F24-A25  [U]  With nothing chosen in the process (holder cleared), /welcome 'Skip introduction' navigates to /auth, /gender is never visited, and genderForTest stays null; after choosing Female, Back to /welcome, then 'Skip introduction', genderForTest is still 'female' (last-state-wins, not cleared by skipping); intro 'Skip' from any slide goes to /personalize with state.gender unchanged
F24-A26  [U]  const ProfileState().gender == null; ProfileState(gender: 'female').copyWith(climate: 'Hot').gender == 'female'; ProfileState(gender: 'female').copyWith().gender == 'female'; every other ProfileState default is unchanged from F18 (name 'Alex Morgan' ... billingCycle 'yearly')
F24-A27  [U]  InMemoryProfileRepository().snapshot.gender == null and stays null after calling each of its 10 existing write methods once; neither profile_repository.dart nor in_memory_profile_repository.dart contains the substring 'gender' (no new interface method, guest never stores it)
F24-A28  [U]  FirestoreProfileRepository.watchProfile() against a fake users/uid-1 document: no 'gender' key -> gender null; 'gender': null -> null; 'gender': 'female' -> 'female'; 'gender': '' -> '' (not coerced to null, missing != empty); in all four cases the other 11 fields equal what F18-A01/A18/A19 already require
F24-A29  [U]  bootstrapIfNeeded(gender: 'female') on a brand-new document leaves its raw key set equal to exactly {name, email, styles, occasions, dailyNotifications, plannedNotifications, productNotifications, weatherConsent, climate, plan, billingCycle, wishlist, seeded, gender} with gender == 'female'; bootstrapIfNeeded() with no gender, and separately bootstrapIfNeeded(gender: 'other') and bootstrapIfNeeded(gender: ''), each leave the key set exactly the 13 keys of F18-A02 with no 'gender' key, and the rest of the seed is still written
F24-A30  [U]  bootstrapIfNeeded(gender: 'female') against a document that already has gender: 'male' and no seeded flag leaves gender == 'male' (absent-keys-only rule, F18 Important #5); against a document already seeded: true with no gender key it performs no write at all and gender stays absent (no backfill)
F24-A31  [U]  None of FirestoreProfileRepository's 10 existing write methods (updateDetails ... setBillingCycle) sends a payload containing a 'gender' key; after bootstrapIfNeeded(gender: 'female') followed by setClimate('Hot') the raw document still has gender == 'female'
F24-A32  [I]  Real StyloBuddyApp (uidStream/firestoreOverride harness, bounded polling, no bare pumpAndSettle wait for Firestore): as a guest, tap Get Started -> Female card -> Continue -> walk to /personalize via the UI, then emit uid 'uid-new'; polling the fake shows users/uid-new with seeded == true and gender == 'female', the resulting ProfileCubit.state.gender == 'female', and PendingOnboardingSelections.genderForTest == null afterwards
F24-A33  [I]  Same harness, guest taps 'Skip introduction' (no gender ever chosen, holder cleared at test start), then uid 'uid-skip' is emitted: users/uid-skip is seeded with no 'gender' key and ProfileCubit.state.gender == null
F24-A34  [I]  Same harness, users/uid-ret is pre-seeded (seeded: true, no gender); guest chooses Male via the UI, then uid 'uid-ret' is emitted: the document still has no 'gender' key and genderForTest == null (consumed even though nothing was written); then uid flips to null and then to 'uid-2' with no new choice: users/uid-2 is seeded with no 'gender' key (no leak across sign-ups)
F24-A35  [I]  Same harness, guest chooses Female via the UI then reaches /home through /auth 'Skip for now' with uid still null: the guest ProfileCubit (InMemoryProfileRepository) has state.gender == null and genderForTest is still 'female' (the guest branch does not consume)
F24-A36  [I]  Firestore emulator (F22 harness, project demo-stylobuddy): an owner create of users/alice with the 13-key bootstrap payload plus gender: 'female' succeeds and reads back identically; the same with gender: 'male' succeeds; a one-key merge-set {gender: 'female'} onto an existing valid document succeeds; F22-A07's 13-key create (no gender) still succeeds
F24-A37  [I]  Firestore emulator: each of gender: 'other', gender: '', gender: 'Female', gender: null and gender: 1 is denied with PERMISSION_DENIED both as a one-key merge-set onto a valid document and inside a full 13-key create; each denial is paired with the matching A36 allowed case per F22-A02
F24-A38  [I]  Firestore emulator: the F22-A47 27-write D5 bootstrap transaction, with gender: 'female' added to the users/alice payload, commits; read-back shows all 27 documents, seeded == true and gender == 'female'; the same transaction with gender: 'other' is denied as a whole (0 of 27 documents exist afterwards)
F24-A39  [L]  On a running Android debug build (emulator or device, portrait), walking welcome -> Get Started -> Female -> Continue -> all 5 slides -> personalize shows /gender with two equally sized and treated cards, then four visually distinct female images: no baked-in caption text on f03, no progress dots baked into any image, no visible colour halo or fringe at in-app size, and each image fully contained (no clipping); hardware back from 1/5 returns to /gender with Female selected; the Male walk shows images and copy identical to pre-F24 screenshots; screenshots of /gender and all 10 slide states (5 per gender) are attached to the completion block
F24-A40  [L]  Against the live Firestore project (stylobuddy-b7e46): a fresh Google test account that chose Female shows users/{uid}.gender == 'female' in the console after first sign-in; a second fresh account that used 'Skip introduction' has no gender field; both survive an app kill and relaunch. Runs in the same deferred live-verification pass as F18-A20; if F22's rules are deployed before then, the deployed file must be the F24-amended one
```

## 12. Edge cases

- **Choose Female, Back to Welcome, then "Skip introduction":** the holder
  keeps `'female'` and a later Google sign-in seeds it. This is
  last-state-wins, the same as occasions toggled then abandoned (F18 §12).
  The user did make the choice explicitly, so it is kept (A25).
- **Change gender mid-flow** (Female, slides 1-3, Back to `/gender`, Male,
  Continue): the intro restarts at slide 0, because Back from 1/5 is the
  only way into `/gender` from `/intro`. It renders the male set and the
  holder holds `'male'`. Occasions already toggled on slide 3 are kept,
  because they are gender-agnostic.
- **`/personalize` -> ‹ -> `/intro`:** same shell and same cubit, so slide
  and gender are kept and the guard does not fire.
- **A fresh onboarding shell lands on `/intro`** (deep link, or a router
  rebuild that recreates the `ShellRoute`): the guard sends the user to
  `/gender` (A20). There is never a male-art default.
- **Pre-existing F02 tests pump `/intro` directly.** After this change they
  land on `/gender` (A20). The F02 harness must reach `/intro` through
  `/gender` -> Male -> Continue. This is a test-harness change backed by the
  dated F02 amendments, not a weakened assertion.
- **The prototype shows a "1 / 2" step counter on the gender screen.** It
  is not ported: this app has no second step that it counts, and it would
  read as conflicting with the intro's `1/5`.
- **The prototype's "You can change this later."** is dropped, because no
  edit path exists (§3).
- **Two sign-ins in one process** (sign out, then a new account): the
  holder is consumed on the first signed-in construction, so the second
  account never inherits the first account's choice (A34).
- **The female card image is the same artwork as the female finale
  slide.** In v27 both come from one flat-lay. This is accepted: the
  male card is likewise drawn from the male flat-lay source. A19's
  distinctness rule covers the four slides, not the cards.
- **Text-scale / small screens (320-360 px wide):** layout fractions are
  shared per index (A16) and every female description is at most its male
  counterpart's length + 5 characters, so wrapping matches the male path.
  A39 is the visual check.

## 13. Open questions

**Preconditions (not product questions, mechanical, must be applied before
any code):**

- **P1 — Foundation amendment.** `docs/foundation/03-domain-model.md` must
  gain the field before it is used (03 §5). Proposed exact text, under
  `ProfileState` after the `billingCycle` line:
  `gender: String | None = None             # F24: 'male' | 'female'; null = never chosen (guest, skipped intro, or pre-F24 user). Written only by the D5 bootstrap seed; no setter.`
  And a new row in §4 "Missing versus empty":
  `| ProfileState.gender | missing key or null -> null ("never chosen") | '' is never written (setGender and rules reject it); if present it is read back verbatim as '', not coerced to null (F24-A28) |`
  The same key should be added to
  `docs/superpowers/specs/2026-10-19-firestore-schema.md` §1:
  `gender: string ('male' | 'female'), optional; absent = never chosen (F24)`.
  This document does not edit foundation files itself. It defers to
  whoever owns 03 under `08-agent-harness.md`.
- **P2 — Amendments to existing assertions** (applied with this document,
  dated 2026-10-22): F02-A01, F02-A08, F02-A09, F02-A10, F02-A11, F02-A27
  (the gender step now sits between `/welcome` and `/intro`), F02-A14 (the
  ‹/back-to-`/intro` behaviour now depends on a gender already being chosen
  in the same session; a cold `/personalize` → ‹ instead hits the
  null-gender guard and lands on `/gender`, covered by F24-A20's second
  sentence),
  F18-A02 (the key set gains `gender` when one was chosen), and a dated note
  under F22 §7 and F22-A07 (allowlist 13 -> 14 keys). No assertion is
  deleted.

**Product questions (non-blocking for this build):**

- **Q1 — A third option.** Design D1 fixes `'male' | 'female' | null`, and
  this document follows it. Whether a "prefer not to say" or neutral path
  is wanted (it would need a third art set or the neutral prototype art) is
  a product decision for later. `Genders.values` and the rules' value list
  are the two places it would change.
- **Q2 — Editing gender later** (§3). Needs its own feature document, which
  would add a `ProfileRepository.setGender` and widen F22's rules tests
  accordingly.
- **Q3 — Asset quality on device.** If A39 finds `onboard-f03-style.png`
  (cropped from screenshot-derived art) soft, or `onboard-f04-outfit.png`
  haloed, the contingency prompts in `docs/image-prompts.md` are for the
  user to run (project-hygiene image rule: Claude does not generate
  images). A replacement drops in under the same filename with no code
  change, and A19 re-verifies distinctness.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: DONE (gates 1-3) — 2026-10-22

[x] Gate 1  Interface documented
[x] Gate 2  Unit          A01-A31 (test/features/onboarding/f24_gender_model_test.dart,
                          f24_gender_screens_test.dart, test/features/profile/f24_profile_gender_test.dart)
[x] Gate 3  Integration   A32-A35 (test/f24_gender_wiring_test.dart, real StyloBuddyApp +
                          fake Firestore); A36-A38 (test/firestore_rules_test/gender_rules_test.dart,
                          Firestore emulator via scripts/run_firestore_rules_suite.sh, 58/58 green)
[ ] Gate 4  Live run      A39 (device screenshots) and A40 (live Firestore) deferred, same as
                          every other feature's [L] assertions. The expected A39 colour
                          halo/fringe risk on onboard-f03-style.png and onboard-f04-outfit.png
                          (the v26/v27 prototype art) was pre-empted 2026-10-22: both contingency
                          prompts from docs/image-prompts.md were run and the results (clean,
                          no visible halos) replace the prior files, plus onboard-gender-female.png
                          (duplicate of f04 per §12's accepted-duplication note). F24-A19's
                          distinctness check re-passed against the new files. A39 is otherwise
                          still a real device/screen check (layout, text-scale, no clipping) and
                          stays deferred; the image-quality risk specifically is closed.

Assertions: 38/40 PASS (A01-A38); A39, A40 [L] deferred
Regression: flutter analyze clean; full flutter test suite green (see .memory/handoffs/F24.md)
Validation: scrutiny-validator pass 2026-10-22, fix round applied and independently re-verified
            same day: Icons.check replaced with the repo's ✓-glyph convention in gender_card.dart;
            03 §4 and the firestore-schema.md gender row corrected (adds the '' read-back rule,
            drops the wrong /intro-redirect claim); A27/A31's "11 methods" off-by-one fixed to 10;
            F02-A14 amendment added plus a new F24_A20 test for the cold /personalize -> back ->
            /gender case; F18-A01 and F02-A26 stale counts dated-amended; 06-validation-contract.md
            uses the ledger's own `~` symbol. welcome_view.dart's hero-image layout change is a
            separate, earlier-approved fix (design-review thread, this session) — kept, to be
            committed separately from F24, not part of this feature's scope; F02-A27's live parity
            check should be re-run against it when that pass happens.
            Re-verified after the fix round: flutter analyze 0 issues; flutter test 631 passed /
            10 skipped (rules tag) / 0 failed; rules emulator suite 58/58 (A36-A38 by name).
            contract-auditor pass 2026-10-22: confirmed every A01-A38 assertion has a matching,
            unweakened test; confirmed the F02/F18/F22 cross-document amendments are present,
            dated and non-deleting; signed off at gates 1-3, 38/40, A39/A40 deferred. Known,
            accepted low-severity drift (pre-existing, not introduced by F24): .memory/contracts/ledger.json
            is empty and does not mirror 06's table; F22 §12's bootstrap-payload comparison table
            (not an assertion) still says "11" in one cell. behaviour-validator NOT yet run.
Harness note: F02 tests now reach /intro via /gender -> Male -> Continue (pumpIntro /
pumpPersonalize in test/features/support/f02_harness.dart), per the dated F02 amendments.
```
