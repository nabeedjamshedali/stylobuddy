# StyloBuddy — Port of the v23 HTML prototype to Flutter

## Intent

The user designed the full app as an HTML/CSS/JS prototype at
`C:\Users\DELL\Downloads\stylobuddy-v23-mobile-icon-final\stylobuddy-prototype`
(referred to below as **the prototype**). They want the Flutter app to have
**exactly the same UI, screens and flow** — copy, layout, spacing, colors,
images, navigation. The prototype is the spec; this doc only records the
decisions needed to turn it into a Flutter app. The user opted out of
questions and asked for senior-engineer judgement; every call below is ours.

## What gets built

All 64 prototype routes (`pages.*` in `app.js`) as Flutter screens, with the
prototype's in-memory behavior (sample wardrobe, simulated AI, demo auth,
demo purchases). Routes: home · wardrobe, clothing, edit-item, filter,
import, import-source, batch, analyzing, review, add-confirm · stylist,
occasion, styling-options, generating, results, result-detail · matching,
match-select, match-review, match-options, matching-progress,
matching-results, matching-detail · builder, manual-preview · saved,
saved-detail, wear-detail · calendar, calendar-choose, calendar-date ·
packing, new-trip, packing-preview, packing-list, packing-add · shopping,
shop-item · insights · profile, edit-profile, edit-style, settings,
notifications, weather-settings, support, support-detail, delete-account,
signout, premium, plan, purchase, subscription · welcome, intro (5 slides),
personalize, auth, login, signup, forgot, reset-sent, verify-email ·
generic (fallback).

The desktop "design studio" chrome (left studio panel, inspector, screen
directory, reset button, fake status bar and home indicator) is **not**
part of the app — it is the prototype's viewer, not the product.

## Goals / non-goals / anti-goals

- **Goal:** a user clicking through the Android app sees the same screens,
  copy and flow as the prototype at its 390×844 mobile viewport.
- **Goal:** clean architecture per `.claude/agents/tech-stack.md` (Cubit +
  feature folders + repositories) so real services slot in later without
  touching widgets.
- **Non-goal (this pass):** Firebase, Supabase, RevenueCat, real AI, camera.
  Repositories are in-memory, seeded with the prototype's data. Credentials
  are not requested until a later pass wires real services.
- **Anti-goal:** "inspired by" redesigns. Don't restyle, re-word, reorder or
  "improve" screens. If the prototype has it, the app has it.

## Decisions (ours)

1. **Replace** the current dark/coral theme, Dribbble-based splash and
   3-screen onboarding entirely. Keep the project, package id
   `com.stylobuddy.stylobuddy`, and folder conventions.
2. **Pixel mapping:** CSS px at the prototype's 390-wide mobile viewport map
   1:1 to Flutter logical pixels. Use the *last* CSS rule that wins in
   `styles.css` (later version sections override earlier ones).
3. **Fonts:** DM Sans (body) and Manrope (headings), bundled as assets via
   `google_fonts` with runtime fetching disabled, so first launch offline
   looks right.
4. **Glyph icons:** the prototype uses unicode glyphs (✧ ◇ ▦ ♡ ⌂ …) and a
   few inline SVGs. Reproduce the same glyphs as text and the same SVG paths
   via `flutter_svg` — not Material icons.
5. **Garment images:** bundle `assets/fashion/*.webp` for the 17 ids the
   prototype maps locally (`LOCAL_FASHION`). For the other 7 ids
   (cream-blouse, blue-jeans, sage-dress, black-skirt, gold-jewelry,
   sunglasses, green-shirt) the prototype hotlinks Unsplash lifestyle photos
   that don't show the garment, and its own webp crops for them show the
   wrong garment — use the prototype's bundled SVG illustrations (its
   offline fallback). Logged in `docs/image-prompts.md` as needing real
   product photos.
6. **Demo disclaimers** ("simulated", "No real email is sent…") are kept
   verbatim, but every one renders through a single `DemoNote` widget /
   copy constant so they can be removed together when services go live.
7. **Navigation:** `go_router`. Every route path equals the prototype route
   name (`/match-select`). The bottom nav (Home · Wardrobe · AI Stylist ·
   Saved · Profile) shows on every route except
   welcome/intro/personalize/auth/login/signup/forgot/reset-sent/verify-email,
   and highlights the tab using the prototype's `render()` grouping.
   A header back button pops if possible, otherwise goes to the prototype's
   explicit back route.
8. **Toasts and modals:** prototype `toast()` → a dark floating
   SnackBar-like overlay with identical styling; prototype `modal()` →
   centered dialog with the same card styling and ✕ close button.
9. **Simulated waits:** prototype `simulate()` waits 1150 ms then moves on;
   keep the same duration.
10. **Launcher icon & splash:** from `assets/branding/` — adaptive icon
    foreground PNG + background `#006F54`; native splash white with the icon.
    App label "StyloBuddy". Start route is `/welcome` (prototype initial route).
11. **State:** prototype global `S` is split into Cubits. Cross-feature data
    (wardrobe items, saved outfits + wear log, calendar plans, profile) live
    in Cubits provided at the app root; feature-local UI state (selection,
    drafts, filters) lives in that feature's Cubit.

## Left to the builder

Exact widget decomposition inside each feature, Cubit method names beyond
the shared contracts in the plan, and tiny rendering differences where
Flutter can't match CSS exactly (e.g. `mix-blend-mode`) — pick the closest
look and note it.
