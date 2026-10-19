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

Structurally guest-vs-authenticated as of F14: `uid == null` gets an in-memory-only subtree (D2 in `backend-architecture.md`), `uid != null` gets the authenticated subtree — no code path can mix the two in one Cubit instance (D3) (identical in-memory construction until Tasks 2-7 land their own repositories). Per-collection Firestore isolation (`request.auth.uid == uid` on every `users/{uid}/...` document, already the shape of the live `firestore.rules`) is hardened with field-level rules in Task 9; Supabase `user-photos/{uid}/...` per-uid policies land with Task 2. Isolation assertions are added with each integration feature document.

## 4. Secrets

Firebase service-account JSON and Supabase access token are supplied by the owner for setup only, never committed, never logged; client config files (`google-services.json`, `firebase_options.dart`) are committed since they are public client identifiers, not secrets.

## 5. Audit

Crashlytics is wired (`lib/main.dart`: `FlutterError.onError`/`PlatformDispatcher.instance.onError` both record to `FirebaseCrashlytics.instance`). Analytics events without personal content are still Later (not wired by this plan).

## 6. Threats considered

Considered: committing secrets (none present); rendering user text as markup (all user-entered text is rendered as plain `Text`, so prototype `safeText` escaping is satisfied by construction); accidental real destructive actions (Delete account / purchase are preview-only and change nothing).
Not defended in Milestone 1: network attacks, account takeover, data theft from device (no real data).
