# F02 — Onboarding and Auth

> The welcome screen, five-slide intro, personalization, auth chooser and the demo email auth screens (login, signup, forgot, reset-sent, verify-email). Plan Task 4; prototype `app.js:288-323`. Depends on foundation 03, 04, 07.

**Status:** DONE (gates 1-3; gate 4 open) · **Milestone:** 1 · **Depends on:** F01

---

## 1. Goal

A first-time user is walked from welcome to the app (or skips straight in) with the exact prototype copy, using demo-only auth.

## 2. MVP scope

9 routes without bottom nav. `OnboardingCubit`, `AuthCubit`. Password show/hide. Inline auth errors. Demo disclaimers via `DemoNote`.

## 3. Later scope

Real Firebase Auth (Google, email, Apple), real verification and reset emails, persisting the onboarding-complete flag.

## 4. Roles and permissions

guest / demo user. "Skip for now" and a successful demo login both enter `/home`; no gating.

## 5. Main flows

```text
/welcome -> "Get Started →" -> /intro (slide 1/5) -> Continue x4 -> slide 5 "Create My Wardrobe" -> /personalize -> "Continue →" -> /auth
/welcome -> "Skip introduction" -> /auth ; intro "Skip" -> /personalize ; intro "Back" on slide 1 -> /welcome
/auth -> "Continue with Email" -> /login -> valid -> /home + toast ; "Forgot password?" -> /forgot -> /reset-sent
/auth -> /signup -> valid -> /verify-email -> "Continue to demo →" -> /home + toast
invalid password/mismatch -> inline error, no navigation
```

## 6. Interface surface

Routes: `/welcome` `/intro` `/personalize` `/auth` `/login` `/signup` `/forgot` `/reset-sent` `/verify-email` (exposed via `onboardingRoutes`, `authRoutes`).

```text
OnboardingCubit{int slide; Set<String> chosenOccasions; void next(); void back(); void toggleOccasion(String)}
AuthCubit{String email; String? error; AuthResult submitLogin(...); AuthResult submitSignup(...); AuthResult submitForgot(...)}
Consumes: BrandMark ScreenHead OptionTile ChipButton PrimaryButton AppToast DemoNote
```

## 7. Domain model usage

None of the shared entities. `AuthCubit.email` is remembered for the reset-sent and verify-email screens. Signup does not write `ProfileState` (F02-A28).

## 8. Data changes

None.

## 9. Background work and events

None. No real email is sent.

## 10. Degradation and failure

Invalid email/blank required fields: submit blocked, no navigation, no toast. Password < 8 on signup and confirm mismatch: inline error text. `AuthCubit.email` empty: reset-sent and verify-email show the fallback phrase `your email address`.

## 11. Validation assertions

