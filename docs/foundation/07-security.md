# 07 — Security

> Authentication, authorization, secrets and data protection. Depends on `02-architecture.md`.

---

## 1. Authentication

Google sign-in is real: Firebase Auth + Google Sign-In (Android first), sessions managed by the Firebase SDK (`lib/features/auth/repository/auth_repository.dart`). "Create account", "Forgot password" and "Verify email" with email/password are still demo flows that validate input locally and navigate; no credentials leave the device and none are stored for those paths. Later (Task 8 of the backend-wiring plan): real email/password via `FirebaseAuth.createUserWithEmailAndPassword`/`signInWithEmailAndPassword`; Apple sign-in on iOS.

## 2. Roles and permissions

| Role | Can | Cannot |
|------|-----|--------|
| guest | Use every screen with in-memory sample data ("Skip for now") | Persist data across restarts; sync |
| demo user | Same as guest, after "Signed in to demo account" (flag only) | Reach real cloud data |
| authenticated user | Signed in via real Google/Firebase Auth (F14's `uidChanges()` keys `lib/app.dart`'s Cubit reconstruction on this); will read/write only their own Firestore documents and Supabase Storage prefix once each feature's repository lands (Tasks 2-7) | Read other users' data |

Feature documents reference these roles rather than redefining them. No feature in Milestone 1 is permission-gated; Premium screens are preview-only and never change `ProfileState.plan`.

## 3. Data isolation

Structurally guest-vs-authenticated as of F14: `uid == null` gets an in-memory-only subtree (D2 in `backend-architecture.md`), `uid != null` gets the authenticated subtree — no code path can mix the two in one Cubit instance (D3) (identical in-memory construction until Tasks 2-7 land their own repositories). Per-collection Firestore isolation (`request.auth.uid == uid` on every `users/{uid}/...` document) is field-level in the repo's `firestore.rules`; production still runs the pre-F22 rules until the gated deploy (A51). As of Task 9 (F22, 2026-10-20), `firestore.rules` replaced the single recursive `users/{uid}/{document=**}` wildcard with six explicit per-collection blocks (`users/{uid}` profile, `wardrobeItems`, `outfits`, `wearEvents`, `plannedEntries`, `packingTrips`), each validating an exact allow-listed key set and a per-field type/invariant check (full detail: `docs/superpowers/specs/2026-10-19-firestore-schema.md` §8, `docs/features/F22-firestore-rules-hardening.md`). Any other path, including any other subcollection under `users/{uid}`, is default-deny. This is proven against the Firestore emulator (`test/firestore_rules_test/`, 50 assertions, F22-A01-A49 + A46b); the production deploy itself (F22-A50-A53) is a separate, explicitly gated follow-up and had not happened as of this note. Supabase `user-photos/{uid}/...` per-uid policies land with Task 2. Isolation assertions are added with each integration feature document.

## 4. Secrets

Firebase service-account JSON and Supabase access token are supplied by the owner for setup only, never committed, never logged; client config files (`google-services.json`, `firebase_options.dart`) are committed since they are public client identifiers, not secrets.

*(2026-10-20, Task 10/F23)* The `ai-stylist` Edge Function's `LLM_PROVIDER` selector and any future chosen provider's API key are set only via `supabase secrets set --project-ref dbaeaqyoyilxcuwplvuw`, the same mechanism and discipline as the existing service-role key — never committed, never logged. Today `LLM_PROVIDER` is unset in production and the function always answers `501` (`docs/features/F23-ai-stylist-stub.md`).

*(2026-10-30, F26)* `ai-stylist` gains a real provider, Google Gemini
(`docs/features/F26-real-ai-stylist.md`).

- **Secrets.** These are set only via `supabase secrets set --project-ref
  dbaeaqyoyilxcuwplvuw` and are never committed, logged, echoed in a
  response, or put in Remote Config:
  - `LLM_PROVIDER=gemini`;
  - `GEMINI_API_KEY`, sent only in the `x-goog-api-key` request header and
    never in a URL;
  - `GEMINI_MODEL`, optional, default `gemini-2.5-flash`. It is not secret,
    but it is managed the same way;
  - `AI_DAILY_LIMIT`, optional, default `30`. `0` turns AI off for every
    user.
- **Service-role key.** The platform-injected `SUPABASE_URL` and
  `SUPABASE_SERVICE_ROLE_KEY` are read only by `_shared/usage-limit.ts`, to
  call `ai_usage_try_increment`.
- **`ai_usage` table.** Supabase Postgres `public.ai_usage` stores only the
  SHA-256 hex of the Firebase uid (never the raw uid), the UTC day and a
  count. RLS is enabled with no policies, and table privileges and execute on
  the function are revoked from `anon`/`authenticated`.
- **Third-party processing.** For signed-in users, only while Remote Config
  `ai_stylist_enabled` is true, the app sends Gemini:
  - the chosen occasion, style direction and weather;
  - the id, name, category, color, occasion and season of up to 120 of the
    user's wardrobe items.

  Nothing else is sent: no uid, email, display name, gender, photos or image
  URLs. Item names are user-typed free text. On the Gemini API **free tier**
  Google may use submitted content to improve its products. The privacy
  policy must therefore disclose this processing **before** `ai_stylist_enabled`
  is turned on in production (F26-A87).

## 5. Audit

Crashlytics is wired (`lib/main.dart`: `FlutterError.onError`/`PlatformDispatcher.instance.onError` both record to `FirebaseCrashlytics.instance`). Analytics events without personal content are still Later (not wired by this plan).

*(2026-10-29, F25)* Firebase Analytics is now wired through `AnalyticsService`
(`lib/shared/backend/analytics_service.dart`), whose typed methods are the only way to log.
Binding privacy rules: no gender, name, email, uid, free text, wardrobe item names/ids,
occasions or query parameters are ever sent; parameter values are fixed enum strings or
integers; `setUserId`/`setUserProperty`/`setDefaultEventParameters` are never called (F25-A04,
A09). Remote Config values are public to every client, so no secret may ever be stored in a
Remote Config parameter.

## 6. Threats considered

Considered: committing secrets (none present); rendering user text as markup (all user-entered text is rendered as plain `Text`, so prototype `safeText` escaping is satisfied by construction); accidental real destructive actions (Delete account / purchase are preview-only and change nothing).
Not defended in Milestone 1: network attacks, account takeover, data theft from device (no real data).
