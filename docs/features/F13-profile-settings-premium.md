# F13 — Profile, Settings and Premium

> The profile hub, personal details and style preference editing, settings (notifications, weather, help and legal, delete account preview, sign out), and the preview-only Plus paywall, plans, checkout and subscription screens. Plan Task 13 (profile part, 13c); prototype `app.js:268-287`. Depends on foundation 03, 04, 07.

**Status:** IN PROGRESS · **Milestone:** 1 · **Depends on:** F01

---

## 1. Goal

Let the user view and edit their demo profile and preferences and explore the premium preview, without any real account or billing action.

## 2. MVP scope

14 routes (`profileRoutes`): `/profile /edit-profile /edit-style /settings /notifications /weather-settings /support /support-detail /delete-account /signout /premium /plan /purchase /subscription`. State lives in `ProfileCubit` (F01); no new Cubit required.

## 3. Later scope

Real account deletion, sign-out via Firebase Auth, RevenueCat entitlements, real pricing, persisted preferences.

## 4. Roles and permissions

guest / demo user. Delete account, sign out and purchase are preview-only: they change no wardrobe, outfit or plan data (`07-security.md`).

## 5. Main flows

```text
/profile -> pencil -> /edit-profile -> validate -> ProfileCubit.updateDetails -> /profile + toast
/profile -> Style preferences -> /edit-style -> togglePreference (immediate) -> "Save preferences" -> /profile + toast
/profile -> Settings -> /notifications | /weather-settings | /subscription | /support | /signout
/profile -> premium banner -> /premium -> /plan -> /purchase -> /subscription  (ProfileState.plan stays 'Free')
/signout -> "Sign out · Demo" -> /auth + toast
```

## 6. Interface surface

Routes as in section 2.

```text
ProfileCubit (F01): updateDetails(name,email) togglePreference(PreferenceField, value) setDailyNotifications setPlannedNotifications setProductNotifications setWeatherConsent setClimate setPlan setBillingCycle
Consumes: ScreenHead, AppToast, AppModal, DemoNote, PrimaryButton/SecondaryButton/DangerButton, AppRoutes
```

## 7. Domain model usage

`ProfileState` all fields (`name`, `email`, `styles`, `occasions`, three notification flags, `weatherConsent`, `climate`, `plan`, `billingCycle`, `styleSummary`).

## 8. Data changes

None (session-only, as the prototype says "saved only in this demo session").

## 9. Background work and events

None.

## 10. Degradation and failure

Blank/whitespace name or invalid email -> toast, no change. Empty name -> avatar 'A'. No real data is deleted or purchased by any control.

## 11. Validation assertions

