# F26 — Real AI Stylist (Gemini Flash behind `ai-stylist`)

> Makes the stylist real for signed-in users. The `ai-stylist` Supabase Edge
> Function (deployed 2026-10-29 as F23's `501` stub) gains a Gemini provider
> behind the existing `LlmAdapter` seam, a request contract, a two-stage
> output validator (Gemini JSON mode, then the handler's own checks) and a
> per-user daily cap stored in Supabase Postgres (`ai_usage`, uid stored only
> as a SHA-256 hash). The Flutter app calls it from `StylistCubit` through a
> new `AiStylistClient` when Remote Config `ai_stylist_enabled` is on, the
> user is signed in and the wardrobe is not empty. On every other path, and
> on any failure, it falls back silently to today's algorithmic generation.
> Results carry a `source` (`ai` or `algorithm`), and the three on-screen
> disclaimers say which one produced the result. Source of truth for scope
> and decisions D1-D8 and the "Settled after the builder check" section:
> `docs/superpowers/specs/2026-10-30-real-ai-stylist-design.md`. Depends on
> F03 (`StylistCubit`, results/detail views), F23 (`ai-stylist`,
> `LlmAdapter`, `getLlmAdapter`, `verifyFirebaseToken` reuse), F25
> (`RemoteConfigKeys.aiStylistEnabled`, `AppConfig.aiStylistEnabled`,
> `AppConfigCubit`, `AnalyticsService`) and F14 (uid-keyed subtree in
> `lib/app.dart`). Foundation: 01, 03 (amended, §13 P1), 05, 06, 07
> (amended).

**Status:** NOT STARTED · **Milestone:** 3 · **Depends on:** F03, F23, F25, F14

---

## 1. Goal

Today "Style me for today" picks from three hard-coded outfits made of sample
item ids. For a user who uploaded their own clothes it returns almost
nothing, and the screen admits the results are simulated. This feature lets a
signed-in user get 1-3 outfits that Gemini composed **only from the pieces in
their own wardrobe**, for the occasion, style direction and weather they
chose. Match My Clothes works the same way, always keeping the user's locked
pieces. The app never shows an AI error. If the AI is off, slow, over quota or
broken, the user gets today's suggestions and the screen honestly says they
are simulated. The rollout is one Remote Config flag (D8), so the feature can
ship dark and be switched off without a release.

## 2. MVP scope

### 2.1 Edge Function (Deno, `supabase/functions/`)

- **`_shared/gemini-adapter.ts` (new).** It implements `LlmAdapter` against
  the Gemini REST API with `fetch` and no SDK. Exact call shape is in §6.2.
  - JSON mode with a fixed response schema.
  - Temperature `0.7`, `maxOutputTokens` `1024`, thinking disabled
    (`thinkingBudget: 0`).
  - 12 s timeout (`GEMINI_TIMEOUT_MS = 12000`).
  - The key is sent only in the `x-goog-api-key` header.
  - The model comes from `GEMINI_MODEL`, defaulting to `gemini-2.5-flash`
    (D1).
  - It throws `LlmProviderError` with a fixed `code` for every failure
    (§6.2). It never parses outfits; it returns the model's text.
  - `geminiAdapterFromEnv()` reads `GEMINI_API_KEY` and `GEMINI_MODEL`. These
    are the only environment reads in this file.
- **`_shared/llm-adapter.ts` (amended).** The `LlmAdapter` interface is
  byte-identical (settled after the builder check). `getLlmAdapter()`
  registers exactly one provider: `LLM_PROVIDER` whose trimmed value is
  exactly `gemini` (case-sensitive) delegates to `geminiAdapterFromEnv()`.
  The unset, empty and unregistered behaviour and warnings are unchanged
  (F23-A10..A12). `gemini` with a missing or empty key returns `null` with
  its own warning, so the client still gets F23's `501`.
- **`_shared/usage-limit.ts` (new).** It contains:
  - `hashUid` (SHA-256, lowercase hex);
  - `readDailyLimit` (`AI_DAILY_LIMIT`, default 30);
  - `checkDailyUsage(uid, deps?)`, which calls the SQL function
    `ai_usage_try_increment` through PostgREST RPC with the platform-injected
    service-role key. It fails open (D5).

  It is the only file in the `ai-stylist` import graph that reads
  `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` or `AI_DAILY_LIMIT`.
- **`ai-stylist/stylist-contract.ts` (new, pure: no env, no network).** It
  contains:
  - `parseStylistRequest(json)`, which validates and returns either a typed
    request or one of the six fixed 400 messages;
  - `buildPrompt(request)`;
  - `validateOutfits(rawText, request)`, the D2 pipeline in §5.3.
- **`ai-stylist/index.ts` (amended).** The same `handleRequest(req, deps)`
  shape, with one new injectable `checkUsage`. The flow is §5.1.
- **`supabase/migrations/20261030000000_ai_usage.sql` (new).** It creates
  the table, the function and the grants, with the exact SQL in §8.
- **Tests:**
  - `ai-stylist/index.test.ts`, extended: the F26 `[U]` handler tests, the
    `[I]` real-module tests, and the amended F23 tests;
  - `ai-stylist/stylist-contract.test.ts`;
  - `_shared/gemini-adapter.test.ts`;
  - `_shared/usage-limit.test.ts`;
  - `supabase/tests/ai_usage.test.ts`, the SQL `[I]` tests against a local
    Supabase Postgres (§11 gates).

  Test names are prefixed `F26_Axx`.
- **`supabase/config.toml`:** unchanged. `[functions.ai-stylist]
  verify_jwt = false` already exists (F23-A21).

### 2.2 Flutter app

- **`lib/shared/backend/ai_stylist_client.dart` (new, SDK-free).** It defines
  the interface and the wire models (§6.3). `StylistCubit` imports only this
  file.
- **`lib/shared/backend/http_ai_stylist_client.dart` (new).**
  `HttpAiStylistClient` imports `package:http` and `package:firebase_auth`,
  following `StorageRepository`'s pattern. Only `lib/app.dart` imports it.
  Its constructor touches neither `FirebaseAuth.instance` nor the network.
  The token is read lazily inside `suggest()`.
- **`test/support/fake_ai_stylist_client.dart` (new, test-only).**
  `FakeAiStylistClient` takes a scripted result (outfits, `null`, an error to
  throw, a delay, or never completing) and records every request. There is
  no fake under `lib/`.
- **`StyleResult`** gains `final StyleResultSource source` (default
  `StyleResultSource.algorithm`). The value is part of `copyWith`, and the
  enum is `{ ai, algorithm }`. Every existing `StyleResult(...)` call compiles
  unchanged.
- **`StylistState`** gains a getter `bool get resultsByAi =>
  results.isNotEmpty && results.every((r) => r.source ==
  StyleResultSource.ai)`. There is no new field.
- **`StylistCubit`** gains:
  - the optional named parameters `AiStylistClient? aiClient` and `bool
    Function()? aiAvailable`;
  - the getter `bool get aiAvailable`;
  - `static const aiTimeout = Duration(seconds: 16)`.

  `generateAutomatic()` and `generateMatches()` try the AI first when §5.4's
  predicate holds, and otherwise run today's code unchanged.
  `generationDelay` (1150 ms) becomes the **minimum** wait on the AI path.
  This is decided here: the wait is implemented in the Cubit, not the view
  (design "left to the builder").
- **`swapItem`** also sets `source: StyleResultSource.algorithm` on the
  updated result (D7).
- **Honest labelling (D7).** The exact strings are:

  | Place | When | Text |
  |---|---|---|
  | `results_view.dart` `DemoNote` (`DemoNoteStyle.ai`) | `state.resultsByAi` | `Styled by AI from the pieces in your wardrobe.` |
  | same | otherwise (algorithm, empty, or any result swapped) | `Styling examples are simulated. No real AI evaluation or percentage scores are claimed.` (unchanged) |
  | `stylist_view.dart` hub `DemoNote` | `context.read<StylistCubit>().aiAvailable` | `Recommendations are generated by AI from the pieces in your wardrobe.` |
  | same | otherwise | `Interactive concept • recommendations are simulated, not generated by a live fashion model.` (unchanged) |
  | `detail_modals.dart` `DetailFootnote` | the active result's `source == ai` | `Styled by AI from the pieces in your wardrobe.` |
  | same | `source == algorithm` | `Outfit selections and styling explanations are simulated for design review.` (unchanged) |

  `DetailFootnote` becomes `const DetailFootnote({super.key, this.source =
  StyleResultSource.algorithm})`. `result_detail_view.dart` passes
  `r.source`. All three places still honour `kShowDemoNotes`, which is
  unchanged.
- **`lib/app.dart` wiring.** The `StylistCubit` `BlocProvider` in the
  uid-keyed subtree changes as follows:
  - `aiClient`: `snapshot.data == null ? null : (widget.aiStylistClient ??
    HttpAiStylistClient())`.
  - `aiAvailable`: `() => snapshot.data != null &&
    _appConfig.state.config.aiStylistEnabled`.

  `StyloBuddyApp` gains a test-only seam, `final AiStylistClient?
  aiStylistClient`, which production never sets. Guests never get a client.
- **No analytics change.** `outfit_generated` keeps exactly F25's parameters
  (`mode`, `result_count`) on both paths. It is logged once per emitted
  result set, after the (possibly longer) wait. Whether to record the source
  is §13 Q2.

### 2.3 Docs (applied with this document, dated 2026-10-30)

- **`03-domain-model.md`:** adds `StyleResult.source`, documents the
  pre-existing `StylistState.styleDirection`/`weather`, marks
  `AppConfig.aiStylistEnabled` as consumed by F26, and adds a §4 row.
- **`07-security.md` §4:** the secrets, the `ai_usage` table and the
  third-party processing disclosure.
- **`01-tech-stack.md`:** a dated note.
- **Amendments:** F23 (A07, A09, A11, A12, A14, A15, A18, A19, A24, §4, §6)
  and F03 (A05, A16, A19, A22, A24, A25), plus F04-A14 and F04-A15 (§13
  P2).

## 3. Later scope

- Streaming, chat or free-text prompting, image input (photo analysis),
  embeddings, multi-provider routing (design non-goals).
- AI for guests (no Firebase token, so no rate-limit key).
- A refund of the daily allowance when the provider fails (D5 counts attempts).
- CORS / `OPTIONS` preflight (still no browser caller; F23 §3).
- Paid-tier Gemini, Google Cloud billing, a data-processing agreement.
- Server-side wardrobe lookup (the function stays stateless towards
  Firestore).
- Re-fetching Remote Config mid-session (F25 §3): the hub line follows the
  flag at the screen's next build.
- An analytics parameter for the result source (§13 Q2).
- iOS: nothing platform-specific is added (Dart + an Edge Function). iOS
  inherits this once the iOS app ships. **Not Android-only.**

## 4. Roles and permissions

Roles from `docs/foundation/07-security.md` §2.

| Role | AI path | Function access |
|---|---|---|
| guest / demo user | Never: `aiClient` is `null`, so `aiAvailable == false` and nothing calls the client (A60, A73) | Calling it directly without a token gets `401 Unauthorized` (unchanged) |
| authenticated user, flag off | Never: the predicate is false and there is no network call | Could call it directly with their own token; the per-user cap still applies |
| authenticated user, flag on, non-empty wardrobe | Yes, up to `AI_DAILY_LIMIT` attempts per UTC day, after which it gets `429` and the app falls back | The verified uid is used only as `SHA-256(uid)` for the cap |
| anyone with a missing/invalid/expired/forged token | — | `401`, before anything else runs; the body is not read (A01, A44) |
| Supabase `anon` / `authenticated` Postgres roles | — | No access to `ai_usage` or `ai_usage_try_increment` (RLS on, no policies, execute revoked; A49, A77) |

Isolation:
- one user's requests can only consume their own allowance, because the hash
  comes from the verified token, never the body (A36);
- a response is built only from the caller's own request, so there is no
  cross-user data;
- nothing is stored except `(uid_hash, day, count)`.

## 5. Main flows

### 5.1 `handleRequest` (Edge Function)

```text
client -> ai-stylist: POST, Authorization: Bearer <Firebase ID token>, JSON body (§6.1)
handleRequest(req, deps):
  1. uid = await verify(req)                         # F15 verifyFirebaseToken, unmodified
     !uid -> 401 text/plain "Unauthorized"            # body unread; getAdapter/checkUsage never called (F23 unchanged)
  2. adapter = getAdapter()                          # getLlmAdapter()
     null -> 501 {"error":"AI provider not configured yet"}   # body still unread (F23-A08 holds)
  3. body (§5.2): Content-Length > 65536 -> 400 "Request body too large" (unread);
     stream-read, abort as soon as total > 65536 bytes -> 400 "Request body too large";
     UTF-8 decode + JSON.parse; not a plain object -> 400 "Invalid request body"
  4. request = parseStylistRequest(json)              # §6.1 rules, fixed order; first failure wins -> 400
  5. decision = await checkUsage(uid)                 # SHA-256(uid) -> RPC; throws -> treated as "allowed"
     "limited" -> 429 {"error":"Daily AI styling limit reached"}   # no provider call
  6. prompt = buildPrompt(request)                    # only §6.1 fields; never uid/token/hash
     raw = await adapter.generateOutfitSuggestion(prompt)
     throws -> console.error("ai-stylist: provider call failed (<code>)") -> 502 {"error":"AI styling failed"}
  7. outfits = validateOutfits(raw, request)          # §5.3
     [] -> console.error("ai-stylist: provider output had no valid outfits") -> 502 {"error":"AI styling failed"}
  8. 200 application/json {"outfits":[{"name","why","itemIds"}, ...]}   # 1..3
  any unexpected throw after step 1 -> console.error("ai-stylist: unexpected error (<error.name>)")
     -> 502 {"error":"AI styling failed"}             # never an unhandled 500, never undefined
```

`<code>` is `LlmProviderError.code` (§6.2), or `unknown` for any other
thrown value. No log line ever includes the error's message, the provider's
response text, the prompt, the request body, the uid, its hash, the token or
any key (A18).

### 5.2 Body reading

The handler never buffers more than 65 537 bytes. A `Content-Length` header
above 65 536 is rejected before reading, so `req.bodyUsed` stays `false`.
Otherwise the body is read from `req.body` chunk by chunk, and reading stops
with the 400 the moment the running total exceeds 65 536 bytes. A body of
exactly 65 536 bytes is accepted. A missing body (`GET`, or a `POST` with
none) decodes to `""`, which is not JSON, so it gets `400 "Invalid request
body"`.

### 5.3 Output validation pipeline (`validateOutfits`, D2)

The input is the adapter's raw string and the validated request. The output
is 0-3 outfits.

```text
1. JSON.parse(raw); throws -> []
2. top must be a plain object whose "outfits" is an array; else []
3. for each element, in order, until 3 have been kept:
   a. element must be a plain object with string "name", string "why", array "itemIds"; else drop
   b. ids = itemIds entries that are strings AND exactly (case-sensitive) equal to a request.items[].id;
      others (unknown ids, non-strings) are removed
   c. dedupe ids keeping the first occurrence (order otherwise preserved)
   d. mode "match": if any request.lockedIds is not in ids -> drop
      mode "match" and includeAccessories false: if any id is not in request.selectedIds -> drop
         (F04-A14: with "Complete my outfits" off, looks contain only selected items)
   e. require 2 <= ids.length <= 6; else drop                    # >6 is dropped, not truncated
   f. name = collapse every whitespace run (incl. \n \t) to one space, trim;
             empty -> drop; truncate to the first 40 Unicode code points, then trimEnd
      why  = same normalisation; empty -> drop; first 160 code points, then trimEnd
   g. key = sorted ids joined by "|"; key already kept -> drop (does not count toward 3)
   h. keep {name, why, itemIds: ids}                             # exactly these three keys
4. return kept (0..3)
```

### 5.4 App: `StylistCubit` generation

```text
aiAvailable (getter) = aiClient != null && (aiAvailable predicate?.call() ?? false)
mayUseAi(match) = aiAvailable
                  && wardrobe.state.items.isNotEmpty
                  && request (§6.4) could be built
                       # match: >= 1 owned selected id; every locked id has id length <= 60
generateAutomatic() / generateMatches():
  if isGenerating -> return (unchanged)
  snapshot NOW (call time, as today): occasion, fallback results = today's code path's results
     (templates / createMatches, names, _why), each source algorithm
  if !mayUseAi -> today's code path exactly: emit isGenerating, wait 1150 ms, emit, log outfit_generated
  else:
    emit isGenerating true                                     # GeneratingView shows at once
    request = AiStylistRequest(... §6.4)
    ai = await Future.wait([ Future.delayed(1150 ms),
                             client.suggest(request).timeout(aiTimeout 16 s) catching every throw -> null ])
    if isClosed -> return (no emit, no analytics)
    outfits = ai filtered client-side (A59): ids outside request.items dropped, <2 ids dropped,
              match mode missing a locked id dropped, match mode with includeAccessories false
              containing an id outside selectedIds dropped (same rules as §5.3 b-e)
    outfits non-empty -> results[i] = StyleResult(id: clock()+i, name, items: itemIds, occasion: snapshot,
                                                  why, source: ai)
    else              -> results = the fallback results snapshotted above (source algorithm)
    emit results, isMatchMode: match, isGenerating false
    analytics.outfitGenerated(mode, resultCount: results.length)     # once, either path
```

No state field, toast, dialog or log line visible to the user reports the
failure (anti-goal: no AI error UI, A68).

### 5.5 App: end-to-end (signed-in, flag on)

```text
/stylist hub: line "Recommendations are generated by AI from the pieces in your wardrobe."
"Style me for today" -> /occasion -> Next -> /styling-options -> "Generate 3 looks ✧"
  -> StylistCubit.generateAutomatic() (AI path) -> /generating for max(1150 ms, AI time)
  -> /results: AI names, "Styled by AI from the pieces in your wardrobe."
  -> card -> /result-detail: footnote "Styled by AI from the pieces in your wardrobe."
  -> Swap a piece -> result.source = algorithm -> footnote reverts to the simulated wording;
     back on /results the list label reverts to the simulated wording (one result is no longer AI)
  -> Save / Plan / Share: unchanged (F03-A27/A28/A32), using the AI name/items/why
Fallback (timeout, 4xx/5xx, 429, malformed, zero outfits, offline):
  same screens, same timing ceiling (<= 16 s), algorithm looks, simulated labels, no error UI
```

### 5.6 Deploy and rollout (gated, never automatic; D8)

```text
Phase A — needs only the user's deploy go-ahead (no Gemini key):
  1. apply supabase/migrations/20261030000000_ai_usage.sql through the Management API
     (access token from ~/.secrets, never echoed or committed); verify A77
  2. supabase functions deploy ai-stylist --project-ref dbaeaqyoyilxcuwplvuw (ai-stylist only)
  3. live probes A78 (LLM_PROVIDER still unset -> 501), A79 (LLM_PROVIDER=gemini, no key -> 501)
Phase B — PENDING the user's Gemini API key:
  4. supabase secrets set GEMINI_API_KEY (+ LLM_PROVIDER=gemini; GEMINI_MODEL only if A80 says so)
  5. live probes A80-A85; device walk A86
  6. user confirms the privacy policy discloses Gemini processing -> publish ai_stylist_enabled = true (A87)
Kill switch: publish ai_stylist_enabled = false (no release), or set AI_DAILY_LIMIT=0 (server-side, immediate).
```

## 6. Interface surface

### 6.1 HTTP: `POST https://dbaeaqyoyilxcuwplvuw.supabase.co/functions/v1/ai-stylist`

Headers: `Authorization: Bearer <Firebase ID token>`, `Content-Type:
application/json`. Request (D3):

```json
{
  "occasion": "Office",
  "styleDirection": "Smart casual",
  "weather": "Mild / all season",
  "includeAccessories": true,
  "mode": "match",
  "lockedIds": ["white-shirt"],
  "selectedIds": ["white-shirt", "navy-chinos", "blue-jeans"],
  "items": [
    {"id": "white-shirt", "name": "White Oxford Shirt", "category": "Shirts",
     "color": "White", "occasion": "Office", "season": "All season"}
  ]
}
```

Validation, in this order, where the first failure returns `400
application/json {"error": "<message>"}`. Messages are fixed strings and never
contain input:

| # | Rule | Message |
|---|---|---|
| 1 | Body > 65 536 bytes (§5.2) | `Request body too large` |
| 2 | Not UTF-8 JSON, or not a plain object (array, `null`, number, string) | `Invalid request body` |
| 3 | `mode` is exactly `"auto"` or `"match"` (missing, `""`, `"AUTO"` and non-strings all fail) | `Invalid mode` |
| 4 | `occasion`, `styleDirection`, `weather`: each a string with `length <= 60` and a non-empty `trim()`. `includeAccessories`: a boolean (missing fails; `false` is valid) | `Invalid styling options` |
| 5 | `items`: an array of 1-120 plain objects. Each has all six keys `id`, `name`, `category`, `color`, `occasion`, `season`, every one a string of `length <= 60`. `id` is non-empty and equal to its own `trim()`. Ids are pairwise distinct. `name`/`category`/`color`/`occasion`/`season` may be `""` (present-but-empty is valid; a missing key fails) | `Invalid items` |
| 6 | `lockedIds` and `selectedIds`: both keys present (missing fails, `[]` is valid), each an array of strings with no duplicates and every entry an `items[].id`. `auto`: both must be `[]`. `match`: `selectedIds.length >= 1`, `lockedIds` ⊆ `selectedIds`, `lockedIds.length <= 6` | `Invalid selection` |

`length` is the JavaScript string length (UTF-16 code units). Unknown keys,
at the top level or inside items, are ignored and **never forwarded** to
Gemini (A28). Values used in the prompt are the validated ones (styling
strings trimmed; ids exactly as sent).

Responses (D4). This is every response the function can return:

| Status | Content-Type | Body | When |
|---|---|---|---|
| 200 | `application/json` | `{"outfits":[{"name":"...","why":"...","itemIds":["...",...]}]}` (1-3 outfits, each exactly these 3 keys) | success |
| 400 | `application/json` | `{"error":"<one of the 6 messages>"}` | §6.1 validation |
| 401 | `text/plain` | `Unauthorized` | missing/invalid token (F23, unchanged) |
| 429 | `application/json` | `{"error":"Daily AI styling limit reached"}` | cap reached, or `AI_DAILY_LIMIT=0` |
| 501 | `application/json` | `{"error":"AI provider not configured yet"}` | `getLlmAdapter()` returned `null` (F23, unchanged) |
| 502 | `application/json` | `{"error":"AI styling failed"}` | provider error/timeout/block, unparseable output, zero valid outfits, unexpected error |

F23's adapter-present `501 {"error":"AI stylist not implemented yet"}` is
retired. That string no longer exists in `index.ts` (amended F23-A09).

### 6.2 Deno modules

```text
supabase/functions/_shared/llm-adapter.ts
  export interface LlmAdapter { generateOutfitSuggestion(prompt: string): Promise<string> }   # UNCHANGED
  export function getLlmAdapter(): LlmAdapter | null
    LLM_PROVIDER unset                 -> null; warn "LLM_PROVIDER is not set"                  (F23)
    "" / whitespace-only               -> null; warn "LLM_PROVIDER is set but empty"            (F23)
    trimmed value === "gemini"         -> geminiAdapterFromEnv()                                 (F26)
    anything else (incl. "Gemini")     -> null; warn `LLM_PROVIDER "<value>" is not a registered provider` (F23)
  sole import: import { geminiAdapterFromEnv } from "./gemini-adapter.ts"

supabase/functions/_shared/gemini-adapter.ts
  import type { LlmAdapter } from "./llm-adapter.ts"          # type-only (erased); no other import
  export const GEMINI_DEFAULT_MODEL = "gemini-2.5-flash"
  export const GEMINI_TIMEOUT_MS = 12000
  export class LlmProviderError extends Error { readonly code: string }   # message === code
  export interface GeminiAdapterOptions { apiKey: string; model?: string; fetch?: typeof fetch; timeoutMs?: number }
  export function createGeminiAdapter(options: GeminiAdapterOptions): LlmAdapter
  export function geminiAdapterFromEnv(): LlmAdapter | null
    GEMINI_API_KEY unset               -> null; warn "GEMINI_API_KEY is not set"
    GEMINI_API_KEY "" / whitespace     -> null; warn "GEMINI_API_KEY is set but empty"
    GEMINI_MODEL unset                 -> GEMINI_DEFAULT_MODEL, no warn
    GEMINI_MODEL "" / whitespace       -> GEMINI_DEFAULT_MODEL; warn "GEMINI_MODEL is set but empty; using gemini-2.5-flash"
    GEMINI_MODEL not matching ^[a-z0-9][a-z0-9.-]{0,63}$ (after trim)
                                       -> GEMINI_DEFAULT_MODEL; warn "GEMINI_MODEL is invalid; using gemini-2.5-flash"
    no warn line ever contains the key or the rejected model value
```

The Gemini call made by `generateOutfitSuggestion(prompt)`:

```text
POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent     # no query string
headers: x-goog-api-key: <apiKey>, content-type: application/json
signal: aborts after timeoutMs (default GEMINI_TIMEOUT_MS)
body (exactly these two top-level keys):
{
  "contents": [ { "role": "user", "parts": [ { "text": "<prompt>" } ] } ],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 1024,
    "responseMimeType": "application/json",
    "responseSchema": {
      "type": "OBJECT",
      "properties": {
        "outfits": {
          "type": "ARRAY",
          "items": {
            "type": "OBJECT",
            "properties": {
              "name":    { "type": "STRING" },
              "why":     { "type": "STRING" },
              "itemIds": { "type": "ARRAY", "items": { "type": "STRING" } }
            },
            "required": ["name", "why", "itemIds"]
          }
        }
      },
      "required": ["outfits"]
    },
    "thinkingConfig": { "thinkingBudget": 0 }
  }
}
```

Response handling. The success shape is `{"candidates":[{"content":{"parts":[{"text":"..."}]},"finishReason":"STOP"}], ...}`.
Any outcome other than success throws `LlmProviderError(code)`, which the
handler maps to `502`:

| Outcome | `code` |
|---|---|
| `fetch` rejects | `network` |
| no response within the timeout (the request's `AbortSignal` is aborted) | `timeout` |
| HTTP status not 2xx (400 bad request/model, 403 key, 429 Gemini quota, 5xx) | `http_<status>` |
| body is not JSON | `bad_response` |
| `promptFeedback.blockReason` present (any value) | `blocked` |
| `candidates` missing, not an array, or empty | `no_candidates` |
| `candidates[0].finishReason` is not exactly `"STOP"` (`SAFETY`, `MAX_TOKENS`, `RECITATION`, `BLOCKLIST`, `PROHIBITED_CONTENT`, `SPII`, `OTHER`, missing, ...) | `finish_reason` |
| concatenating, in order, the `text` of `candidates[0].content.parts` entries whose `thought !== true` gives `""` | `empty_text` |
| success | resolves to that concatenated text |

A Gemini `429` is a provider failure (`502`), never the function's own `429`,
which means only "your daily cap".

```text
supabase/functions/_shared/usage-limit.ts
  export type UsageDecision = "allowed" | "limited"
  export const USAGE_DEFAULT_LIMIT = 30
  export const USAGE_RPC_TIMEOUT_MS = 3000
  export async function hashUid(uid: string): Promise<string>     # SHA-256 of UTF-8 uid, 64 lowercase hex
  export function readDailyLimit(): number
    AI_DAILY_LIMIT unset              -> 30, no warn
    "" / whitespace                   -> 30; warn "AI_DAILY_LIMIT is set but empty; using 30"
    trimmed matches ^\d+$             -> that integer (so "0" -> 0, " 7 " -> 7)
    anything else ("abc","-1","2.5","1e3") -> 30; warn "AI_DAILY_LIMIT is invalid; using 30"
  export interface UsageLimiterDeps { fetch?: typeof fetch; supabaseUrl?: string; serviceRoleKey?: string;
                                      limit?: number; now?: () => Date; timeoutMs?: number }
  export async function checkDailyUsage(uid: string, deps?: UsageLimiterDeps): Promise<UsageDecision>
    limit = deps.limit ?? readDailyLimit()
    limit == 0                        -> "limited", no fetch                     # global AI off
    url/key from deps, else SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY; either missing/empty
                                      -> "allowed", no fetch; warn "ai-stylist: usage limiter not configured; allowing request"
    POST {url}/rest/v1/rpc/ai_usage_try_increment
      headers: apikey: <key>, Authorization: Bearer <key>, Content-Type: application/json
      body: {"p_uid_hash": hashUid(uid), "p_day": now() as UTC "YYYY-MM-DD", "p_limit": limit}
    2xx and JSON body === true        -> "allowed"
    2xx and JSON body === false       -> "limited"
    anything else (throw, timeout, non-2xx, non-boolean, non-JSON)
                                      -> "allowed"; console.error("ai-stylist: usage check unavailable; allowing request (<reason>)")
                                         reason in {network, timeout, http_<status>, bad_response}
    never throws; never logs the uid, the hash or the key

supabase/functions/ai-stylist/stylist-contract.ts    (no imports from _shared, no Deno.env, no fetch)
  export type StylistMode = "auto" | "match"
  export interface StylistItem { id, name, category, color, occasion, season: string }
  export interface StylistRequest { occasion, styleDirection, weather: string; includeAccessories: boolean;
                                    mode: StylistMode; lockedIds: string[]; selectedIds: string[]; items: StylistItem[] }
  export interface OutfitSuggestion { name: string; why: string; itemIds: string[] }
  export const MAX_BODY_BYTES = 65536
  export const BAD_REQUEST = { tooLarge: "Request body too large", body: "Invalid request body",
                               mode: "Invalid mode", options: "Invalid styling options",
                               items: "Invalid items", selection: "Invalid selection" } as const
  export function parseStylistRequest(json: unknown): { ok: true; request: StylistRequest } | { ok: false; error: string }
  export function buildPrompt(request: StylistRequest): string
  export function validateOutfits(raw: string, request: StylistRequest): OutfitSuggestion[]

supabase/functions/ai-stylist/index.ts
  export interface HandleRequestDeps {
    verify?: typeof verifyFirebaseToken            // default verifyFirebaseToken (F15)
    getAdapter?: typeof getLlmAdapter              // default getLlmAdapter
    checkUsage?: (uid: string) => Promise<UsageDecision>   // default checkDailyUsage   (F26)
  }
  export async function handleRequest(req: Request, deps?: HandleRequestDeps): Promise<Response>
  if (import.meta.main) Deno.serve((req) => handleRequest(req))
  imports exactly: ../_shared/firebase-auth.ts, ../_shared/llm-adapter.ts, ../_shared/usage-limit.ts, ./stylist-contract.ts
```

**Prompt (`buildPrompt`).** The wording is the builder's choice, with these
binding constraints:
- It contains, verbatim:
  - `Use only item ids from the ITEMS list. Never invent an item.`
  - `Return between 1 and 3 outfits, each with 2 to 6 item ids.`
  - in `match` mode with `lockedIds` non-empty: `Every outfit must include all of these locked item ids: <lockedIds joined by ", ">.`
  - in `match` mode with `includeAccessories` true: `Prefer these selected item ids: <selectedIds joined by ", ">. You may complete outfits with other items from the ITEMS list.`
  - in `match` mode with `includeAccessories` false: `Use only these selected item ids: <selectedIds joined by ", ">. Do not add any other item.`
  - in `auto` mode with `includeAccessories` false: `Do not add items whose category is Accessories.`
- It contains the occasion, style direction and weather.
- It contains an `ITEMS` section listing every item's six fields, for
  example as JSON lines.
- It contains **nothing else** derived from the request or the caller: no
  uid, hash, token, unknown body keys or header values.
- It treats item text as data. It may tell the model to ignore instructions
  inside item fields, but correctness never depends on that, because §5.3
  enforces ownership.

### 6.3 Dart

```text
lib/shared/backend/ai_stylist_client.dart            (imports only ../models/clothing_item.dart)
  enum AiStylistMode { auto, match }                  wire 'auto' / 'match'
  class AiStylistRequest {
    const AiStylistRequest({required mode, required occasion, required styleDirection, required weather,
                            required includeAccessories, required lockedIds, required selectedIds, required items});
    final AiStylistMode mode; final String occasion, styleDirection, weather; final bool includeAccessories;
    final List<String> lockedIds, selectedIds; final List<ClothingItem> items;
    Map<String, Object> toJson();     # exactly the 8 keys of §6.1; each item exactly the 6 keys;
                                      # every string truncated by truncateUtf16(s, 60)
  }
  String truncateUtf16(String s, int max)   # longest prefix of whole code points whose UTF-16 length <= max
  class AiOutfit { const AiOutfit({required name, required why, required itemIds}); ==/hashCode by value }
  abstract interface class AiStylistClient {
    /// 1+ outfits on success; null on ANY failure. Never throws.
    Future<List<AiOutfit>?> suggest(AiStylistRequest request);
  }

lib/shared/backend/http_ai_stylist_client.dart       (imports package:http, package:firebase_auth)
  class HttpAiStylistClient implements AiStylistClient {
    HttpAiStylistClient({http.Client? client, Uri? functionUrl, Future<String?> Function()? getIdToken,
                         Duration? timeout});
    static const defaultTimeout = Duration(seconds: 15);
    static final defaultUrl = Uri.parse('https://dbaeaqyoyilxcuwplvuw.supabase.co/functions/v1/ai-stylist');
  }
  suggest(): token = getIdToken() (default: FirebaseAuth.instance.currentUser?.getIdToken(), any throw -> null)
             null/'' token -> null, NO request sent
             POST functionUrl, headers {Authorization: 'Bearer <token>', Content-Type: 'application/json'},
                  body jsonEncode(request.toJson())
             the whole call (token + POST + body read) is bounded by `timeout` (default 15 s) -> null on expiry
             status != 200 -> null
             body must be {"outfits": [ {name: String, why: String, itemIds: List<String>} , ...]} with >= 1 entry,
                  any deviation (non-JSON, wrong types, empty list) -> null for the whole response
             any exception -> null
  (storage_repository.dart is NOT changed; the URL literal is local to this file)

lib/features/stylist/models/style_result.dart
  enum StyleResultSource { ai, algorithm }
  StyleResult({..., this.source = StyleResultSource.algorithm}); copyWith({..., StyleResultSource? source})

lib/features/stylist/cubit/stylist_state.dart
  bool get resultsByAi        # results.isNotEmpty && every source == ai

lib/features/stylist/cubit/stylist_cubit.dart
  StylistCubit(WardrobeCubit, {int Function()? clock, AnalyticsService? analytics,
                               AiStylistClient? aiClient, bool Function()? aiAvailable})
  bool get aiAvailable        # aiClient != null && (aiAvailable?.call() ?? false); evaluated on every read
  static const aiTimeout = Duration(seconds: 16)
  generationDelay (1150 ms) unchanged; on the AI path it is the minimum wait

lib/features/stylist/widgets/detail_modals.dart
  const DetailFootnote({super.key, this.source = StyleResultSource.algorithm})

lib/app.dart
  StyloBuddyApp({..., AiStylistClient? aiStylistClient})     # test-only seam; production never sets it
```

### 6.4 Request built by `StylistCubit`

| Field | `generateAutomatic()` | `generateMatches()` |
|---|---|---|
| `mode` | `auto` | `match` |
| `occasion`, `styleDirection`, `weather` | `state.*` at call time | same |
| `includeAccessories` | `state.accessories` | same |
| `selectedIds` | `[]` | `state.selected` ∩ wardrobe ids, in `state.selected` order, limited to ids included in `items` |
| `lockedIds` | `[]` | `state.locked` ∩ the `selectedIds` above, in `state.locked` order (same rule as `createMatches`) |
| `items` | the 120-cap selection below | same |

**120-cap selection rule (decided here).**
- Items whose `id` is empty or longer than 60 UTF-16 units are excluded.
- The remaining wardrobe items are ordered by bucket. Within each bucket the
  order is wardrobe order (`WardrobeCubit.state.items`), and no item appears
  twice:
  1. locked ids (match mode);
  2. other selected ids (match mode);
  3. items whose `occasion == state.occasion`;
  4. every other item.
- The first 120 are sent. This rule applies whatever the wardrobe size.
- If a `match` request would contain zero `selectedIds`, or a locked id was
  excluded for length, the AI path is skipped: there is no client call and
  the algorithm path runs.

## 7. Domain model usage

From `docs/foundation/03-domain-model.md`:

- **`ClothingItem`:** reads `id`, `name`, `category`, `color`, `occasion`,
  `season`. It **never** reads or sends `wears`, `sourceId`, `imageUrl` or
  `imageId`.
- **`StylistState`:** reads `occasion`, `styleDirection`, `weather`,
  `accessories`, `selected`, `locked`, `isGenerating`, `results`.
  `styleDirection` and `weather` existed in code since F03 but were missing
  from 03. They were documented there 2026-10-30 (§13 P1).
- **`StyleResult`:** adds `source: StyleResultSource = algorithm`. Added to 03
  on 2026-10-30, before implementation (03 §5).
  - Missing vs empty: `source` is never missing, because the constructor
    default is `algorithm`.
  - The results label treats an **empty** result list as "not AI"
    (simulated wording), never as "AI".
- **`AppConfig.aiStylistEnabled` (F25):** read through
  `AppConfigCubit.state.config.aiStylistEnabled` in `lib/app.dart` only.
  Views never read Remote Config (02 §2).
- **F25 names relied on:**
  - `RemoteConfigKeys.aiStylistEnabled` (`'ai_stylist_enabled'`);
  - `AppConfig.aiStylistEnabled`, `AppConfig.defaults` (`false`);
  - `AppConfigCubit` and `AppConfigState.config`;
  - `RemoteConfigService` and `DefaultsRemoteConfigService` (tests);
  - `AnalyticsService`, `AnalyticsService.noop()`, `outfitGenerated`,
    `OutfitGenerationMode`;
  - `StyloBuddyApp.remoteConfig` and `StyloBuddyApp.analytics`.

  If F25 renames any of them before it closes, this document is amended by a
  dated note. The code follows F25's final names.
- **Not read by any F26 code path:** `ProfileState.gender`, `name`, `email`
  (privacy, D3).

## 8. Data changes

- **Supabase Postgres (new).** The migration file is
  `supabase/migrations/20261030000000_ai_usage.sql`. It is idempotent and
  safe to apply twice. Exact content:

  ```sql
  -- F26: per-user daily AI styling cap. Stores only SHA-256(uid) hex, the UTC day and a count.
  create table if not exists public.ai_usage (
    uid_hash text    not null check (uid_hash ~ '^[0-9a-f]{64}$'),
    day      date    not null,
    count    integer not null default 0 check (count >= 0),
    primary key (uid_hash, day)
  );
  alter table public.ai_usage enable row level security;   -- no policies: only service_role (bypasses RLS)
  revoke all on table public.ai_usage from public, anon, authenticated;

  create or replace function public.ai_usage_try_increment(p_uid_hash text, p_day date, p_limit integer)
  returns boolean
  language plpgsql
  set search_path = public
  as $$
  declare
    new_count integer;
  begin
    if p_limit is null or p_limit < 1 then
      return false;
    end if;
    insert into public.ai_usage as u (uid_hash, day, count)
    values (p_uid_hash, p_day, 1)
    on conflict (uid_hash, day) do update
      set count = u.count + 1
      where u.count < p_limit
    returning u.count into new_count;
    return new_count is not null;
  end;
  $$;
  revoke all on function public.ai_usage_try_increment(text, date, integer) from public, anon, authenticated;
  grant execute on function public.ai_usage_try_increment(text, date, integer) to service_role;
  ```

  - Atomicity comes from the single `INSERT ... ON CONFLICT DO UPDATE ...
    WHERE` statement, which row-locks the conflicting row.
  - A denied call does not increment (the `WHERE` fails, so no row is
    returned).
  - The design's `primary key (uid, day)` is corrected to `(uid_hash, day)`,
    since there is no `uid` column (§13, "design vs code").
  - Rows are never deleted by the app. Pruning old days is §13 Q3.
- **Firestore / `firestore.rules`:** no change. Nothing AI-related is stored
  in Firestore. Saved AI looks are ordinary `Outfit`s (F16) and carry no
  `source`.
- **Supabase secrets (production, Phase B only):**
  - `LLM_PROVIDER=gemini` and `GEMINI_API_KEY`;
  - optionally `GEMINI_MODEL`, and `AI_DAILY_LIMIT` (unset means 30).

  `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected by the
  platform.
- **Remote Config:** `scripts/remoteconfig.template.json` is **not changed**.
  `ai_stylist_enabled` stays `false` (F25 owns the template; D8).
- **Code:**
  - New files: §2.
  - Modified: `llm-adapter.ts`, `ai-stylist/index.ts`, `index.test.ts`,
    `llm-adapter.test.ts` (amended F23 tests), `style_result.dart`,
    `stylist_state.dart`, `stylist_cubit.dart`, `results_view.dart`,
    `stylist_view.dart`, `detail_modals.dart`, `result_detail_view.dart`,
    `lib/app.dart`, and `test/backend/ai_stylist_unwired_test.dart` (amended
    F23-A18).
  - No new Dart dependency: `http` is already used by `StorageRepository`.
    No new Deno runtime dependency.
  - SQL tests use `npm:postgres@3`, test-only.
- **After F25 closes:** `AppConfig.aiStylistEnabled`'s dartdoc ("Reserved for
  the LLM-provider feature; nothing reads it yet.") is updated to name F26.
  F26 does not edit F25's files while F25 is open.

## 9. Background work and events

- **No jobs, schedules or triggers.**
- **Writes:** one `ai_usage` upsert per non-400, non-401, non-501 request
  that reaches step 5. Retries by the client count again; the client never
  retries automatically.
- **Analytics:** `outfit_generated` is unchanged (F25-A36) and logged once
  per emitted result set on both paths.
- **Function log lines (exhaustive):**
  - the `getLlmAdapter`/`geminiAdapterFromEnv` warnings (§6.2);
  - `readDailyLimit` warnings;
  - the limiter's `not configured` warning and its `usage check unavailable`
    error;
  - `provider call failed (<code>)`;
  - `provider output had no valid outfits`;
  - `unexpected error (<name>)`.

  A successful request logs nothing.

## 10. Degradation and failure

| Situation | Server outcome | App outcome |
|---|---|---|
| Guest | — (never called) | algorithm path, simulated labels (A60, A73) |
| Flag `ai_stylist_enabled` false (default, kill switch) | — | algorithm path, hub line simulated (A60, A66) |
| Flag fetched after the generate tap (F25 load still running) | — | that generation uses the flag value at call time; the next one follows the new value (A72) |
| Empty wardrobe | — | algorithm path (F03-A03's 3 empty looks), no client call (A60) |
| Match with zero owned selected ids | — | algorithm path (`createMatches` → 0 looks), no client call (A60) |
| No Firebase token / `getIdToken` throws or hangs | — | client returns `null` within 15 s, no request sent when the token is null → fallback (A53) |
| Offline / DNS / TLS failure | — | `null` → fallback (A53, A86) |
| `LLM_PROVIDER` unset / empty / unregistered | 501 + F23 warning | `null` → fallback |
| `LLM_PROVIDER=gemini`, `GEMINI_API_KEY` missing vs empty | 501 for both; warnings differ (`is not set` vs `is set but empty`) | fallback |
| `GEMINI_MODEL` missing vs empty vs invalid | default model; no warn vs `is set but empty` warn vs `is invalid` warn | — |
| `AI_DAILY_LIMIT` missing vs empty vs `0` vs invalid | 30 silently vs 30 + warn vs **every call 429, no DB call** vs 30 + warn | fallback on 429 |
| Cap reached | 429, no provider call | fallback (A58) |
| `ai_usage` RPC unreachable / errors / odd body; limiter not configured | **fail open**: request proceeds; one `console.error`/`console.warn` without uid or hash | normal |
| Body > 64 KB / malformed / invalid fields | 400 with a fixed message; no quota used | fallback |
| Gemini HTTP error (incl. its own 429), timeout 12 s, safety block, bad finish reason, empty text | 502 | fallback |
| Gemini returns invented ids / too few / duplicates / missing locked id | the outfit is dropped; 502 if none survive | fallback |
| AI call slower than 1.15 s | — | `/generating` stays until the answer or the 15 s client timeout (16 s Cubit ceiling) |
| AI call faster than 1.15 s | — | the screen still waits 1.15 s (no flash, A57) |
| A returned id deleted from the wardrobe before render | — | `itemOrFallback` (G-A01), no crash |
| Cubit closed mid-call (sign-out, uid flip) | — | result discarded; no emit, no analytics (A64) |
| Supabase project auto-paused (free tier, F23 note) | gateway error | client `null` → fallback |

## 11. Validation assertions

Gates:

- `[U]` covers:
  - Deno tests with every collaborator injected (`verify`, `getAdapter`,
    `checkUsage`, `fetch`, `now`) and no network;
  - Dart unit/widget tests with `FakeAiStylistClient` or `MockClient`
    (`package:http/testing.dart`);
  - static checks.
- `[I]` covers:
  - Deno: the handler wired to the real `verifyFirebaseToken` (local JWKS),
    the real `getLlmAdapter`/`geminiAdapterFromEnv`/`checkDailyUsage` driven
    by real `Deno.env`, with `globalThis.fetch` replaced by a recording
    router for the test's duration (restored in `finally`), so there is no
    real network;
  - SQL tests against a local Supabase Postgres (`supabase start`; roles
    `anon`/`authenticated`/`service_role` present);
  - the real `StyloBuddyApp` harness (`uidStream`, `firestoreOverride`, a
    fake `RemoteConfigService`, `aiStylistClient: FakeAiStylistClient`).
- `[L]` covers the deployed function on `dbaeaqyoyilxcuwplvuw` and a device
  build. **Phase A** (A77-A79) needs only the user's deploy go-ahead.
  **Phase B** (A80-A87) is **PENDING THE USER'S GEMINI API KEY** and cannot
  run before it.

Deno test names start `F26_Axx`. Dart test names start `F26_Axx`. Tests that
change environment variables restore them in `finally`. "Markers" are unique
strings planted in an input and searched for in outputs.

```
F26-A01  [U]  handleRequest with verify -> null and a valid JSON body returns 401, body exactly "Unauthorized", content-type text/plain; getAdapter, checkUsage and the adapter's generateOutfitSuggestion are each called 0 times; req.bodyUsed is false (F23 behaviour unchanged)
F26-A02  [U]  handleRequest with verify -> "uid-1" and getAdapter -> null returns 501 application/json deep-equal {"error":"AI provider not configured yet"} for each of: POST with no body, POST "{{not json", POST with a fully valid §6.1 body, GET; req.bodyUsed is false after each; checkUsage is called 0 times
F26-A03  [U]  Happy path call order and arguments: verify(req) once with the same Request object, then getAdapter() once, then checkUsage once with exactly the string verify resolved, then generateOutfitSuggestion once with a string argument; recorded order is exactly [verify, getAdapter, checkUsage, generate]
F26-A04  [U]  200: a valid auto request with 5 items (ids a,b,c,d,e) and an adapter returning '{"outfits":[{"name":"City Day","why":"Crisp and easy.","itemIds":["a","b","c"]},{"name":"Soft Weekend","why":"Relaxed layers.","itemIds":["d","e"]}]}' -> status 200, content-type application/json, body deep-equal {"outfits":[{"name":"City Day","why":"Crisp and easy.","itemIds":["a","b","c"]},{"name":"Soft Weekend","why":"Relaxed layers.","itemIds":["d","e"]}]}; top-level keys exactly {outfits}; each outfit's keys exactly {name, why, itemIds}
F26-A05  [U]  Size limit: a request with Content-Length 65537 returns 400 {"error":"Request body too large"} with req.bodyUsed false; a 70 000-byte streamed body with no Content-Length returns the same 400; a valid request padded with trailing spaces to exactly 65 536 bytes returns 200 (with an adapter returning A04's text); checkUsage and generate are not called on either 400
F26-A06  [U]  400 {"error":"Invalid request body"} for each body: "" (POST with no body), GET with no body, "{{not json", "[]", "null", "42", "\"text\"", and bytes that are not valid UTF-8 (0xff 0xfe)
F26-A07  [U]  400 {"error":"Invalid mode"} for an otherwise valid body whose mode is missing, "", "AUTO", "chat", 1, null; mode "auto" and "match" (with a valid selection) are accepted
F26-A08  [U]  400 {"error":"Invalid styling options"} when, in an otherwise valid body, occasion/styleDirection/weather (each separately) is missing, "", "   ", 61 characters, 7 or null; or includeAccessories is missing, "true", 1 or null. Accepted: each styling string exactly 60 characters; includeAccessories false (missing and false behave differently: 400 vs accepted)
F26-A09  [U]  400 {"error":"Invalid items"} when items is missing, not an array, [], 121 valid entries, contains a non-object, an entry missing any one of the 6 keys (each tested), an entry with a non-string field, id "" or "  " or " a" (untrimmed), any field of 61 characters, or two entries with the same id. Accepted: exactly 120 entries; every field exactly 60 characters; name/category/color/occasion/season each "" (present-but-empty accepted, missing rejected)
F26-A10  [U]  400 {"error":"Invalid selection"} when lockedIds or selectedIds is missing (each separately; [] is accepted), not an array, contains a non-string, contains an id not in items, or contains a duplicate; in auto mode when either is non-empty; in match mode when selectedIds is [], when a lockedId is not in selectedIds, or when lockedIds has 7 entries. Accepted: match with selectedIds [a,b] and lockedIds [a]; match with lockedIds []
F26-A11  [U]  Every 400 body is exactly {"error": m} with m one of the six §6.1 messages; validation order is §6.1's (a body that is oversized AND non-JSON gets "Request body too large"; mode invalid AND items [] gets "Invalid mode"; options invalid AND selection invalid gets "Invalid styling options"); with the marker "echo-marker-3b1" placed in every string field of each invalid case, no 400 body contains it
F26-A12  [U]  No 400 response (all cases of A05-A10) calls checkUsage or generateOutfitSuggestion (invalid requests never consume quota or reach the provider)
F26-A13  [U]  checkUsage -> "limited" returns 429 application/json deep-equal {"error":"Daily AI styling limit reached"} and generateOutfitSuggestion is called 0 times
F26-A14  [U]  generateOutfitSuggestion rejecting with new LlmProviderError("http_429"), with new Error("provider-text-marker-77"), and throwing synchronously each return 502 application/json deep-equal {"error":"AI styling failed"}; no body contains "provider-text-marker-77" or "http_429"
F26-A15  [U]  502 {"error":"AI styling failed"} when the adapter resolves each of: "", "not json", "[]", "{}", '{"outfits":"x"}', '{"outfits":[]}', '{"outfits":[{"name":"A","why":"B","itemIds":["ghost-1","ghost-2"]}]}' (ids not sent), '{"outfits":[{"name":"A","why":"B","itemIds":["a"]}]}' (one valid id)
F26-A16  [U]  handleRequest never throws and never resolves undefined across every case of A01-A15; with checkUsage throwing, the request proceeds as "allowed" (200 with A04's adapter) and one console.error line is captured; an adapter resolving a non-string value (42, null, and an object whose toString throws) yields 502 {"error":"AI styling failed"} and handleRequest does not reject
F26-A17  [U]  Response privacy: with verify resolving "uid-marker-7f3a", Authorization "Bearer tok-marker-91c2", GEMINI_API_KEY "AIza-key-marker-5c" (A41 wiring) and items whose name is "item-name-marker-2d", none of the 200, 400, 401, 429, 501 and 502 response bodies contains the uid marker, its SHA-256 hex, the token marker or the key marker; the 200 body contains no item name (only ids, the model's name and the model's why)
F26-A18  [U]  Log privacy: console.log/info/warn/error/debug are captured across every path of A01-A17 and A41-A44 (including fail-open and provider failures); no captured line contains the uid marker, its SHA-256 hex, the token marker, the key marker, the item-name marker, the occasion value "occasion-marker-4e", the provider-text marker, or the prompt text; the only lines emitted are those listed in §9
F26-A19  [U]  validateOutfits drops unknown ids per id: request ids [a,b,c]; output itemIds [a,"ghost",b,"A",1,null,{}] keeps [a,b] (case-sensitive, non-strings removed)
F26-A20  [U]  validateOutfits dedupes within an outfit keeping first-occurrence order: [a,b,a,c,b] -> [a,b,c]
F26-A21  [U]  Size bounds after filtering: 1 surviving id -> outfit dropped; 2 -> kept; 6 -> kept; 7 distinct valid ids -> dropped (not truncated)
F26-A22  [U]  Match mode, includeAccessories true, selectedIds [a,b], lockedIds [a]: an outfit without a is dropped, [a,c] (c unselected) is kept; lockedIds [a,b]: [a,c] dropped, [a,b,c] kept; match mode with includeAccessories false and selectedIds [a,b], lockedIds [a]: [a,b] kept, [a,c] dropped (only selected items, F04-A14); the same outfits in auto mode (lockedIds [], selectedIds []) are all kept
F26-A23  [U]  Normalisation: name "  City\n\tDay  " -> "City Day"; a 45-character name -> its first 40 characters; a why of 200 characters -> 160; a name of 41 "👗" -> exactly 40 "👗" (no split surrogate); name or why missing, non-string, "" or "   " -> outfit dropped
F26-A24  [U]  At most 3 outfits, model order preserved: 5 valid distinct outfits -> the first 3, in order
F26-A25  [U]  Identical sets: outfits [a,b], [b,a], [c,d], [e,f] -> [a,b], [c,d], [e,f] (the duplicate set is dropped and does not count toward 3)
F26-A26  [U]  Malformed shapes: a non-object element, an element whose itemIds is a string, and extra keys ("score": 98, "extra": "x") on a kept outfit -> the malformed elements are dropped and the kept outfit has exactly the keys {name, why, itemIds}
F26-A27  [U]  buildPrompt always contains verbatim "Use only item ids from the ITEMS list. Never invent an item." and "Return between 1 and 3 outfits, each with 2 to 6 item ids."; match mode, selectedIds [white-shirt, black-watch, navy-chinos], lockedIds [white-shirt, black-watch]: contains "Every outfit must include all of these locked item ids: white-shirt, black-watch." and, with includeAccessories true, "Prefer these selected item ids: white-shirt, black-watch, navy-chinos. You may complete outfits with other items from the ITEMS list.", with false, "Use only these selected item ids: white-shirt, black-watch, navy-chinos. Do not add any other item."; match mode with lockedIds [] has no "locked item ids" sentence; auto mode has no "locked item ids" and no "selected item ids" sentence, and contains "Do not add items whose category is Accessories." exactly when includeAccessories is false; every prompt contains the occasion, styleDirection, weather and every item's six field values
F26-A28  [U]  Prompt privacy: a body with extra top-level keys {uid, email, displayName, gender, token} and extra per-item keys {imageUrl, sourceId, wears, photo}, each holding a distinct marker, yields a prompt (captured as the adapter's argument through handleRequest) that contains none of those markers, nor the verified uid marker, its SHA-256 hex, or the bearer token marker
F26-A29  [U]  createGeminiAdapter({apiKey: "k-marker", fetch: recorder}).generateOutfitSuggestion("P") makes exactly one fetch: URL exactly "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent" (no "?" and no "k-marker" in it); method POST; header x-goog-api-key "k-marker"; header content-type "application/json"; a non-null AbortSignal; body JSON deep-equal to §6.2's body with text "P" (top-level keys exactly {contents, generationConfig}; temperature 0.7; maxOutputTokens 1024; responseMimeType "application/json"; responseSchema exactly §6.2's; thinkingConfig {thinkingBudget: 0}); GEMINI_TIMEOUT_MS === 12000 and GEMINI_DEFAULT_MODEL === "gemini-2.5-flash"
F26-A30  [U]  geminiAdapterFromEnv model selection: GEMINI_MODEL unset -> URL uses gemini-2.5-flash and no warn; "gemini-2.5-flash-lite" -> URL uses it; "" and "   " -> default plus warn "GEMINI_MODEL is set but empty; using gemini-2.5-flash"; "../x", "a b", "models/x?key=1", "Gemini-Flash" and a 65-character name -> default plus warn "GEMINI_MODEL is invalid; using gemini-2.5-flash"; no warn line contains the rejected value (verified through a fetch recorder on globalThis.fetch restored in finally)
F26-A31  [U]  Success extraction: candidates[0] {content: {parts: [{text: '{"outfits":'}, {text: "[]}"}]}, finishReason: "STOP"} resolves to '{"outfits":[]}'; a part with thought: true is excluded from the concatenation
F26-A32  [U]  Failure mapping (each rejects with LlmProviderError whose code is): fetch rejects -> "network"; fetch never resolves with timeoutMs 50 -> "timeout" and the recorded AbortSignal is aborted; status 400, 403, 429, 500, 503 -> "http_400" ... "http_503"; 200 with body "<html>" -> "bad_response"; promptFeedback {blockReason: "SAFETY"} -> "blocked"; candidates missing and [] -> "no_candidates"; finishReason "SAFETY", "MAX_TOKENS", "RECITATION", "OTHER" and missing -> "finish_reason"; STOP with no parts, with only {text: ""} and with only thought parts -> "empty_text"; for a response body containing "resp-marker-19" no error's message or code contains it, and no error contains the key
F26-A33  [U]  getLlmAdapter registration: LLM_PROVIDER "gemini" and " gemini " with GEMINI_API_KEY "k" return a non-null adapter and emit no warn; "Gemini" and "GEMINI" return null with the F23 unregistered warning; "gemini" with GEMINI_API_KEY deleted returns null with exactly one warn containing "GEMINI_API_KEY is not set"; with "" and "   " returns null with exactly one warn containing "GEMINI_API_KEY is set but empty"; those two messages differ from each other and from F23's three; no warn line in any case contains the key value (key "k-marker-0a" in the non-null case); F23-A10/A11/A12 cases still pass unchanged
F26-A34  [U]  Static boundaries: llm-adapter.ts satisfies amended F23-A14 (sole import "./gemini-adapter.ts"); gemini-adapter.ts has exactly one import, `import type { LlmAdapter } from "./llm-adapter.ts"`, no npm:/jsr: specifier, its only Deno.env access is Deno.env.get("GEMINI_API_KEY") and Deno.env.get("GEMINI_MODEL"), and contains no "?key=" or "key=" substring; usage-limit.ts has no import and is the only file among index.ts, stylist-contract.ts, llm-adapter.ts, gemini-adapter.ts, usage-limit.ts that contains "SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY" or "AI_DAILY_LIMIT"; stylist-contract.ts has no import, no Deno.env and no fetch(; index.ts satisfies amended F23-A15; no file in that set contains "supabase-js" or "Deno.env.toObject"
F26-A35  [U]  hashUid("abc") === "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"; hashUid of any uid matches ^[0-9a-f]{64}$; hashUid("uid-1") !== hashUid("uid-2")
F26-A36  [U]  checkDailyUsage("uid-marker-7f3a", {fetch: recorder, supabaseUrl: "https://db.test", serviceRoleKey: "srk-marker", limit: 30, now: () => new Date("2026-10-30T23:59:59Z")}) makes one POST to exactly "https://db.test/rest/v1/rpc/ai_usage_try_increment" with headers apikey "srk-marker", Authorization "Bearer srk-marker", Content-Type "application/json" and body deep-equal {"p_uid_hash": hashUid("uid-marker-7f3a"), "p_day": "2026-10-30", "p_limit": 30}; with now 2026-10-30T23:30:00-05:00 p_day is "2026-10-31" (UTC); neither URL nor body contains "uid-marker-7f3a"
F26-A37  [U]  Decision mapping: 200 body true -> "allowed"; 200 body false -> "limited"; fail-open to "allowed", each with exactly one console.error line starting "ai-stylist: usage check unavailable; allowing request", for: fetch rejects (reason network), fetch never resolves with timeoutMs 50 (timeout; default USAGE_RPC_TIMEOUT_MS === 3000), statuses 401/404/500 (http_<status>), 200 bodies "null", "\"true\"", "{}", "1", "not json" (bad_response); checkDailyUsage never throws; no line contains the uid, its hash or "srk-marker"
F26-A38  [U]  readDailyLimit: AI_DAILY_LIMIT deleted -> 30, no warn; "" and "  " -> 30 with warn "AI_DAILY_LIMIT is set but empty; using 30"; "abc", "-1", "2.5", "1e3" -> 30 with warn "AI_DAILY_LIMIT is invalid; using 30"; "5" -> 5; " 7 " -> 7; "0" -> 0; checkDailyUsage with limit 0 returns "limited" and makes zero fetch calls (zero means AI off for everyone, distinct from missing = 30)
F26-A39  [U]  checkDailyUsage with SUPABASE_URL deleted, and separately SUPABASE_SERVICE_ROLE_KEY set to "", (no deps overrides) returns "allowed", makes zero fetch calls, and emits exactly one warn "ai-stylist: usage limiter not configured; allowing request"
F26-A40  [U]  Deno hygiene: `deno test --allow-env --allow-read supabase/functions/ai-stylist/ supabase/functions/_shared/llm-adapter.test.ts supabase/functions/_shared/gemini-adapter.test.ts supabase/functions/_shared/usage-limit.test.ts` passes without --allow-net (cache warmed first, F23 §12); no test file under supabase/functions contains "sanitizeOps" or "sanitizeResources"; `deno lint supabase/functions` and `deno check supabase/functions/ai-stylist/index.ts` report no problems; every F15 test and every (amended) F23 test passes in the same run
F26-A41  [I]  Real modules: env LLM_PROVIDER=gemini, GEMINI_API_KEY="AIza-key-marker-5c", SUPABASE_URL="https://db.test", SUPABASE_SERVICE_ROLE_KEY="srk-marker", AI_DAILY_LIMIT and GEMINI_MODEL deleted; globalThis.fetch replaced by a router answering the RPC with true and Gemini with a valid candidate; handleRequest wired to real verifyFirebaseToken (local JWKS, valid test token) and default getAdapter/checkUsage returns 200 with validated outfits; the router recorded exactly 2 calls in order [RPC, Gemini], the RPC body's p_limit is 30 and the Gemini call carries x-goog-api-key "AIza-key-marker-5c"
F26-A42  [I]  Same wiring: RPC answering false -> 429 and the router recorded no Gemini call; RPC answering 500 -> one console.error (fail-open), Gemini called, 200; Gemini answering 503 -> 502 {"error":"AI styling failed"}; AI_DAILY_LIMIT "0" -> 429 with zero recorded calls
F26-A43  [I]  Same wiring with LLM_PROVIDER=gemini and GEMINI_API_KEY deleted -> 501 {"error":"AI provider not configured yet"}, zero recorded fetch calls, one warn containing "GEMINI_API_KEY is not set"; with GEMINI_API_KEY "" -> the same 501, zero calls, one warn containing "GEMINI_API_KEY is set but empty"; req.bodyUsed false in both
F26-A44  [I]  Same wiring, each bad-token shape of F23-A04 -> 401 "Unauthorized" and zero recorded fetch calls (no RPC, no Gemini)
F26-A45  [I]  Local Postgres: applying the migration file twice in a row succeeds; afterwards public.ai_usage has exactly the columns uid_hash text not null, day date not null, count integer not null default 0, primary key (uid_hash, day); pg_class.relrowsecurity is true for it; pg_policies has 0 rows for it; inserting uid_hash 'XYZ' (not 64 lowercase hex) fails the check constraint
F26-A46  [I]  As service_role, ai_usage_try_increment(h, '2026-10-30', 3) returns true, true, true, then false, false; the row's count is 3 (denied calls do not increment); the same h with '2026-10-31' returns true with a new row of count 1; a different hash on '2026-10-30' returns true independently
F26-A47  [I]  20 concurrent calls on separate connections for one new (hash, day) with p_limit 5 return exactly 5 true and 15 false, and the final count is 5
F26-A48  [I]  ai_usage_try_increment(h, day, 0), (h, day, -1) and (h, day, null) return false and create or change no row; one call with p_limit 1 returns true, the second false
F26-A49  [I]  Privileges: as role anon and as role authenticated, select from public.ai_usage, insert into it and select ai_usage_try_increment(...) each fail with permission denied (SQLSTATE 42501) and leave the table unchanged; as service_role all three succeed
F26-A50  [U]  StyleResultSource.values == [ai, algorithm]; StyleResult(id: 1, name: 'n', items: [], occasion: 'o', why: 'w').source == algorithm; copyWith() keeps source; copyWith(source: StyleResultSource.ai) changes source only; every pre-existing StyleResult constructor call compiles unchanged
F26-A51  [U]  AiStylistRequest.toJson(): keys exactly {occasion, styleDirection, weather, includeAccessories, mode, lockedIds, selectedIds, items}; mode wire values 'auto'/'match'; each item's keys exactly {id, name, category, color, occasion, season}; a ClothingItem with wears 4, sourceId 'src-marker' and imageUrl 'url-marker' produces JSON containing neither marker nor 'wears'; an 80-character name is sent as its first 60 characters; a name of 31 '👗' (62 UTF-16 units) is sent as 30 '👗'; truncateUtf16('abc', 60) == 'abc'
F26-A52  [U]  HttpAiStylistClient(client: MockClient, getIdToken: () async => 'tok').suggest(req) sends exactly one POST to https://dbaeaqyoyilxcuwplvuw.supabase.co/functions/v1/ai-stylist with headers Authorization 'Bearer tok' and Content-Type 'application/json' (charset suffix allowed) and body == jsonEncode(req.toJson()); a 200 response {"outfits":[{"name":"A","why":"B","itemIds":["x","y"]}]} returns [AiOutfit(name: 'A', why: 'B', itemIds: ['x','y'])]
F26-A53  [U]  HttpAiStylistClient.suggest returns null and never throws for: token null and token '' (MockClient receives 0 requests in both); getIdToken throwing; getIdToken never completing (timeout 50 ms -> null by 60 ms of fake time); statuses 400, 401, 429, 500, 501, 502; 200 bodies 'not json', '{}', '{"outfits":[]}', '{"outfits":"x"}', an outfit missing name, an outfit whose itemIds contains 1; MockClient throwing SocketException; MockClient never responding (timeout 50 ms)
F26-A54  [U]  HttpAiStylistClient.defaultTimeout == Duration(seconds: 15); StylistCubit.aiTimeout == Duration(seconds: 16); StylistCubit.generationDelay == Duration(milliseconds: 1150) (unchanged); constructing HttpAiStylistClient() with no arguments in a test without Firebase initialised does not throw
F26-A55  [U]  StylistCubit.aiAvailable is false with no aiClient (with or without a predicate returning true), false with a client and no predicate, false with a client and a predicate returning false, true with a client and a predicate returning true; flipping the predicate's backing value flips the getter on the next read without any new state emission
F26-A56  [U]  AI success, auto: seed wardrobe, occasion 'Office', a fake returning 2 outfits of seed ids -> isGenerating true synchronously after generateAutomatic(); after completion results.length == 2 with the fake's names, why and itemIds, every source ai, every occasion 'Office', ids clock()+0 and clock()+1, isMatchMode false; the fake received exactly one request with mode auto, lockedIds [], selectedIds [], occasion 'Office', styleDirection 'Smart casual', weather 'Mild / all season', includeAccessories true; a recording analytics sink logged exactly one outfit_generated {'mode':'automatic','result_count':2}
F26-A57  [U]  Minimum wait (fake async): a fake answering after 10 ms -> at 1100 ms isGenerating is true and results unchanged, at 1150 ms results are the AI results; a fake answering after 3000 ms -> at 2900 ms still generating, at 3000 ms AI results emitted
F26-A58  [U]  Fallback triggers: the fake returning null, returning [], throwing StateError, never completing (fallback emitted at StylistCubit.aiTimeout = 16 s of fake time, not before), and returning only outfits whose ids are outside the sent items -> in each case results deep-equal (by name, items, why, occasion) what a StylistCubit with no client produces for the same state (F03-A01's three looks for the seed wardrobe), every source algorithm, exactly one outfit_generated event, and StylistState has no error field
F26-A59  [U]  Client-side recheck: a fake outfit [white-shirt, ghost, navy-chinos] becomes items [white-shirt, navy-chinos]; an outfit left with 1 id is dropped; in match mode an outfit lacking a locked id is dropped; in match mode with accessories false an outfit containing an unselected owned id is dropped; when at least one outfit survives, the results are those survivors with source ai; when none survive, the algorithm results are used
F26-A60  [U]  Zero client calls and algorithm results (F03 outputs, source algorithm, simulated labels) when: predicate false; no client (guest); wardrobe emptied (results are F03-A03's three empty looks); match mode with no owned selected id; match mode with a locked id whose length is 61 characters; in every case FakeAiStylistClient.requests is empty
F26-A61  [U]  Match request: selected [white-shirt, navy-chinos, ghost-item], locked [white-shirt, black-skirt], accessories false -> the request has mode match, selectedIds [white-shirt, navy-chinos], lockedIds [white-shirt], includeAccessories false; AI results have isMatchMode true and keep the fake's names (not 'Best Match' ...); swapItem on white-shirt in those results returns 'Mandatory items cannot be swapped' and changes nothing (F03-A17 holds on AI results)
F26-A62  [U]  Swap flips source: on AI results, swapItem(navy-chinos -> beige-chinos) on the active result sets its source to algorithm, replaces the item in place, sets why to F03-A16's preview text and keeps the name; every other result keeps source ai; state.resultsByAi becomes false
F26-A63  [U]  120-cap rule: a wardrobe of 150 synthetic items item-000..item-149 (occasion 'Office' for even numbers, 'Everyday' for odd), state.occasion 'Office', match selected [item-149, item-148, item-001] locked [item-149] -> request.items ids are exactly [item-149, item-001, item-148] (locked first, then the other selected in wardrobe order), then item-000, item-002, ..., item-146 (the 'Office' items in wardrobe order, excluding item-148, 74 items), then item-003, item-005, ... until 120 entries; an auto request on a 120-item wardrobe sends all 120 ids; an item whose id has 61 characters is never sent
F26-A64  [U]  A second generateAutomatic() while an AI generation is in flight makes no second client call and does not restart the wait; closing the cubit while the fake is pending leads to no emitted state after close, no analytics event, and no uncaught error when the fake later completes
F26-A65  [U]  ResultsView label: results all source ai -> 'Styled by AI from the pieces in your wardrobe.' found once and the simulated text not found; all algorithm -> 'Styling examples are simulated. No real AI evaluation or percentage scores are claimed.' found once and the AI text not found; two ai and one algorithm (after a swap) -> simulated text; empty results -> simulated text; the same four cases with ResultsView(match: true)
F26-A66  [U]  StylistView hub line: with aiAvailable true -> 'Recommendations are generated by AI from the pieces in your wardrobe.' found once and 'Interactive concept • recommendations are simulated, not generated by a live fashion model.' not found; with aiAvailable false (and with no client) -> the reverse
F26-A67  [U]  Result detail footnote: active result source ai -> 'Styled by AI from the pieces in your wardrobe.' found once and 'Outfit selections and styling explanations are simulated for design review.' not found; source algorithm -> the reverse; after a swap on the detail screen the footnote shows the simulated text; ResultDetailView(match: true) follows the same rule
F26-A68  [U]  No AI error UI: driving /styling-options -> 'Generate 3 looks ✧' with each A58 failing fake ends on /results with F03-A23's copy and the three algorithm looks; at no pumped frame between the tap and /results does any Text contain (case-insensitive) 'AI styling failed', 'limit', 'unavailable', 'error' or 'try again', and no AppToast or dialog is shown
F26-A69  [U]  Structural: lib/features/stylist/cubit/stylist_cubit.dart imports lib/shared/backend/ai_stylist_client.dart and does not import package:http, package:firebase_auth or http_ai_stylist_client.dart; http_ai_stylist_client.dart is imported only by lib/app.dart; ai_stylist_client.dart imports nothing outside lib/shared/models; no file under lib/features/*/view, */widgets or lib/shared/widgets imports either client file or package:http; the amended F23_A18 test passes
F26-A70  [U]  Existing behaviour with no client: test/features/stylist/stylist_cubit_test.dart, test/features/stylist/stylist_screens_test.dart and the F04 and F05 test files pass with their content byte-identical to the pre-F26 commit; F25-A36's StylistCubit analytics test passes unchanged
F26-A71  [I]  Real StyloBuddyApp, uidStream 'uid-1', FakeFirebaseFirestore (bootstrap-seeded wardrobe awaited by bounded polling), remoteConfig returning aiStylistEnabled true from initialize(), aiStylistClient FakeAiStylistClient returning 3 outfits of seed ids named 'AI One', 'AI Two', 'AI Three': /stylist shows the AI hub line; Style me for today -> Next -> Generate 3 looks ✧ goes through /generating to /results showing 'AI One'..'AI Three' and the AI results label; opening look 1 shows the AI footnote; '♡ Save Outfit' saves an Outfit named 'AI One' with the fake's items and why; going back and swapping a piece on look 2's detail shows the simulated footnote
F26-A72  [I]  Same harness: a fake returning null -> /results shows F03-A01's three template looks with the simulated label and no error UI; with remoteConfig initialize() -> defaults and refresh() -> aiStylistEnabled true delayed by a Completer, a generate before the Completer completes makes 0 client calls and a generate after it makes 1
F26-A73  [I]  Real StyloBuddyApp as guest (uid null) with aiStylistClient FakeAiStylistClient and remoteConfig flag true: Home 'View outfits →', the stylist generate flow and a Match My Clothes generate together make 0 client calls; StylistCubit.aiAvailable is false; every label is the simulated wording; with uid 'uid-1' and DefaultsRemoteConfigService (flag false) the same flows also make 0 client calls
F26-A74  [I]  Signed-in harness, flag true, fake returning outfits that all contain white-shirt: Match My Clothes via the UI (select White Oxford Shirt and Navy Chinos, lock the shirt, '✧ Find my best matches') sends a request with mode match and lockedIds [white-shirt]; /matching-results shows the fake's names and the AI label; the matching detail shows 'White Oxford Shirt · Locked' and the AI footnote
F26-A75  [I]  Regression: the full `flutter test` suite passes and `flutter analyze` reports no issues; the only pre-existing Dart test file whose content changed is test/backend/ai_stylist_unwired_test.dart (amended F23-A18); the only pre-existing Deno tests whose assertions changed are F23_A09, F23_A14, F23_A15 (amended)
F26-A76  [U]  Docs: 03-domain-model.md lists StyleResult.source and StylistState.styleDirection/weather with a 2026-10-30 note; 07-security.md §4 names GEMINI_API_KEY, GEMINI_MODEL, AI_DAILY_LIMIT, the ai_usage table and the Gemini disclosure requirement with a 2026-10-30 note; 01-tech-stack.md carries a 2026-10-30 F26 note; F23-A07/A09/A11/A12/A14/A15/A18/A19/A24 and F03-A05/A16/A19/A22/A24/A25 and F04-A14/A15 each carry a dated 2026-10-30 note with the original wording quoted where the statement changed; no assertion was deleted or renumbered; scripts/remoteconfig.template.json's ai_stylist_enabled default is still "false"
F26-A77  [L]  Phase A (deploy go-ahead only): the migration is applied to dbaeaqyoyilxcuwplvuw through the Management API (access token from ~/.secrets, never printed or committed); a follow-up SQL query shows ai_usage present, relrowsecurity true and 0 policies; a PostgREST POST /rest/v1/rpc/ai_usage_try_increment with the public anon key returns a non-2xx status and creates no row; GET /rest/v1/ai_usage with the anon key returns a non-2xx status or []
F26-A78  [L]  Phase A: after F26-A01..A76 pass locally and a recorded go-ahead, `supabase functions deploy ai-stylist --project-ref dbaeaqyoyilxcuwplvuw` exits 0; storage-upload-url's version is unchanged; with LLM_PROVIDER unset, POST without Authorization and with "Bearer garbage" return 401 body exactly "Unauthorized" (not a gateway JSON code); a real freshly minted Firebase ID token for a temporary test user with a valid §6.1 body returns 501 deep-equal {"error":"AI provider not configured yet"}; the test user is deleted afterwards
F26-A79  [L]  Phase A: with LLM_PROVIDER=gemini set and no GEMINI_API_KEY secret, the same real-token request returns 501 with the same body, and the function logs for that request show "GEMINI_API_KEY is not set" and no secret value
F26-A80  [L]  PENDING GEMINI KEY: GET https://generativelanguage.googleapis.com/v1beta/models/<model> (model = GEMINI_MODEL or gemini-2.5-flash) with header x-goog-api-key returns 200 and supportedGenerationMethods contains "generateContent"; if not, GEMINI_MODEL is set to a served Flash model and the probe passes before A81; the key is set only via `supabase secrets set` and never printed, logged or committed
F26-A81  [L]  PENDING GEMINI KEY: with LLM_PROVIDER=gemini and the key set, three auto-mode requests with a real token and the JSON of AiStylistRequest built from SeedData's 23 items each return 200 within 15 s with 1-3 outfits where every itemId is one of the 23 sent ids, each outfit has 2-6 distinct ids, no two outfits have the same id set, name length <= 40 and why length <= 160; observed latencies are recorded
F26-A82  [L]  PENDING GEMINI KEY: three match-mode requests with selectedIds [white-shirt, navy-chinos, blue-jeans] and lockedIds [white-shirt] return 200 (or 502 if no outfit survived validation, recorded) with every returned outfit containing white-shirt; at least 2 of the 3 are 200
F26-A83  [L]  PENDING GEMINI KEY: the live function returns 400 {"error":"Invalid request body"} for body "{" and 400 {"error":"Invalid items"} for a valid body with items []; neither consumes quota (ai_usage count for the test user's hash unchanged)
F26-A84  [L]  PENDING GEMINI KEY: with AI_DAILY_LIMIT temporarily set to 2, a fresh test user's 3rd request of the day returns 429 deep-equal {"error":"Daily AI styling limit reached"}; ai_usage holds one row for SHA-256(uid) with count 2 and no row containing the raw uid; afterwards AI_DAILY_LIMIT is unset again, the test rows are deleted and the test user is removed
F26-A85  [L]  PENDING GEMINI KEY: the function logs for the whole A80-A84 window contain none of: the test uid, its SHA-256 hex, the ID token, the Gemini key, any SeedData item name; every ai_usage.uid_hash value matches ^[0-9a-f]{64}$
F26-A86  [L]  PENDING GEMINI KEY: on an Android debug build signed in with a test account, ai_stylist_enabled delivered as true only to that device (Remote Config condition), Style me for today shows the AI hub line, AI results with 'Styled by AI from the pieces in your wardrobe.', and only pieces from that account's wardrobe; in airplane mode the same flow ends on algorithm looks with the simulated label within 16 s and no error UI; with the flag false the hub shows the simulated line and the function logs show no invocation from the device
F26-A87  [L]  PENDING GEMINI KEY: ai_stylist_enabled is published true for all users only after A80-A86 PASS and the user has confirmed in writing that the privacy policy discloses processing by Google's Gemini API (date recorded in the completion block); until then the published template value is false
```

## 12. Edge cases

- **"Complete my outfits" off (match, `includeAccessories` false):** looks
  may use only selected ids, enforced in the prompt, server-side (§5.3 d) and
  client-side (A59). F04-A14 therefore holds on the AI path too. A locked
  accessory is always selected (`lockedIds ⊆ selectedIds`), so it is always
  allowed.
- **`includeAccessories` in auto mode:** F03's algorithm ignores it in auto
  mode. The AI path only tells the model not to add Accessories when it is
  false, and the server does not enforce it (a preference, not an ownership
  rule).
- **Wardrobe of one item:** `items` has 1 entry and is valid, but every
  outfit needs at least 2 ids, so the server returns 502 and the app falls
  back to F03's template result (A15, A58).
- **Wardrobe item names over 60 characters:** the wardrobe UI has no name
  limit, so the client truncates every string at a code point boundary
  (A51). The server would otherwise reject the whole request (§13
  "design vs code").
- **Two items with the same display name but different ids:** both are sent;
  ids are the only identity.
- **Model returns ids in different letter case:** they are dropped
  (case-sensitive, A19).
- **The same outfit twice in different order:** the second is dropped
  (A25).
- **Gemini model retired:** `http_404` gives 502 and the app falls back.
  This is fixed by `supabase secrets set GEMINI_MODEL=...` with no deploy and
  no release. A80 catches it at rollout.
- **`thinkingBudget: 0` rejected by a future `GEMINI_MODEL`:** that gives
  `http_400`, so 502 and fallback. Changing the model is preceded by an A80/A81
  re-run, and if the field must change, A29 is amended by a dated note.
- **UTC day boundary:** the cap resets at 00:00 UTC, not local midnight
  (A36).
- **A user who signs in on two devices** shares one allowance (same uid hash).
- **Many quick taps:** `isGenerating` ignores re-entry (A64). "Refresh
  combinations" after results counts as a new attempt.
- **`AI_DAILY_LIMIT=0`** turns AI off server-side for everyone at once
  (every call gets 429), even if the flag is on in an old cached config.
- **Remote Config flips mid-session:** the hub line updates at the screen's
  next build. A results label always follows each result's own `source`, so
  it can never claim AI wrongly (anti-goal).
- **`kShowDemoNotes` false** (a compile-time constant, `true` today) would
  hide the AI label too. It is unchanged and out of scope.
- **Provider returns more than 3 outfits:** the first 3 valid, distinct ones
  are kept (A24).
- **Supabase project paused (free tier):** every call fails at the gateway
  and the app falls back. The probes in §5.6 restore it first (F23
  precedent).

## 13. Open questions

**Preconditions (mechanical, applied with this document, 2026-10-30):**

- **P1 — Foundation amendments.**
  - `03-domain-model.md`: `StyleResult.source`, plus documenting the
    already-existing `StylistState.styleDirection`/`weather`;
    `AppConfig.aiStylistEnabled` is marked as consumed by F26; a new §4 row
    for `StyleResult.source`.
  - `07-security.md` §4: secrets, `ai_usage`, Gemini disclosure.
  - `01-tech-stack.md`: Data row and §5 note.
  - `02-architecture.md` §2 is **not** edited by this document (out of the
    brief's scope). It should gain the same kind of note F25 added, recording
    that `ai_stylist_client.dart` is an SDK-free abstraction a Cubit may take
    and `http_ai_stylist_client.dart` is imported only by `lib/app.dart`. That
    is for the controller to apply before code starts.
- **P2 — Amendments to existing assertions (dated 2026-10-30, nothing
  deleted).**
  - F23: A07 (uid hash permitted, raw uid never stored or logged), A09
    (adapter branch now reads the body), A11 (rationale: `gemini` is now
    registered), A12 (two more warnings), A14 (one import allowed), A15
    (import set), A18 (one `lib/` file may reference `ai-stylist`), A19
    (scope note), A24 (historical note), plus the §4 and §6 notes.
  - F03: A19 and A24 (labels depend on availability/source), A25 (footnote
    note), A05 and A22 (timing scoped to the algorithm path), A16 (swap also
    flips `source`).
  - F04: A14 (now also holds on the AI path) and A15 (timing scoped).

**Design vs code: contradictions found and how this document resolves them:**

1. **No "detail-modal assertion" exists.** D7 asks to amend "F03-A19, A24 and
   the detail-modal one". F03 has no assertion and no test for
   `DetailFootnote`'s text: F03-A25 lists the detail copy without it, and no
   test contains "design review". **Resolved:** a new assertion, F26-A67,
   covers both footnote variants, and a dated note under F03-A25 points to it.
   Nothing needs amending there.
2. **D5's `primary key (uid, day)`** conflicts with D5's own `uid_hash`
   column. **Resolved:** `primary key (uid_hash, day)` (§8).
3. **F23-A18 (Dart guard) was not in the design's amendment list.** It fails
   the moment `lib/` references `ai-stylist`, which contradicts D6's "every
   existing test passes unchanged". **Resolved:** F23-A18 is amended (one
   allowed file), and F26-A75 records that its test file is the only Dart
   test that changes.
4. **D3's "each string <= 60 chars"** meets a wardrobe that has no
   name-length limit (`ClothingItem.name` is free text, and no `maxLength`
   exists in the wardrobe UI). Without client-side handling, long names would
   always 400 and silently force fallback. **Resolved:** the client truncates
   at a code point boundary (A51), and ids over 60 characters are not sent
   (A63).
5. **The design's wiring note says `StylistCubit` is built "with only
   `WardrobeCubit`".** F25's in-progress change already passes `analytics:`.
   **Resolved:** F26 adds two more optional parameters alongside it (§2.2).
   F25-A36's timing ("after the 1150 ms wait") stays true for the algorithm
   path that its test exercises (no client).
6. **D4 lists no `405`.** **Resolved:** no method restriction is added. A
   `GET` has no body and gets `400 Invalid request body`, keeping the
   response set closed (§6.1).
7. **D3 says only "subsets of items" for `lockedIds`/`selectedIds`.**
   **Decided (stricter, compatible):** `lockedIds ⊆ selectedIds`, at most 6
   locked, and both `[]` in auto mode, because a request that could never
   produce a valid outfit should not consume quota (A10).
8. **D3's `includeAccessories` has no stated meaning in match mode**, and
   the design gives no rule for it. But in today's code it means "Complete my
   outfits": `createMatches` adds unselected shoes and accessories only when
   it is on, and F04-A14 asserts that with it off the looks contain **only
   selected items**. An unconstrained model would break F04-A14 on the AI
   path. **Resolved:** in match mode with `includeAccessories` false, both the
   prompt and the validator (§5.3 d, client-side A59) allow only
   `selectedIds`. A dated note is added under F04-A14.

**Product questions (non-blocking for the build):**

- **Q1 — Privacy policy text.** The user must update the policy to disclose
  that styling options and the item names/categories/colors/occasions/seasons
  sent are processed by Google's Gemini API, and that on the free tier Google
  may use them to improve its products. Free-text item names could contain
  anything the user typed. This blocks A87 (the flag flip), not the build.
- **Q2 — Analytics for the source.** F25's `outfit_generated` has no
  `source` parameter, and adding one changes F25's `AnalyticsParams.all` and
  A01/A02/A04. Proposed: a later dated F25 amendment adding `source`
  (`ai`/`algorithm`) once F25 is closed. It is not done here, because F25 is
  in progress and owned by another agent.
- **Q3 — `ai_usage` retention.** Rows accumulate (one per active user per
  day). Proposed: a later `delete from ai_usage where day < current_date - 30`
  through `pg_cron`, or run manually. It is negligible at MVP scale.
- **Q4 — SQL `[I]` environment.** A45-A49 need a local Supabase stack
  (`supabase start`, which needs Docker). If Docker is unavailable on the
  build machine, the controller decides whether they run in Phase A against
  the live database with a synthetic hash (`'0'` x 64), deleted afterwards.
  The completion block must say which. Skipped tests never count as PASS.
- **Q5 — Harness coverage of Deno tests** (same as F23 Q8): `test_paths` is
  `["test"]`, so Deno `F26_Axx` names are checked manually by the
  contract-auditor.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: NOT STARTED

[ ] Gate 1  Interface documented
[ ] Gate 2  Unit          A01-A40 (Deno), A50-A70 (Dart), A76 (docs)
[ ] Gate 3  Integration   A41-A44 (Deno, real modules), A45-A49 (SQL, local Supabase), A71-A75 (StyloBuddyApp)
[ ] Gate 4  Live run      Phase A A77-A79 (needs the user's deploy go-ahead)
                          Phase B A80-A87 PENDING THE USER'S GEMINI API KEY

Assertions: 0/87 PASS   ([U] 62 · [I] 14 · [L] 11)
Regression: —
```
