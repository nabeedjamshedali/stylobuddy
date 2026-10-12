# Agent: Tech Stack Setup

Use this whenever scaffolding a new project or wiring in one of the fixed
services. Goal: every project ends up with the same stack, wired the same
way, so nothing needs to be re-explained.

## Flutter base

- Project is scaffolded by the agent itself (`flutter create`), never
  manually by me — see `.claude/agents/project-kickoff.md` Step 0a.
- **State management: Cubit only** (`flutter_bloc`'s `Cubit`, not full
  Bloc, not Riverpod, not Provider). No Freezed — states are plain
  classes with a hand-written `copyWith` method. Don't introduce Freezed
  or a different state manager even for "just this one screen."
  - Convention: one Cubit per feature (e.g. `HomeCubit`, `AuthCubit`),
    paired with one State class exposing `copyWith`.
  - State example shape:
    ```dart
    class HomeState {
      final bool isLoading;
      final List<Item> items;
      final String? error;

      const HomeState({
        this.isLoading = false,
        this.items = const [],
        this.error,
      });

      HomeState copyWith({
        bool? isLoading,
        List<Item>? items,
        String? error,
      }) {
        return HomeState(
          isLoading: isLoading ?? this.isLoading,
          items: items ?? this.items,
          error: error,
        );
      }
    }
    ```
  - Emit new states via `emit(state.copyWith(...))`, never mutate in place.
- **Folder structure: feature-based**, always:
  ```
  lib/
    core/          # app-wide setup: theme, routing, DI, constants
    shared/         # shared widgets/utils reused across features
    features/
      <feature_name>/
        cubit/        # <feature>_cubit.dart, <feature>_state.dart
        view/         # screens
        widgets/      # feature-local widgets
        repository/   # data access for this feature
        models/       # feature-local models
  ```
  Every new feature gets its own folder under `lib/features/`. Don't put
  feature logic in `core/` or `shared/` — those are for genuinely
  cross-feature code only.

## Firebase Auth

- Packages: `firebase_auth`, `firebase_core`.
- **Default sign-in method: Google only.** Don't add Apple, Email/Password,
  or any other provider unless a specific app's PRD calls for it.
- Wire `firebase_options.dart` via FlutterFire CLI, one Firebase project
  per app unless told otherwise.

## Firestore

- Package: `cloud_firestore`.
- Primary app database. Standard collection-per-feature structure unless
  the PRD dictates otherwise.
- When a document needs to reference a stored image/file, save the
  **Supabase Storage URL** as a field on the relevant Firestore
  document/user record — don't store files in Firestore itself.

## Supabase Storage (images/files)

- Package: `supabase_flutter` (Storage client comes with it).
- **All image/file storage goes through Supabase Storage — not Firebase
  Storage.** Don't add `firebase_storage` to any project.
- Default bucket convention: `user-uploads/{uid}/...` for anything tied
  to a specific user; separate top-level buckets (e.g. `app-assets`) for
  shared/non-user-specific files.
- After upload, save the resulting public/signed URL onto the relevant
  Firestore document when the file is user-specific (e.g.
  `users/{uid}.profileImageUrl`).
- Set bucket access policies so user-specific buckets require auth;
  public/shared asset buckets can be public-read.

## Supabase Edge Functions

- Package: `supabase_flutter` for the client.
- Edge functions live in `supabase/functions/*`, written in
  Deno/TypeScript, deployed via `supabase functions deploy`.
- Supabase handles Storage + backend/edge logic; Firebase handles
  Auth + Firestore + Analytics/Crashlytics/Remote Config. Don't
  duplicate auth in Supabase.
- Env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY` — never hardcode.

## Credentials & setup automation

Don't ask me to click through the Firebase or Supabase consoles. Instead:
- Ask me for a **Firebase service account key (JSON)** when Firebase
  project setup/config is needed.
- Ask me for a **Supabase access token** when Supabase project
  setup/config is needed.

With those, handle the full setup yourself: create the project, enable
Auth (Google provider), set up Firestore, create Supabase Storage
buckets and access policies, deploy edge functions, and configure
`firebase_options.dart` / `SUPABASE_URL` / `SUPABASE_ANON_KEY` in the
app — via the Firebase/Supabase CLIs or management APIs, not manual
console steps. Only loop me in for things that genuinely require a
human (OAuth consent screen branding/verification, billing setup, store
listing details).

## RevenueCat

- Package: `purchases_flutter`.
- **Two-phase setup — don't fully link it during the initial build:**
  - **Phase 1 (MVP build, every project):** integrate the `purchases_flutter`
    SDK, initialize it with the RevenueCat API key, and build the paywall
    UI/flow. Do **not** create real products/entitlements yet — Google
    Play requires an app to sit in closed testing before real in-app
    products can be created, so there's nothing to link yet. Paywall UI
    can be built against placeholder/mock entitlement checks in the
    meantime.
  - **Phase 2 (after 14-day closed testing on Google Play):** once the
    app has cleared Play Console's closed testing period and I'm ready to
    create real products, this happens on a **separate git branch**
    (not `main`/the MVP branch). On that branch: create the actual
    products in Google Play Console, create matching products/offerings/
    entitlements in RevenueCat, and wire the paywall to the real
    entitlement checks.
  - Don't assume Phase 2 is done just because Phase 1 is — always ask
    which phase we're in if it's ambiguous, rather than assuming
    products/entitlements already exist.
- Default paywall trigger points to consider: end of onboarding, and any
  feature-gated action. Actual placement is decided per-app in
  `.claude/agents/onboarding-builder.md` and the PRD, not here.
- Entitlement structure default (used once Phase 2 starts): a `pro`
  entitlement gating premium features, unless the PRD specifies otherwise.

## Firebase Analytics / Crashlytics / Remote Config

- Packages: `firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`.
- Crashlytics: wire `FlutterError.onError` and `PlatformDispatcher.onError`
  to Crashlytics on app start, every project, no exceptions.
- Analytics: log at minimum — app_open, onboarding_step, onboarding_complete,
  paywall_shown, purchase_completed, core feature usage events (define
  per-app in the PRD).
- Remote Config: default keys every project should have —
  `min_supported_version`, `force_update`, `maintenance_mode`. Add
  app-specific flags as needed.

## Android-first, iOS-later notes

- Build and test Android by default.
- Flag anything that will need iOS-specific work later (e.g. platform
  channels, permission dialogs, Apple sign-in requirement, App Store
  privacy manifest) rather than doing it now, unless I ask.
