# 01 — Tech Stack

> Languages, frameworks, services and versions. Depends on `00-product-spec.md`.
> The fixed stack is defined in `CLAUDE.md` and `.claude/agents/tech-stack.md`; this file records what is wired **now**.

---

## 1. Summary

| Layer | Choice |
|-------|--------|
| Language | Dart ^3.12 |
| Framework | Flutter 3.44 (Android first; web only as a verification surface) |
| State | `flutter_bloc` ^9.1 — Cubit only, plain state classes, hand-written `copyWith` |
| Navigation | `go_router` ^14 |
| Assets/UI | `flutter_svg` ^2, bundled DMSans + Manrope fonts (via `AppTextStyles`), `intl` ^0.20 |
| Data (Milestone 1) | In-memory repositories seeded from `SeedData` (prototype data) |
| Data (later) | Firestore, Supabase Storage, Firebase Auth, RevenueCat, Analytics, Crashlytics, Remote Config (none wired in Milestone 1) |
| Tests | `flutter_test` (unit + widget); live run on Chrome |
| Tooling | `flutter_launcher_icons`, `flutter_native_splash` |

## 2. Choices and reasons

- **Cubit, no Freezed, no Bloc/Riverpod/Provider**: fixed stack; enforced by `.claude/harness.json` boundary "Cubit-only state".
- **Bundled fonts, no runtime fetch**: first launch must look right offline (ruling: plain pubspec families DMSans/Manrope; never `GoogleFonts.*` in feature code).
- **SVG fallback for 7 garments** (cream-blouse, blue-jeans, sage-dress, black-skirt, gold-jewelry, sunglasses, green-shirt): the prototype's photos for these show the wrong garment; real product photos are tracked in `docs/image-prompts.md` and needed before store release.
- **Hash URLs on web** for the parity/live runs (`/#/<route>`).
- **No backend yet**: credentials are not requested until the later integration pass.

## 3. Development environment

```
flutter pub get
flutter test                       # unit + widget suite
flutter analyze                    # must report no issues
flutter run -d chrome              # fastest visual loop; set window to 390x844
flutter build web                  # then serve build/web (python -m http.server 8802)
flutter build apk --debug          # Android build check
```

## 4. Repository layout

```
lib/core/{theme,assets,router}      design tokens, AppAssets, AppRoutes/appRouter/AppShell
lib/shared/{models,data,widgets}    ClothingItem/Outfit/WearEvent/PlannedEntry, SeedData, shared widgets
lib/features/<f>/{cubit,repository,view,widgets,<f>_routes.dart,<f>_tokens.dart}
test/{core,shared,features/<f>}     mirrors lib
assets/{fashion,garments,onboarding,branding,fonts}
docs/{foundation,features}          the contract
```

## 5. Versioning and dependencies

Versions are pinned by `pubspec.lock`. Upgrades happen only as their own task with a full `flutter test` run. Adding a dependency needs a note in the owning feature document.