```
F13-A01  [U]  Profile renders 'YOUR SPACE', 'My profile', avatar 'A', 'Alex Morgan', 'alex@example.com', 'Personal wardrobe profile' for the defaults; with name 'sam' the avatar is 'S' (uppercased first character); with name '' the avatar is 'A' (missing differs from set)
F13-A02  [U]  The pencil (label 'Edit profile') opens /edit-profile; the premium banner 'STYLOBUDDY PLUS' 'Make every outfit count.' 'Explore premium styling tools →' opens /premium
F13-A03  [U]  Style hub rows 'Outfit planner'/'Plan looks ahead of time', 'Packing assistant'/'Build travel wardrobes', 'Shopping assistant'/'Fill wardrobe gaps', 'Style insights'/'Understand your wardrobe' open /calendar, /packing, /shopping, /insights
F13-A04  [U]  Account rows 'Personal details'/'Name and contact email' (-> /edit-profile), 'Style preferences' with subtitle 'Minimal · Smart casual' (-> /edit-style), 'Settings'/'Notifications, privacy, billing' (-> /settings); the subtitle updates after styles change
F13-A05  [U]  Edit-profile renders head 'Personal Details', 'A little about you.', 'Keep your profile details up to date.', fields 'Display name' (max 64) and 'Email address' prefilled, helper 'Changes here are saved only in this demo session.', 'Save changes'
F13-A06  [U]  Saving with an empty or whitespace-only name toasts 'Please enter a name and valid email', stays, and ProfileState.name is unchanged
F13-A07  [U]  Saving with email 'abc', 'a@b', 'a b@c.d' or '' toasts 'Please enter a name and valid email' and changes nothing; 'sam@x.co' is accepted
F13-A08  [U]  A valid save stores the trimmed name and email, opens /profile and toasts 'Profile updated in demo'
F13-A09  [U]  Edit-style renders head 'Your Style', 'What feels like you?', 'PERSONAL STYLE' with Minimal, Smart casual, Classic, Streetwear, Elegant, Bold and 'YOUR OCCASIONS' with Everyday, Office, Wedding, Date Night, Party, Travel; selected chips show '✓' (Minimal, Smart casual, Everyday, Office) and others '＋'
F13-A10  [U]  Tapping a chip toggles it immediately in ProfileState (adds 'Bold', removes it again)
F13-A11  [U]  'Save preferences' opens /profile and toasts 'Preferences saved'; styleSummary joins styles with ' • '
F13-A12  [U]  Settings renders head 'Settings', sections PERSONALIZATION (Notifications 'Daily looks and outfit reminders' -> /notifications; Weather preferences 'Optional context for recommendations' -> /weather-settings), SUBSCRIPTION (Subscription & billing 'Free plan · Plans not yet priced' -> /subscription), SUPPORT & ACCOUNT (Help, privacy & legal 'Policies and support' -> /support; Sign out 'Leave the current demo session' -> /signout) and 'StyloBuddy · Interface prototype V19'
F13-A13  [U]  Notifications renders head 'Notifications', 'Stay in the know.', rows 'Daily outfit ideas' (on), 'Planned outfit reminders' (on), 'Product updates' (off), helper 'System notification permissions will be requested in the real app.'; toggling updates the matching ProfileState flag
F13-A14  [U]  Notifications 'Done' opens /settings and toasts 'Notification preferences saved'; the toggled values persist in ProfileCubit after leaving and returning
F13-A15  [U]  Weather & Location renders head 'Weather & Location', 'Dress for your day.', toggle 'Use local weather' (on), 'FALLBACK CLIMATE' with Warm, Mild (selected), Cool, Cold, helper 'No location data is accessed by this offline prototype.'; choosing Cold sets ProfileState.climate; 'Save settings' opens /settings with toast 'Weather settings saved'
F13-A16  [U]  Support renders head 'Help & Privacy', rows 'Help center', 'Contact support', 'Privacy policy', 'Terms of service' (-> /support-detail) and 'Delete account' (-> /delete-account)
F13-A17  [U]  Support-detail renders head 'Help & Information', 'Coming before launch', 'Official support channels, policies and terms are not included in this design prototype.' and 'Back to help' (-> /support)
F13-A18  [U]  Delete-account renders 'Your account, your choice.', the warning 'This is a visual preview only. No real user account or cloud data will be deleted.' and 'Review deletion'; the button opens modal 'Deletion preview' with 'This demo does not connect to a live user account. No data will be deleted.' and 'Close'
F13-A19  [U]  After 'Review deletion' and 'Close', wardrobe items, outfits and ProfileState are unchanged
F13-A20  [U]  Signout renders head 'Sign Out', 'Sign out of StyloBuddy?', 'Sign in again to access your synced wardrobe in the future app.'; 'Stay signed in' opens /settings; 'Sign out · Demo' opens /auth with toast 'Signed out of demo preview' and no bottom nav; wardrobe and profile data are unchanged
F13-A21  [U]  Premium renders head 'StyloBuddy Plus', 'More possibilities.' 'More personal style.', 'PLANNED PREMIUM VALUE' with four benefits ('Additional AI outfit recommendations', 'Advanced garment matching', 'Expanded style insights', 'Smarter trip and calendar planning'), helper 'These are proposed benefits. Entitlements and pricing require cost review.' and 'Preview plan options →'
F13-A22  [U]  Plan renders head 'Choose a Plan', 'Choose your rhythm.', cards 'Monthly'/'Pay month to month' and 'Yearly'/'A longer-term option' each with 'Price TBD', Yearly selected by default; choosing Monthly calls setBillingCycle('monthly'); the warning 'No purchase is available in this prototype. Final plans depend on AI operating costs.' and 'Continue · Preview only' (-> /purchase)
F13-A23  [U]  Purchase renders head 'Checkout Preview', 'Checkout integration pending', the StoreKit/Google Play Billing paragraph, and 'View subscription settings' (-> /subscription)
F13-A24  [U]  Subscription renders head 'Subscription', 'CURRENT PLAN', 'Free' (from ProfileState.plan), 'Subscription pricing and included AI usage are still under review.', 'Explore StyloBuddy Plus →' (-> /premium), 'MANAGE' row 'Plan options' (-> /plan), 'Restore purchases · Demo' (toast 'No purchases to restore in this demo') and the helper about app stores
F13-A25  [U]  Completing premium -> plan -> purchase -> subscription leaves ProfileState.plan == 'Free' (no flow sets a paid plan)
F13-A26  [U]  Header back targets: edit-profile, edit-style, settings -> /profile; notifications, weather-settings, support, signout, subscription -> /settings; support-detail, delete-account -> /support; premium -> /profile; plan -> /premium; purchase -> /plan
F13-A27  [U]  All 14 routes sit in the shell (bottom nav visible); per AppRoutes.tabFor, /profile /settings /edit-profile /edit-style /notifications /support /premium /plan /purchase /subscription highlight Profile, while /weather-settings /support-detail /delete-account /signout highlight Home (as the prototype render())
F13-A28  [L]  In the running web build at 390x844: /#/profile matches the prototype screenshot; edit profile with name '   ' (toast 'Please enter a name and valid email') then 'Sam Lee' (toast 'Profile updated in demo') and Home greets 'Hi, Sam Lee'; premium -> plan -> purchase -> subscription still shows 'Free'; sign out lands on /auth
```

## 12. Edge cases

Tab highlighting follows F01 `tabFor` (see A27). Sign out is a preview: it does not clear any state. The delete-account modal and the sign-out toast are the only side effects.

## 13. Open questions

None.

---

## Completion block

```
Status: IN PROGRESS

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 27/28 PASS ([U] A01-A27; A28 is [L], pending the parity pass)
Regression: flutter test — 388 passing (2026-10-17)
```
