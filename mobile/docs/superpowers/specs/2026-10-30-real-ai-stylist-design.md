# Real AI stylist (Gemini Flash behind `ai-stylist`) — design

## Intent and why

The "AI-powered personal stylist" is the app's reason to exist, but today
its suggestions are not driven by the user's wardrobe. `StylistCubit.
generateAutomatic()` picks from three hard-coded outfits made of the sample
wardrobe's item ids (`white-shirt`, `navy-chinos`, ...) and keeps only the
ones the user happens to own; for someone who uploaded their own clothes it
returns almost nothing. `generateMatches()` is a rule-based combiner over the
selected pieces. The on-screen copy admits this ("Styling examples are
simulated").

This change makes the stylist real for signed-in users: the `ai-stylist`
Supabase Edge Function (deployed 2026-10-29 as a 501 stub, F23) gets a
Gemini Flash provider behind the existing `LlmAdapter` seam, and the
Flutter app calls it from `StylistCubit`, falling back to today's behaviour
whenever the AI path is off, unavailable or fails.

The user chose Gemini Flash (cheapest per request, free tier) on
2026-10-29. They cannot enable Google Cloud billing right now (card
verification fails), so v1 runs on the free tier of the Gemini API. That
shapes several decisions below.

## Goals

- `ai-stylist` returns `200` with 1-3 validated outfits when
  `LLM_PROVIDER=gemini` and `GEMINI_API_KEY` are set; it still returns
  `501 {"error":"AI provider not configured yet"}` when they are not (the
  F23 contract for the unconfigured state is preserved exactly).
- Outfits are built **only** from the wardrobe items the client sent. Any
  item id the model invents is dropped server-side; an outfit left with
  fewer than 2 valid items is dropped; if none survive the function
  returns a defined error, never an empty `200`.
- The app uses the AI path only when: Remote Config flag `ai_stylist_enabled`
  is true (F25), the user is signed in (the function needs a Firebase ID
  token), and the wardrobe is non-empty. Otherwise, and on any failure
  (network, timeout, 4xx/5xx, malformed body, zero outfits), it silently
  falls back to the existing algorithmic generation. The app never shows an
  AI error screen.
- The results screen is honest about which path produced the result.
- Per-user daily cap enforced server-side so one account cannot drain the
  shared free quota.

## Non-goals

- No streaming, chat, or free-text prompting from the user in v1.
- No server-side wardrobe lookup: the function stays stateless with respect
  to Firestore. The client sends what it wants styled.
- No fine-tuning, embeddings, image input (no photo analysis), or
  multi-provider routing. The `LlmAdapter` seam stays so another provider can
  be added later without touching the handler or the app.
- No change to the male/female onboarding (F24) or to how results are saved,
  planned or shared once generated.
- No paid-tier setup, no Google Cloud billing work.
- Guests (no Firebase user) do not get AI in v1.

## Anti-goals (failure even if it technically works)

- A suggestion that includes a garment the user does not own.
- The app hanging or erroring because the AI call is slow or down.
- The results screen claiming "AI" when the fallback produced the result, or
  claiming "simulated" when Gemini produced it.
- Sending anything personally identifying (uid, email, name, gender,
  photos) to Gemini.

## Constraints

- Stack is fixed for v1: Supabase Edge Function (Deno) + Firebase Auth.
  Provider code goes in `supabase/functions/_shared/` behind
  `getLlmAdapter()`; secrets only through `supabase secrets set`
  (`docs/foundation/07-security.md` §4), never committed or logged.
- The function must keep verifying the Firebase ID token first, with the
  F23 behaviour for bad tokens (plain-text `Unauthorized` 401) unchanged.
- F23's 501-when-unconfigured contract, and the rule that the request body
  is not read before auth succeeds, stay true.
- Document-driven workflow (`docs/README.md`): a numbered feature document
  (F26) with assertions is written before code; F23 and F25 are amended
  where this changes them.
- Android first. The app change is platform-neutral Dart.
- The Gemini **free tier** may use submitted content to improve Google's
  products, and has low rate limits (per-minute and per-day). So the
  payload must contain only what styling needs (see Request contract), and
  the privacy policy must disclose third-party AI processing before this
  flag is switched on in production.

## Decisions made (the "how", settled by me as the engineer)

**D1 — Provider code and model.** A `gemini` adapter registered in
`getLlmAdapter()` (selected by `LLM_PROVIDER=gemini`), calling the Gemini
REST API (`generativelanguage.googleapis.com`) with `fetch` and the key in
the `x-goog-api-key` header (never in a URL, never logged). Model name from
`GEMINI_MODEL` with a default of `gemini-2.5-flash`; it is an env var because
Google retires and replaces Flash versions, and the first live probe
(`models.list`) confirms the default is still served before the flag is
turned on. Temperature ~0.7 (varied looks), thinking disabled/minimal
(latency and free-quota), `maxOutputTokens` capped, request timeout 12 s.

**D2 — Structured output, validated twice.** The call uses Gemini's JSON
mode with a response schema (`outfits[]: {name, why, itemIds[]}`), and the
handler re-validates the parsed result regardless (schema compliance is a
request, not a guarantee): drop unknown ids, dedupe ids within an outfit,
require 2-6 items, truncate `name` to 40 chars and `why` to 160, cap at 3
outfits, and drop outfits that are the same set of ids.

**D3 — Request contract** (`POST /functions/v1/ai-stylist`, JSON,
`Authorization: Bearer <Firebase ID token>`):
`{ occasion, styleDirection, weather, includeAccessories, mode:
"auto" | "match", lockedIds[], selectedIds[], items: [{id, name, category,
color, occasion, season}] }`. Limits enforced before calling Gemini: body
<= 64 KB, `items` 1-120 entries (the client sends the 120 most relevant if
the wardrobe is larger, preferring selected/locked ones), each string
<= 60 chars, `lockedIds`/`selectedIds` must be subsets of `items`. Violations
return `400 {"error": "..."}` with a fixed message, not echoing input.
In `match` mode every outfit must contain all `lockedIds` (re-checked
server-side; outfits missing a locked id are dropped).
Nothing identifying is forwarded to Gemini: the prompt contains only the
fields above. The verified uid is used for the rate limit only.

**D4 — Response contract.** `200 {"outfits": [{"name", "why", "itemIds"}]}`.
Errors: `400` bad request, `401` (F23 unchanged), `429
{"error": "Daily AI styling limit reached"}`, `502 {"error": "AI styling
failed"}` for provider errors, timeouts, unparseable output, or zero valid
outfits, `501` unconfigured (F23 unchanged). Error bodies never contain
provider text, the key, the token or the uid.

**D5 — Per-user daily cap in Supabase Postgres.** The Supabase project's
Postgres is otherwise unused (D1 of the backend architecture), and the
function already runs next to it. A small table `ai_usage(uid_hash text, day
date, count int, primary key (uid, day))` with RLS enabled and no policies
(only the service role can touch it; the `uid` column holds the **SHA-256
hex of the Firebase uid**, never the raw uid), and one SQL function
`ai_usage_try_increment(p_uid_hash text, p_day date, p_limit int) returns
boolean` that atomically increments and returns whether the call is
allowed. The function calls it with the service-role key that Supabase
injects into Edge Functions. Limit from `AI_DAILY_LIMIT` (default 30). The cap counts **attempts** that
reach the provider, not only successes: no refund path, so the SQL stays one
function (a flaky-provider day can burn a user's allowance; the app falls
back silently, so the cost is a worse suggestion, not an error).
The check happens after auth and request validation and before the Gemini
call. **If the database is unreachable the request is allowed** (fail
open): Gemini's own quota is the backstop and availability beats
strictness at this scale; the failure is logged without the uid. The
migration is applied through the Supabase Management API with the access
token already in `~/.secrets`, and the SQL is committed under
`supabase/migrations/`.

**D6 — Client wiring.** A small `AiStylistClient` interface in
`lib/shared/backend/` with an HTTP implementation (gets the ID token from
`FirebaseAuth`, posts to the function URL, 15 s timeout, maps every failure
to "unavailable") and a fake for tests. `StylistCubit` gains an optional
`AiStylistClient` and a "may use AI" predicate (flag on + signed in +
non-empty wardrobe). `generateAutomatic()` and `generateMatches()` try the
AI first when allowed and otherwise run today's code untouched, so every
existing F03/F04/F05 test passes unchanged with no client injected. The
1.15 s generation animation stays; a fast AI answer waits out the minimum so
the screen does not flash.

**D7 — Honest labelling.** `StyleResult` gets a `source` (`ai` or
`algorithm`). The disclaimer on the results screen reads
"Styled by AI from the pieces in your wardrobe." for `ai` results and keeps
today's "Styling examples are simulated. No real AI evaluation or
percentage scores are claimed." for `algorithm` results. F03-A24 is amended
accordingly (dated). Two more places say the same "simulated" thing and
become false with AI on, so they change too: the hub line in
`stylist_view.dart` ("Interactive concept • recommendations are simulated,
not generated by a live fashion model.") reads "Recommendations are
generated by AI from the pieces in your wardrobe." whenever AI is available
(flag on, signed in), and the disclosure in `detail_modals.dart` follows the
result's `source` the same way as the results screen. The views read one
getter, `StylistCubit.aiAvailable`. **A swap flips `source` to `algorithm`**
(it already replaces an item and overwrites `why` with the canned preview
text, so the look is no longer what the AI produced); the label reverts to
the existing preview wording. Each affected assertion (F03-A19, A24 and the
detail-modal one) gets a dated amendment, not a deletion.

**D8 — Rollout is a flag, not a build.** `ai_stylist_enabled` stays `false`
in Remote Config (F25) until the function is live with a key, the live
probes pass, and the user has updated the privacy policy. Flipping it needs
no app release. Turning it back off is the kill switch.

## Settled after the builder check (2026-10-30)

- **Interface:** `LlmAdapter.generateOutfitSuggestion(prompt): Promise<string>`
  is unchanged. JSON mode, the response schema and the timeout live inside
  the Gemini adapter; the handler parses and validates the returned string.
- **Unconfigured states stay 501:** `LLM_PROVIDER=gemini` with no (or empty)
  `GEMINI_API_KEY` returns `null` with its own distinct warning, so the
  client still gets F23's 501. Unset, empty and unregistered names behave as
  F23-A05/A06/A12 specify.
- **F23 amendments (dated, nothing deleted):** A07 ("uid never stored")
  now permits a one-way SHA-256 hash for the rate limit while still
  forbidding the raw uid in any response, log or store; A09 (the adapter
  branch no longer returns a stub; it now reads the body and answers 200);
  A14/A15 (`Deno.env` reads and imports are no longer confined to
  `llm-adapter.ts`/two shared modules: the usage limiter reads
  `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in its own module, and the
  handler receives its collaborators through the existing injectable-deps
  pattern).
- **Wiring facts found in the code:** `StylistCubit` is built in
  `lib/app.dart` with only `WardrobeCubit`, so it has no access to Remote
  Config or auth today; app.dart passes it the client and an
  `aiAvailable` predicate (flag on + signed in). `ai_stylist_enabled`
  already exists in F25's `RemoteConfigKeys`/`AppConfig`.
- **Credentials:** the Supabase access token is in `~/.secrets` and works
  (used for the F23 deploy). No Gemini key exists yet, so the function can
  be deployed and tested with a faked provider but the live probe and the
  flag flip wait for the key. Until then production keeps answering 501 and
  the app keeps using the algorithmic path.

## What is left to the builder

- Exact prompt text (system instruction + user content), as long as it
  states the "only these item ids" rule and the locked-item rule, and
  contains none of the data excluded in D3.
- Exact Gemini request/response field mapping for the REST call (verified
  once against the live API with the real key).
- How the client picks the "120 most relevant" items when the wardrobe is
  larger.
- Test seam shape for the Edge Function's `fetch` and DB calls (follow the
  injectable-deps pattern of F23's `handleRequest`).
- Whether the minimum animation wait is implemented in the cubit or the view.
