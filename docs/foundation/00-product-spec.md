# 00 — Product Specification

> The definition of what StyloBuddy is and what it must do. Every other document serves this
> one. Where a later document contradicts it, this one wins until it is amended here.

---

## 1. One-sentence definition

StyloBuddy is a mobile app (Flutter, Android first, iOS later) where people catalogue the clothes
they own and get outfit suggestions, matching, planning and packing lists built only from those clothes.

## 2. The problem

People own many clothes yet "have nothing to wear". Existing outfit apps suggest imaginary or
purchasable items; StyloBuddy styles only what the user already owns.

## 3. Who it is for

| Actor | Needs |
|-------|-------|
| Primary user (demo user in Milestone 1) | Browse a wardrobe, get 3 looks for an occasion, match chosen pieces, save and plan looks, pack for trips |
| Guest | Explore the app without an account ("Skip for now") |
| Administrator | None in Milestone 1 |

## 4. Capabilities

Onboarding and demo auth (F02) · AI stylist with simulated results (F03) · Match My Clothes with
locked must-wear items (F04) · Home dashboard (F05) · Wardrobe browse/add/edit/import (F06) ·
Manual outfit builder (F07) · Saved looks and wear history (F08) · Calendar planner (F09) ·
Packing assistant (F10) · Shopping gap suggestions (F11) · Style insights (F12) ·
Profile, settings and premium preview (F13). All sit on the shared design foundation (F01).

## 5. Key interactions

1. Home -> "View outfits" -> 1150 ms "Putting looks together..." -> 3 looks (Refined Everyday, Modern Classic, Effortless Edge) -> open one -> "Save Outfit" -> toast "Saved to your outfits".
2. Wardrobe -> item -> "Find matching outfits" -> item is pre-selected and locked -> options -> up to 3 looks that all contain it.
3. Wardrobe -> Add clothing -> 3 sample photos -> analyze -> review each -> "Save to my wardrobe" -> wardrobe shows 26 pieces.
4. Saved look -> "Plan outfit" -> pick date -> calendar shows it with toast "Outfit planned for <date>".

## 6. Non-goals

Milestone 1 does NOT include: real AI, camera, Firebase/Supabase/RevenueCat wiring, push
notifications, real payments, web as a shipping target (web is only the verification surface).
No restyling, rewording, reordering or "improving" prototype screens (spec 2026-10-16 anti-goal).

## 7. Success criteria

- All 64 prototype routes (63 + generic fallback) render in the Flutter app and match the v23 prototype at 390x844.
- Copy is verbatim from `prototype/app.js`, including punctuation.
- `flutter test` and `flutter analyze` are clean; every feature document F01-F13 has all assertions PASS including `[L]`.
- Deleting any wardrobe item never crashes a screen that references it.
