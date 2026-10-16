# 07 — Security

> Authentication, authorization, secrets and data protection. Depends on `02-architecture.md`.

---

## 1. Authentication

Milestone 1 has **no auth backend**. "Sign in", "Create account", "Forgot password" and "Verify email" are demo flows that validate input locally and navigate; no credentials leave the device and none are stored. Social buttons only toast ("Google authentication UI preview"). Later: Firebase Auth with Google sign-in (Android first), email/password, Apple on iOS; sessions managed by the Firebase SDK.

## 2. Roles and permissions

| Role | Can | Cannot |
|------|-----|--------|
| guest | Use every screen with in-memory sample data ("Skip for now") | Persist data across restarts; sync |
| demo user | Same as guest, after "Signed in to demo account" (flag only) | Reach real cloud data |
| authenticated user (later) | Read/write only their own Firestore documents and Supabase Storage prefix | Read other users' data |

Feature documents reference these roles rather than redefining them. No feature in Milestone 1 is permission-gated; Premium screens are preview-only and never change `ProfileState.plan`.

## 3. Data isolation

Single in-memory user in Milestone 1; nothing to isolate. Later: Firestore rules `request.auth.uid == userId` on every user document; Supabase bucket `user-uploads/{uid}/...` with per-uid policies. Isolation assertions are added with the integration feature document.

## 4. Secrets

No secrets exist yet. Later: Firebase service-account JSON and Supabase access token are supplied by the owner for setup only, never committed, never logged; client config files stay out of the repo unless they are public identifiers.

## 5. Audit

Not applicable in Milestone 1. Later: Crashlytics for errors, Analytics events without personal content.

## 6. Threats considered

Considered: committing secrets (none present); rendering user text as markup (all user-entered text is rendered as plain `Text`, so prototype `safeText` escaping is satisfied by construction); accidental real destructive actions (Delete account / purchase are preview-only and change nothing).
Not defended in Milestone 1: network attacks, account takeover, data theft from device (no real data).