```
F02-A01  [U]  OnboardingCubit starts at slide 0; next() increments; back() decrements; next() from slide 4 emits finished (navigates to /personalize); back() on slide 0 signals return to /welcome
F02-A02  [U]  toggleOccasion('Office') adds it to chosenOccasions, a second call removes it
F02-A03  [U]  submitSignup with password 'short' sets error 'Use at least 8 characters for your password.' and returns a failure result
F02-A04  [U]  submitSignup with password 'longenough' and confirm 'different' sets error 'Passwords do not match. Please try again.'; the 8-character check runs first when both apply
F02-A05  [U]  submitLogin has no length rule: password 'abc' with a valid email succeeds
F02-A06  [U]  Email validation rejects '', 'abc', 'a@b' and accepts 'you@example.com'; signup full name of 1 character is rejected, 2 accepted; blank (empty) password is rejected
F02-A07  [U]  A successful submitForgot or submitSignup stores the entered email in AuthCubit.email; submitLogin stores it too
F02-A08  [U]  Welcome renders 'Your AI-Powered' and 'Personal Stylist', the line 'Organize your wardrobe,', 'Get Started →' and 'Skip introduction'; 'Get Started →' opens /intro on slide 1; 'Skip introduction' opens /auth
F02-A09  [U]  Intro slide 1 shows counter '1/5', title 'Your wardrobe.' / 'Smarter.', the description 'Organize every outfit and get AI-powered styling recommendations in seconds.' and button 'Get Started'; slides 2-4 use 'Continue'; slide 5 uses 'Create My Wardrobe'
F02-A10  [U]  Intro slide titles in order: 'Your wardrobe.' 'Smarter.' / 'Scan it once.' 'Find it anytime.' / 'Let AI style you.' / 'Tell us where' 'you’re going.' / 'Never wonder' '“What should I wear?”' with desc 'Smart outfits for every you.' on slide 5
F02-A11  [U]  Intro always renders 5 dots with exactly one active matching the slide; 'Skip' navigates to /personalize at any slide; 'Back' on slide 2 returns to slide 1; 'Back' on slide 1 goes to /welcome
F02-A12  [U]  Slide 4 lists occasions with glyphs ▣ Office, ♧ Wedding, ♥ Date Night, ☼ Casual Day Out, ✧ Party, ♙ Interview, ⌂ Vacation; tapping one marks it chosen and tapping again clears it
F02-A13  [U]  Personalize renders head 'Your Style, Your Way', 'What feels most like you?', 'Choose a few favorites. You can change them later.', five options ('Minimal & clean', 'Smart casual' preselected, 'Elegant & polished', 'Relaxed & comfy', 'Colorful & bold'); tapping an option toasts '<option> selected'
F02-A14  [U]  Personalize shows chips Everyday Office Wedding Party Travel that toggle independently; 'Continue →' opens /auth; the ‹ button on Personalize returns to /intro
F02-A15  [U]  Auth renders 'Create your wardrobe.' and the three buttons; Google toasts 'Google authentication UI preview', Apple toasts 'Apple authentication UI preview', 'Continue with Email' opens /login, 'Skip for now' opens /home
F02-A16  [U]  Login renders overline 'STYLE STARTS HERE', 'Welcome back.', 'Sign in to continue building your personal wardrobe.', fields 'Email address' 'Password', 'Forgot password?', 'Sign in →' and 'New to StyloBuddy? Create an account'
F02-A17  [U]  Login with valid email and non-empty password navigates to /home, toasts 'Signed in to demo account' and the bottom nav is visible
F02-A18  [U]  Login with an empty password, or an invalid email, stays on /login with no toast
F02-A19  [U]  Password fields start obscured with a 'Show' control; tapping it reveals and relabels it 'Hide'; tapping again re-obscures
F02-A20  [U]  Signup renders 'Create your account.', 'Save your wardrobe, discover outfits, and keep everything in one place.', fields 'Full name' 'Email address' 'Password' 'Confirm password', helper 'Use 8 or more characters for a secure password.', 'Create account →', legal 'By continuing, you agree to the Terms of Service and Privacy Policy.', footer 'Already have an account? Sign in'
F02-A21  [U]  Signup with valid data navigates to /verify-email; with 'short' it stays and shows 'Use at least 8 characters for your password.'; with mismatch it shows 'Passwords do not match. Please try again.'; the error clears or hides on a successful submit
F02-A22  [U]  Forgot renders 'Reset your password.', 'Enter your email and we’ll help you get back into your account.', 'Send reset link →', 'Remembered it? Back to sign in'; a valid email opens /reset-sent; an empty one stays
F02-A23  [U]  Reset-sent renders 'Check your inbox.', 'Reset link preview', the entered email in bold inside 'In the real app, a secure link would be sent to <email>. No email has been sent by this prototype.'; with no stored email the text uses 'your email address'; 'Back to sign in →' opens /login; 'Try another email' opens /forgot
F02-A24  [U]  Verify-email renders 'One more step.', 'Verification preview', 'In production, we’ll send a verification email to <email>. This is an interactive design preview only.'; 'Continue to demo →' opens /home with toast 'Verification simulated'; 'Resend verification email' toasts 'No real email is sent in this prototype' and stays
F02-A25  [U]  Header back targets: login -> /auth, signup -> /auth, forgot -> /login, reset-sent -> /forgot, verify-email -> /signup (pop when history exists)
F02-A26  [U]  None of the 9 routes shows the bottom navigation
F02-A28  [U]  After a successful signup the ProfileState name and email are unchanged ('Alex Morgan', 'alex@example.com')
F02-A27  [L]  In the running web build at 390x844, /#/welcome matches the prototype screenshot; driving welcome -> Get Started -> 5 slides -> personalize -> auth -> Skip for now reaches /home with nav; demo signup with 'short' shows the inline error
```

## 12. Edge cases

Whitespace-only full name or email passes HTML `required` in the prototype; port trims email and rejects whitespace-only name (stricter, invisible to the prototype UI flow). Slide image assets: `onboard-00-rack.png` .. `onboard-04-outfit.png`.

## 13. Open questions

None. Resolved 2026-10-16: signup does not write `ProfileCubit` (matches the prototype; profile stays Alex Morgan).

---

## Completion block

```
Status: DONE (gates 1-3; gate 4 open)

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run   (F02-A27 pending parity pass)

Assertions: 27/28 PASS (A27 [L] pending)
Regression: flutter test 98 passed; flutter analyze clean
```
