# 04 — Interface Standards

> Conventions for every public interface. In this app the interfaces are **routes**, **Cubit public methods**, and **user-visible messages** (toasts and modals). Depends on `03-domain-model.md`.

---

## 1. Naming

- **Routes**: path = prototype route name, kebab-case, defined once in `AppRoutes` (e.g. `matchSelect = '/match-select'`). Id routes use query params and helpers: `clothing(id)` -> `/clothing?id=<id>`, `savedDetail(int)` -> `/saved-detail?id=<n>`, `wearDetail(int)` -> `/wear-detail?id=<n>`; bare paths are `clothingPath`, `savedDetailPath`, `wearDetailPath`.
- No-nav routes (`AppRoutes.noNavRoutes`): welcome, intro, personalize, auth, login, signup, forgot, reset-sent, verify-email. Start route `/welcome`.
- Route ownership: F02 the no-nav routes · F03 stylist, occasion, styling-options, generating, results, result-detail · F04 matching, match-select, match-review, match-options, matching-progress, matching-results, matching-detail · F05 home · F06 wardrobe, clothing, edit-item, filter, import, import-source, batch, analyzing, review, add-confirm · F07 builder, manual-preview · F08 saved, saved-detail, wear-detail · F09 calendar, calendar-choose, calendar-date · F10 packing, new-trip, packing-preview, packing-list, packing-add · F11 shopping, shop-item · F12 insights · F13 profile, edit-profile, edit-style, settings, notifications, weather-settings, support, support-detail, delete-account, signout, premium, plan, purchase, subscription.
- **Cubits**: `<Feature>Cubit` + `<Feature>State` in `lib/features/<f>/cubit/`; methods are verbs (`logWear`, `toggleLock`); getters for derived values; states are plain classes with `copyWith`.
- Navigation: drill-down `context.push`; tabs and resets `context.go`.

## 2. Request and response shape

There is no HTTP API in Milestone 1. Cubit methods are synchronous and return the affected entity when callers need it (`saveOrFind`, `upsertManual` return `Outfit`); async methods (`generateAutomatic`, `generateMatches`) return `Future<void>` and drive `isGenerating`. Repositories return `List<T>` snapshots (`WardrobeRepository.loadItems()`).

## 3. Errors

User-facing failures are **toasts** (`AppToast.show`, 2200 ms, dark `#172A20`), never exceptions. Validation failures leave state unchanged and keep the user on the screen. Verbatim copy (including `’`, `·`, `→`):

| Context | Message |
|---------|---------|
| Signup password < 8 | `Use at least 8 characters for your password.` (inline) |
| Confirm mismatch | `Passwords do not match. Please try again.` (inline) |
| Login success | `Signed in to demo account` |
| Verify continue | `Verification simulated` |
| Resend verification | `No real email is sent in this prototype` |
| Google / Apple button | `Google authentication UI preview` / `Apple authentication UI preview` |
| Personalize option | `<option> selected` |
| Edit item blank name | `Enter an item name` |
| Item edited / removed | `Clothing updated` / `Item removed` |
| Import review blank name | `Name is required` |
| Save result / wear / look / entry | `Saved to your outfits` / `Outfit wear recorded` / `Look removed` / `Wear entry removed` |
| Builder blank name / no items / saved | `Give your outfit a name` / `Choose at least one item` / `Outfit saved` |
| Plan from result | `Outfit scheduled for October <d>` |
| Plan from calendar / removed | `Outfit planned for <Month d, yyyy>` / `Plan removed` |
| Swap | `Garment replaced` / `No alternative in your wardrobe for this category` / `Mandatory items cannot be swapped` |
| Share copy | `Outfit details copied` / `Select and copy the text above` / `Outfit description copied` |
| Original outfit gone | `Original outfit was removed` |
| Trip validation | `Add a trip name and both dates` / `End date must be after start date` / `Trip removed` |
| Wishlist | `Added to wishlist` / `Removed from wishlist` |
| Profile | `Please enter a name and valid email` / `Profile updated in demo` / `Preferences saved` |
| Settings | `Notification preferences saved` / `Weather settings saved` / `Signed out of demo preview` / `No purchases to restore in this demo` |

Modal titles (via `AppModal`, ✕ close): `Clothing options`, `Remove clothing?`, `Plan this outfit`, `Swap <name>`, `Share this look`, `Share your outfit`, `Remove saved outfit?`, `Remove wear entry?`, `Remove this plan?`, `Delete this trip?`, `Add a travel essential`, `Deletion preview`.

## 4. Pagination, filtering and limits

No pagination. Wardrobe search is case-insensitive substring on name; saved search is trimmed + case-insensitive on name/occasion/item names. Text limits: outfit name 60, trip name 60, destination 70, profile name 64 characters. Simulated processing delay: 1150 ms.

## 5. Versioning and compatibility

Route paths and Cubit method names listed in feature documents section 6 are the contract between features; renaming one is a breaking change requiring every consumer's document to be amended with a dated note. `AppRoutes` constants never change value once shipped.
