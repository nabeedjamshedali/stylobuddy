# F11 — Shopping Assistant

> Wardrobe-gap suggestions drawn from a fixed five-item catalog, a wishlist, and a suggestion detail that links back to adding a purchase to the wardrobe. Plan Task 13 (shopping part, 13a); prototype `app.js:220-267`. Depends on foundation 03, 04.

**Status:** DONE (gates 1-3; gate 4 open) · **Milestone:** 1 · **Depends on:** F01

---

## 1. Goal

Show what to consider buying based on gaps in what the user owns, not trends.

## 2. MVP scope

Routes `/shopping /shop-item` (`shoppingRoutes`); `ShoppingCubit`; the five-entry catalog (neutral-blazer, versatile-knit, formal-shoes, everyday-bag, neutral-bottom) with title, category, tone, tag, description, pair ids, tip, symbol; art tiles built from the symbol and 'WARDROBE EDIT' caption.

## 3. Later scope

Real product listings, prices, store links (Phase 2 in the prototype copy).

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
/shopping (Discover | Wishlist tabs) -> card -> ShoppingCubit.selectedId = id -> /shop-item
/shop-item: "♡ Save to wishlist" toggles + toast ; "I bought something like this · Add to wardrobe" -> /import
```

## 6. Interface surface

Routes `/shopping /shop-item`.

```text
ShoppingCubit{String tab = 'discover'; List<String> wishlist; String selectedId}  (set tab, toggle wishlist(id) -> bool added, select(id))
suggestions(items) = port of shoppingSuggestions (thresholds: blazer Outerwear<4, knit Outerwear<5, formal-shoes Shoes<5, everyday-bag Accessories<6, neutral-bottom Pants<6)
Consumes: WardrobeCubit, AppToast, GarmentImage
```

## 7. Domain model usage

Reads `ClothingItem.category` counts and ids (for "style with what you own").

## 8. Data changes

None.

## 9. Background work and events

None.

## 10. Degradation and failure

All categories covered -> empty discover state. Unknown `selectedId` -> first catalog entry. Pair ids not in the wardrobe are omitted. Empty wishlist -> empty state.

## 11. Validation assertions

```
F11-A01  [U]  Shopping renders head 'Shopping Assistant', 'SMARTER SHOPPING', 'Wear more.' 'Buy intentionally.', 'Discover useful wardrobe additions based on what you already own—not random trends.'
F11-A02  [U]  With the seed wardrobe (Outerwear 2, Shoes 4, Accessories 5, Pants 4) all 5 suggestions show; tabs read 'Discover 5' and 'Wishlist 0'; the section reads 'Consider for your wardrobe' / 'Illustrative analysis' with the note 'These are sample wardrobe-gap ideas based on clothing categories—not live AI recommendations.'
F11-A03  [U]  Adding two more Outerwear items (4 total) removes 'Neutral tailored blazer' (needs <4) but keeps 'Lightweight layering knit' (needs <5); adding a third (5 total) removes the knit too
F11-A04  [U]  With 5 Shoes 'Dress-ready footwear' is hidden; with 6 Accessories 'Everyday structured bag' is hidden; with 6 Pants 'Versatile neutral bottoms' is hidden
F11-A05  [U]  When all five are hidden Discover shows 'Your wardrobe covers these categories' and 'Explore your clothing collection or return when you add more items.' (empty differs from the seed list)
F11-A06  [U]  Each card shows tag, title, tone and 'Explore suggestion →', e.g. 'Versatile layer' / 'Neutral tailored blazer' / 'Sand / charcoal'; tapping selects it and opens /shop-item
F11-A07  [U]  The phase block renders 'PHASE 1 · AVAILABLE IN PROTOTYPE' 'Shop your wardrobe gaps' and 'PHASE 2 · PLANNED' 'Explore real products' with 'Store availability, product links and prices will be added later. No live products are shown here.'
F11-A08  [U]  Toggling the wishlist on an unsaved id adds it, returns added, and toasts 'Added to wishlist'; toggling again removes it and toasts 'Removed from wishlist'
F11-A09  [U]  Wishlist tab shows '<n> saved' under 'Your shopping wishlist' and its cards in insertion order; empty shows '♡', 'Nothing saved yet', 'Explore suggestions and save ideas you want to remember.' and an 'Explore suggestions' button that switches to Discover
F11-A10  [U]  Wishlist keeps an entry even when that item is no longer in Discover (e.g. after the wardrobe changed)
F11-A11  [U]  Detail for 'neutral-blazer' renders head 'Wardrobe Suggestion', 'VERSATILE LAYER', title, 'Sand / charcoal · Outerwear', 'Why it could help', 'Style with what you own' with white-shirt, navy-chinos, brown-loafers, the tip, and the disclaimer 'These are category-level suggestions, not real store products or guaranteed AI compatibility scores.'
F11-A12  [U]  Detail for 'neutral-bottom' lists only white-sneakers and black-watch because 'green-shirt' is not in the seed wardrobe (missing pair id omitted, not a placeholder)
F11-A13  [U]  Detail button reads '♡ Save to wishlist' when unsaved and '✓ Saved · Remove from wishlist' when saved; tapping toggles and toasts as in A08
F11-A14  [U]  'I bought something like this · Add to wardrobe' opens /import
F11-A15  [U]  An unknown selectedId renders the first catalog entry ('Neutral tailored blazer') without throwing
F11-A16  [U]  Header back targets: shopping -> /home, shop-item -> /shopping
F11-A17  [L]  In the running web build at 390x844: /#/shopping shows Discover 5; open a suggestion, save it (toast 'Added to wishlist'), see Wishlist 1 and the entry on the Wishlist tab; screens match the prototype screenshots
```

## 12. Edge cases

Wishlist and tab are in-memory. Suggestion art is generated from the symbol glyph, not an image.

## 13. Open questions

None.

---

## Completion block

```
Status: DONE (gates 1-3; gate 4 open)

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 16/17 PASS (A17 is [L], deferred to the live parity pass)
Regression: flutter test — 336 passed, 0 failed; flutter analyze — No issues found!
```
