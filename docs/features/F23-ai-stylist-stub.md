# F23 — AI Stylist Edge Function (stub) + LLM Adapter Seam

> Adds a deployed, independently testable Supabase Edge Function `ai-stylist`
> that verifies the caller's Firebase ID token and then answers `501` with
> `{"error": "AI provider not configured yet"}`, plus an interface-only
> `_shared/llm-adapter.ts` seam: `LlmAdapter.generateOutfitSuggestion(prompt)`
> and a `getLlmAdapter()` factory that returns `null` because no provider is
> registered. Nothing in the Flutter app calls this function, and the LLM
> provider is not chosen. That choice is a standing deferred decision (user
> instruction 2026-10-19, saved memory note "LLM provider pending"). This
> task builds only the empty seam. It is Task 10 of
> `docs/superpowers/plans/2026-10-19-backend-wiring.md`, grounded in
> `docs/superpowers/specs/2026-10-19-supabase-storage-and-functions.md` §3-4
> and `docs/superpowers/specs/2026-10-19-backend-architecture.md` D8. It
> depends on F15 (Task 2), whose `supabase/functions/_shared/firebase-auth.ts`
> (`verifyFirebaseToken`) is reused unmodified, and whose
> `storage-upload-url/index.ts` + `index.test.ts` set the handler and test
> pattern this task follows.

**Status:** Gates 1-3 done, Gate 4 pending (live deploy, §13 Q2) · **Milestone:** 2 · **Depends on:** F15

---

## 1. Goal

Prove the pipeline that future AI work will use: an Edge Function deployed to
project `dbaeaqyoyilxcuwplvuw` that authenticates a Firebase user and routes
to a swappable LLM provider. This must exist before anyone chooses a
provider, so adding one later means one new adapter file plus one branch in
`getLlmAdapter()`. It must not require rewriting the function or any Flutter
code (spec §3). No user sees anything new. The value is a working,
authenticated, honestly-unimplemented endpoint (`501`, never a fake
suggestion) and a fixed contract for the later provider task.

## 2. MVP scope

- `supabase/functions/_shared/llm-adapter.ts` (new). It contains:
  - `export interface LlmAdapter { generateOutfitSuggestion(prompt: string): Promise<string> }`.
  - `export function getLlmAdapter(): LlmAdapter | null`. It reads the
    `LLM_PROVIDER` environment variable. No provider is registered, so it
    returns `null` for every value, including unset.
  - When it returns `null`, it logs one server-side `console.warn` line that
    says why. "Not set", "set but empty" and "names an unregistered
    provider" each get their own message (§10, A12; proposal, §13 Q4).
  - No imports, no network calls, no provider SDK, no implementation of
    `LlmAdapter`.
- `supabase/functions/ai-stylist/index.ts` (new). It follows
  `storage-upload-url/index.ts`'s shape exactly:
  - `export async function handleRequest(req, deps)`, where `deps` lets a
    test inject `verify` (default `verifyFirebaseToken`) and `getAdapter`
    (default `getLlmAdapter`).
  - A local `jsonResponse(body, status)` helper.
  - `Deno.serve` only inside `if (import.meta.main)`, so importing the module
    from a test does not start a listener.
  - Behaviour follows the spec §3 sketch:
    - missing, invalid or expired token: plain-text `401 Unauthorized`;
    - valid token and no adapter: `501` JSON;
    - valid token and an adapter present (unreachable today, but reachable
      by injection): a defined `501` (§13 Q3). The spec sketch's
      fall-through to an `undefined` response is not acceptable.
- `supabase/functions/ai-stylist/index.test.ts` and
  `supabase/functions/_shared/llm-adapter.test.ts` (new Deno tests). They
  follow `storage-upload-url/index.test.ts`: injected collaborators, no real
  network, test names prefixed `F23_Axx`.
- `supabase/config.toml`: add `[functions.ai-stylist]` with
  `verify_jwt = false`. This file is not in the plan's file list (§13 Q1).
  Without it, Supabase's gateway rejects every Firebase-signed token before
  the function runs (F15 handoff, "Issues discovered"). Every live
  authenticated call would then get a gateway 401 rather than the `501`, so
  A24 could never pass.
- A Dart guard test under `test/` (A18). It asserts that no `lib/` file
  references `ai-stylist`, so "not wired to any UI" holds structurally.
- Final, separately gated step: `supabase functions deploy ai-stylist
  --project-ref dbaeaqyoyilxcuwplvuw` followed by live probes (A22-A24). It
  runs only after an explicit controller/user go-ahead (§13 Q2).

## 3. Later scope

- Choosing an LLM provider (Claude, OpenAI or other), its adapter file, its
  API key (`supabase secrets set`), and the real `generateOutfitSuggestion`
  call. Deferred by explicit user instruction. The user asked to be reminded
  once the whole backend-wiring plan is done. This document does not choose
  one or suggest one.
- The request contract: what the Flutter client would send (occasion,
  wardrobe item ids, weather and so on), how the prompt is built from it,
  and the success response shape. None exists yet, so the handler never
  reads the request body (A08).
- Any Flutter caller. That means a repository method, wiring `StylistCubit`,
  or any change to F03's algorithmic generation (`generateAutomatic`,
  `generateMatches`). All of it is deferred together with the provider
  choice (spec §3).
- CORS headers and an `OPTIONS` preflight response. These are only needed
  for a browser (Flutter web) caller, and none exists. Architecture D8 lists
  CORS as part of "proving the pipeline". The spec §3 sketch does not
  include it (§13 Q5).
- HTTP method restriction, rate limiting, per-user quotas and request size
  limits. These belong with the real provider call, where cost is real.
- Moving `jsonResponse` into `_shared/`. Doing that would mean editing
  `storage-upload-url/index.ts`, which this task does not touch.

## 4. Roles and permissions

Roles are from `docs/foundation/07-security.md` §2.

| Role | Access to `ai-stylist` |
|---|---|
| guest | Never calls it. No Flutter code references it (A18). If someone calls it directly with no token, they get `401 Unauthorized`. |
| demo user | Same as guest. |
| authenticated user (valid Firebase ID token for project `stylobuddy-b7e46`) | Gets `501 {"error": "AI provider not configured yet"}`. The verified uid is used only as the auth gate. It is never echoed, logged or stored (A07). |
| anyone with a missing, malformed, expired, wrong-audience or forged token | `401 Unauthorized`. The adapter factory is never reached (A02, A04). |

The function reads and writes no user data: no Firestore, no Storage, no
Supabase service-role client (A15). Cross-user isolation therefore does not
apply here. There is no per-user resource to isolate.

## 5. Main flows

```text
Valid caller, today (no provider registered):
  client -> ai-stylist: any method, Authorization: Bearer <firebase-id-token>
  ai-stylist.handleRequest:
    uid = await verify(req)                       # verifyFirebaseToken, F15, unmodified
    uid present -> adapter = getAdapter()         # getLlmAdapter(): reads LLM_PROVIDER
                   adapter == null  (always today; one console.warn stating why, A12)
                   -> 501, content-type application/json,
                      body {"error":"AI provider not configured yet"}
  request body never read (req.bodyUsed stays false, A08)

Missing / invalid / expired / forged token:
  client -> ai-stylist: no Authorization header, or a bad token
  ai-stylist.handleRequest:
    uid = await verify(req) -> null
    -> 401, body "Unauthorized" (text/plain, plain-text precedent of storage-upload-url, §13 Q6)
    getAdapter() is NEVER called; nothing else runs

Adapter present (unreachable in production until a provider is registered;
reachable only via test injection), proposed, §13 Q3:
  uid present -> adapter != null
  -> 501, application/json, {"error":"AI stylist not implemented yet"}
  adapter.generateOutfitSuggestion is NEVER called (no request contract exists to build a prompt from)

Gateway (deployed only):
  Supabase gateway: verify_jwt = false for ai-stylist (config.toml)
  -> the request reaches handleRequest with the Firebase token intact
  (if verify_jwt were left at its default true, every call would get the gateway's own
   JSON 401 (UNAUTHORIZED_*), which A23 is designed to tell apart from the function's own 401)

Future provider task (illustrative only, NOT built here):
  new _shared/<provider>-adapter.ts implements LlmAdapter
  getLlmAdapter(): LLM_PROVIDER == "<name>" -> return that adapter
  ai-stylist's adapter-present branch replaced with the real call
  no Flutter change needed for the function to start answering 200

Deploy (gated, never automatic), §13 Q2:
  precondition: F23-A01..A21 PASS locally (deno test, deno lint, flutter test), recorded with command + date
  controller/user -> implementer: explicit go-ahead (date recorded in completion block)
  implementer:
    1. supabase secrets list --project-ref dbaeaqyoyilxcuwplvuw   (names only; confirm no LLM_PROVIDER)
    2. note storage-upload-url's current version (supabase functions list)
    3. supabase functions deploy ai-stylist --project-ref dbaeaqyoyilxcuwplvuw
       (access token from ~/.secrets/stylobuddy/supabase-access-token.txt, never committed or echoed)
    4. live probes A23, A24; storage-upload-url version unchanged (A22)
  any probe failure -> report it; the function is unreferenced by the app, so no user impact,
    but it is not marked PASS and is not "fixed" by weakening an assertion
```

## 6. Interface surface

```text
supabase/functions/_shared/llm-adapter.ts
  export interface LlmAdapter {
    generateOutfitSuggestion(prompt: string): Promise<string>
  }
  export function getLlmAdapter(): LlmAdapter | null
      reads env LLM_PROVIDER; returns null for every value today (zero registered providers)
      side effect on null: exactly one console.warn naming the reason (A12)

supabase/functions/ai-stylist/index.ts
  export interface HandleRequestDeps {
    verify?: typeof verifyFirebaseToken        // default: verifyFirebaseToken (F15)
    getAdapter?: typeof getLlmAdapter          // default: getLlmAdapter
  }
  export async function handleRequest(req: Request, deps?: HandleRequestDeps): Promise<Response>
  if (import.meta.main) Deno.serve((req) => handleRequest(req))

HTTP  (any method)  https://dbaeaqyoyilxcuwplvuw.supabase.co/functions/v1/ai-stylist
  Authorization missing/invalid/expired/forged -> 401  text/plain        "Unauthorized"
  valid token, no adapter (today)              -> 501  application/json  {"error":"AI provider not configured yet"}
  valid token, adapter present (injection only)-> 501  application/json  {"error":"AI stylist not implemented yet"}  (§13 Q3)
  callers: none in the app; developers / live probes only
```

These are all the responses the function can return. It has no `200` path,
no `400` (the body is never read), and no `500` path of its own. An
uncaught throw would be a defect (§10). The name `LlmAdapter` is introduced
here. The spec describes the interface but does not name it.

## 7. Domain model usage

None. The function reads no entity from `docs/foundation/03-domain-model.md`
and writes none. `LlmAdapter.generateOutfitSuggestion` takes and returns
plain `string`s on purpose. It does not take an `Outfit` or `ClothingItem`.
Mapping between domain entities and a prompt is part of the deferred request
contract (§3), and a provider task must design it against
`03-domain-model.md` names when it lands.

## 8. Data changes

- New files:
  - `supabase/functions/_shared/llm-adapter.ts`
  - `supabase/functions/_shared/llm-adapter.test.ts`
  - `supabase/functions/ai-stylist/index.ts`
  - `supabase/functions/ai-stylist/index.test.ts`
  - one Dart guard test under `test/` (for example
    `test/backend/ai_stylist_unwired_test.dart`; the name is the
    implementer's choice) for A18.
- Modified: `supabase/config.toml`. Add a `[functions.ai-stylist]` block
  with `verify_jwt = false` and a comment explaining why, mirroring the
  existing `storage-upload-url` block. That block and `project_id` stay
  byte-identical (A21, §13 Q1).
- Unmodified, explicitly:
  - `supabase/functions/_shared/firebase-auth.ts` (A20);
  - everything under `supabase/functions/storage-upload-url/`;
  - everything under `lib/` and `pubspec.yaml` (A19);
  - `firestore.rules`.
- Docs (per the plan's "update the foundation doc that describes the
  reality" rule; scope confirmation in §13 Q7):
  - `docs/foundation/07-security.md` §4: future LLM provider keys and the
    `LLM_PROVIDER` selector are set only through `supabase secrets set` and
    are never committed or logged.
  - `docs/foundation/01-tech-stack.md`: the Data row notes the `ai-stylist`
    stub (`501`), with its deploy state.

  `docs/tracker.md` / `docs/project-handoff.md` are left to Task 11 per the
  plan.
- No Firestore, Storage or database migration. No secret is created. In
  particular, `LLM_PROVIDER` is not set.

## 9. Background work and events

None. The function is a stateless request/response handler. It adds no job,
schedule, trigger, Firestore write, Analytics event or audit record. The
only side effect is the one `console.warn` line on the `501` path. It goes to
Supabase's function logs and contains no uid, token or secret (A07, A12).
The deploy is a one-shot manual command, never chained to a test run, commit
hook or CI step (A22).

## 10. Degradation and failure

| Situation | Outcome |
|---|---|
| `Authorization` header missing | `401`, body `Unauthorized`, `text/plain`. `getAdapter` is never called (A02, A04). |
| Token malformed, expired, wrong audience/issuer, or signed by a key outside the JWKS | Same as missing: `401 Unauthorized`. `verifyFirebaseToken` resolves `null` and never throws (F15-A18/A19/A21). |
| Google JWKS endpoint unreachable (deployed only) | `jose` fails verification, `verifyFirebaseToken` catches it and returns `null`, and the caller gets `401`. This is a pre-existing F15 behaviour that this task inherits rather than changes. A valid user then sees `401`, not `501`. That is acceptable for a function nothing calls, and it is recorded so it is not mistaken for a token problem during the live run. |
| `LLM_PROVIDER` unset (today's production state) | `getLlmAdapter()` returns `null` and warns `LLM_PROVIDER is not set`. Response is `501` with the exact JSON body (A01, A05, A12). |
| `LLM_PROVIDER` set but empty or whitespace-only | Also `null`, but the warning is `LLM_PROVIDER is set but empty`. "Missing" and "empty" give the same client response (the client must not learn server configuration) but different operator-visible diagnostics (A06, A12). |
| `LLM_PROVIDER` names a provider that is not registered (for example `anthropic`, which an operator might set before the adapter ships) | `null`, warning `LLM_PROVIDER "<value>" is not a registered provider`, and the same `501` body. The provider name is not a secret and may be logged. No other environment value is ever logged (A06, A11, A12). |
| Adapter present (test injection only today) | Defined `501` `{"error":"AI stylist not implemented yet"}`. `generateOutfitSuggestion` is never called (A09, §13 Q3). The spec sketch's fall-through, which returns `undefined` and makes `Deno.serve` produce a 500, must not happen. |
| Request body absent, non-JSON or huge | Never read, so no `400`/`500` comes from parsing, and the response depends only on the token and the adapter (A08). |
| Gateway JWT verification left enabled (`verify_jwt` missing from `config.toml`) | Every live call gets the gateway's JSON `401` (`UNAUTHORIZED_*`), never the function's own response. A21 catches this statically and A23/A24 catch it live by checking the body, not just the status. |
| Deploy fails (auth, network, bundle error) | Production is unchanged (the function does not exist yet). The report gives the failure, and A22-A24 stay open. |
| Deploy succeeds but a live probe fails | The app is unaffected, because nothing references the function (A18). The probe stays FAIL with the observed status and body. Fix and redeploy within the same go-ahead, or escalate. An assertion is never weakened to match. |

## 11. Validation assertions

Gates:

- `[U]` means Deno or Dart tests with every collaborator injected or faked,
  plus static and repository checks.
- `[I]` means the handler wired to the real `verifyFirebaseToken` (with a
  local test JWKS and test-signed tokens, so real cryptography but no
  network) and the real `getLlmAdapter` (driven by real `Deno.env`). This is
  the full request-to-response path short of deployment.
- `[L]` means the deployed function on project `dbaeaqyoyilxcuwplvuw`. These
  run only inside the gated deploy step (§13 Q2).

Deno test names start `F23_Axx`, like F15's `F15_A17`. Tests that change
`LLM_PROVIDER` restore its original state, unset or set, in a `finally`
block.

```
F23-A01  [U]  handleRequest with verify injected to resolve "uid-123" and getAdapter injected to return null returns status 501, header content-type exactly "application/json", and a body that parses to an object deep-equal to {"error": "AI provider not configured yet"} with no other keys
F23-A02  [U]  handleRequest with verify injected to resolve null returns status 401 with body text exactly "Unauthorized" and a content-type that is not application/json (text/plain), and the injected getAdapter spy is called zero times (mirrors F15's "never calls sign()")
F23-A03  [U]  On the valid-token path, verify is called exactly once with the same Request object passed to handleRequest, getAdapter is called exactly once, and the recorded call order is verify then getAdapter (the adapter is never consulted before authentication resolves)
F23-A04  [I]  handleRequest wired to the real verifyFirebaseToken with a local test JWKS returns 401 "Unauthorized" with getAdapter never called for each of: no Authorization header; "Bearer " with an empty token; "Basic dXNlcjpwYXNz"; "Bearer not-a-jwt"; an expired token; a token whose audience is another project; a token signed by a key absent from the JWKS
F23-A05  [I]  handleRequest wired to the real verifyFirebaseToken (local JWKS, valid test-signed token for project stylobuddy-b7e46) and the real getLlmAdapter, with LLM_PROVIDER deleted from the environment, returns 501 with content-type application/json and the exact body of A01
F23-A06  [I]  The same wiring as A05 returns the identical 501 status and body when LLM_PROVIDER is set to "" and when it is set to "anthropic", so neither the "empty" nor the "unregistered name" configuration changes what the client sees
F23-A07  [U]  No response body ever contains the verified uid, the bearer token, or the LLM_PROVIDER value: with verify resolving "uid-marker-7f3a", the token "tok-marker-91c2" and LLM_PROVIDER "provider-marker-55d0", neither the 501 nor the 401 body text contains any of the three marker strings
F23-A08  [U]  The request body is never read: with a valid token and getAdapter returning null, each of a POST with no body, a POST with body "{{not json", a POST with body {"prompt":"x"} and a GET with no body returns the identical 501 response, and req.bodyUsed is false after each call
F23-A09  [U]  Adapter-present branch (pending §13 Q3): with getAdapter injected to return a test-double LlmAdapter that records calls, handleRequest resolves to a defined Response (never undefined, never throws) with status 501, content-type application/json and body deep-equal to {"error": "AI stylist not implemented yet"}, and the double's generateOutfitSuggestion is called zero times
F23-A10  [U]  getLlmAdapter() returns null when LLM_PROVIDER is not set in the environment (today's production state)
F23-A11  [U]  getLlmAdapter() returns null for each of LLM_PROVIDER = "", "   ", "anthropic", "openai", "claude" and "ANTHROPIC"; with zero providers registered, no value, valid-looking or not, yields an adapter
F23-A12  [U]  Missing vs empty vs unregistered are distinguished for the operator (pending §13 Q4): with console.warn stubbed, each null-returning getLlmAdapter() call emits exactly one warn line; unset gives a line containing "LLM_PROVIDER is not set"; "" and "   " give a line containing "LLM_PROVIDER is set but empty"; "anthropic" gives a line containing `LLM_PROVIDER "anthropic" is not a registered provider`; the three messages are pairwise different, and no line contains the value of any other environment variable
F23-A13  [U]  LlmAdapter's shape is pinned at type level under deno test's type-check: an object literal {generateOutfitSuggestion: (prompt: string) => Promise.resolve("ok")} satisfies LlmAdapter compiles; an object missing generateOutfitSuggestion and one whose generateOutfitSuggestion returns Promise<number> are each marked @ts-expect-error, and that directive is itself satisfied (the file fails to type-check if either becomes assignable)
F23-A14  [U]  Static: supabase/functions/_shared/llm-adapter.ts contains no import statement, no fetch( call, no "npm:" or "jsr:" specifier, no class or object implementing LlmAdapter (the identifier generateOutfitSuggestion occurs exactly once, in the interface declaration), and no Deno.env.get( call whose argument is anything other than "LLM_PROVIDER"; its exports are exactly LlmAdapter and getLlmAdapter
F23-A15  [U]  Static: supabase/functions/ai-stylist/index.ts imports only "../_shared/firebase-auth.ts" and "../_shared/llm-adapter.ts" (plus jsr:@std test helpers in the test file only); it does not import npm:@supabase/supabase-js or any provider SDK, contains no Deno.env access of its own, and never references SUPABASE_SERVICE_ROLE_KEY or SUPABASE_URL
F23-A16  [U]  Importing ai-stylist/index.ts from index.test.ts starts no listener: Deno.serve appears only inside an `if (import.meta.main)` block, and every F23 Deno test passes with Deno's default op and resource sanitizers enabled (no test sets sanitizeOps: false or sanitizeResources: false), so a leaked server would fail the run
F23-A17  [U]  No real network in tests: `deno test --allow-env supabase/functions/ai-stylist/ supabase/functions/_shared/llm-adapter.test.ts`, run without --allow-net, passes; no F23 test calls verifyFirebaseToken without an explicit jwks option, and none calls handleRequest without an injected or locally bound verify
F23-A18  [U]  Structural "not wired to any UI": a Dart test under test/ named F23_A18 scans every file under lib/ and fails, naming the file, if any contains "ai-stylist" (case-insensitive) or "functions/v1/ai"; it passes on the current tree (today the only Edge Function reference in lib/ is storage-upload-url in lib/shared/backend/storage_repository.dart)
F23-A19  [U]  This task changes nothing in the Flutter app: `git diff --name-only <task-base>..HEAD -- lib/ pubspec.yaml pubspec.lock` is empty, so StylistCubit (generateAutomatic, generateMatches and every other member) is byte-identical; the full `flutter test` suite passes with no pre-existing test's assertions edited, and `flutter analyze` reports no issues
F23-A20  [U]  F15's shared code is reused, not changed: `git diff <task-base>..HEAD -- supabase/functions/_shared/firebase-auth.ts supabase/functions/_shared/firebase-auth.test.ts supabase/functions/storage-upload-url/` is empty; `deno test --allow-net --allow-env supabase/functions/` passes every pre-existing F15 Deno test plus every F23 test; `deno lint supabase/functions` reports no problems
F23-A21  [U]  supabase/config.toml contains a [functions.ai-stylist] table with verify_jwt = false; the [functions.storage-upload-url] table and the project_id line are byte-identical to <task-base>
F23-A22  [L]  `supabase functions deploy ai-stylist --project-ref dbaeaqyoyilxcuwplvuw` is run only after F23-A01..A21 PASS and an explicit controller/user go-ahead is recorded with its date in the completion block; immediately before it, `supabase secrets list --project-ref dbaeaqyoyilxcuwplvuw` (names only, values never printed or saved) shows no LLM_PROVIDER secret; the deploy exits 0; `supabase functions list` afterwards shows ai-stylist, and storage-upload-url's version is the same as before the deploy (only ai-stylist was deployed); no test, script, hook or CI step invokes the deploy
F23-A23  [L]  Against the deployed function, a POST to https://dbaeaqyoyilxcuwplvuw.supabase.co/functions/v1/ai-stylist with no Authorization header returns 401 with body exactly "Unauthorized", and the same with "Authorization: Bearer garbage"; a gateway-issued JSON 401 (a body naming an UNAUTHORIZED_* code) is a FAIL, because it means verify_jwt = false is not in effect
F23-A24  [L]  Against the deployed function, a request carrying a real, freshly minted Firebase ID token for a live test user (minted as F15-A25 did: a service-account custom token exchanged via Identity Toolkit; the token is never logged, committed or pasted into the report) returns 501 with content-type application/json and a body that parses deep-equal to {"error": "AI provider not configured yet"}
F23-A25  [U]  Docs reflect the new reality (pending §13 Q7): docs/foundation/07-security.md §4 names LLM_PROVIDER and states that it and any future provider API key are set only via `supabase secrets set` and never committed or logged; docs/foundation/01-tech-stack.md mentions the ai-stylist stub and that it returns 501 until a provider is chosen; each edit carries a dated note
```

## 12. Edge cases

- **Token for a different Firebase project:** `401`, because
  `verifyFirebaseToken` checks the audience and issuer against
  `stylobuddy-b7e46` (A04).
- **`OPTIONS` preflight from a browser:** it has no `Authorization` header,
  so it gets `401`. A browser caller would fail CORS. That is acceptable
  because no browser caller exists (§3, §13 Q5).
- **Very large request body:** never read (A08). The platform's own request
  limits apply. The function adds no limit of its own.
- **`LLM_PROVIDER` with surrounding whitespace, such as `" anthropic "`:**
  still `null` today, since any value gives `null`. Whether a future
  registry trims before matching is the provider task's decision. A12 only
  fixes that whitespace-only counts as "empty".
- **`LLM_PROVIDER` case:** `ANTHROPIC` gives `null` today (A11). Case
  handling is also left to the provider task.
- **Module loading without `--allow-net` (A17):** Deno permissions apply to
  runtime operations, not static `npm:`/`jsr:` imports. A cold cache still
  needs network access once, to download `jose` and `@std/assert`. Warm the
  cache with `deno cache` first, so a failure under A17 means the test made
  a real network call, not that it fetched a dependency. If this turns out
  wrong in practice, amend A17 with a dated note rather than dropping it.
  **Amendment, 2026-10-20:** the actually-required command is `deno test
  --allow-env --allow-read supabase/functions/ai-stylist/
  supabase/functions/_shared/llm-adapter.test.ts`, not `--allow-env` alone.
  `--allow-read` is also required, because F23-A14 and F23-A15 are
  static-structure checks that read `llm-adapter.ts`'s and `index.ts`'s own
  source text via `Deno.readTextFileSync`; without it, those two tests fail
  with `NotCapable`. This does not change A17's actual claim, which is
  specifically about `--allow-net` not being needed — that part still
  holds.
- **The verified uid is unused after the gate:** this is intentional. It
  would become the per-user key for quotas or context only in the provider
  task. Lint must stay clean, and a truthiness check on `uid` counts as a
  use.
- **The spec §4 deploy command deploys both functions together**
  (`deploy storage-upload-url ai-stylist`). This task deploys `ai-stylist`
  alone, per the plan. Redeploying a live, working function that this task
  did not change is avoidable risk (A22 checks it is not redeployed).

## 13. Open questions

**Q1 and Q2 block the live gate (A21-A24). Everything else can proceed with
the proposals below and be amended by dated note if a ruling differs.**

- **Q1: `supabase/config.toml` is outside the plan's Task 10 file list, but
  the live run needs it. (BLOCKING for A21-A24.)** F15 found live that
  Supabase's gateway rejects Firebase ID tokens unless `verify_jwt = false`
  is set for the function (`UNAUTHORIZED_ASYMMETRIC_JWT`, F15 handoff).
  Without it, A24's live `501` can never be observed. A23's no-token `401`
  would still pass, but for the wrong reason: the gateway would issue it,
  not the function. A23 checks the body for exactly this. **Proposed:**
  allow the one-block addition to `config.toml`, mirroring the existing
  `storage-upload-url` block, and leave every other line byte-identical
  (A21). Alternative: deploy with `--no-verify-jwt` only, without the config
  entry. This is not recommended, because the next plain deploy would
  silently turn gateway verification back on.

- **Q2: Should the deploy happen in this task, or wait for a combined
  go-ahead with F22's (Task 9's) production rules deploy? (BLOCKING for
  A22-A24 only.)** The plan says "Deploy" as Task 10's last step, which
  reads as automatic. **Proposed:** treat it as gated, like F22-A51: an
  explicit controller/user go-ahead, with its date recorded in the
  completion block. It may be bundled into the same human sign-off as
  F22's deploy if that is easier, but it does not depend on F22. The risk
  is lower than a rules deploy:
  - nothing references the function (A18);
  - it returns only `401`/`501`;
  - it touches no data;
  - it uses no service-role key.

  It is still a new, publicly reachable production endpoint on the live
  project, using the user's access token, so it should not run on its own.
  All local work (A01-A21, A25) can be completed and reviewed before the
  go-ahead.

- **Q3: What the handler does when an adapter is present.** The spec §3
  sketch ends with "Real call happens here once a provider is chosen" and
  then falls through. The function would resolve `undefined`, and
  `Deno.serve` would answer `500`. No provider can be registered today, but
  the branch is reachable through `deps.getAdapter` injection, and a
  provider task might register an adapter before replacing this branch.
  **Proposed:** `501` `{"error": "AI stylist not implemented yet"}` (a
  different message from the "not configured" case, so the two states can
  be told apart), and `generateOutfitSuggestion` is never called, because
  there is no request contract to build a prompt from (A09). Alternative:
  call `generateOutfitSuggestion` with a placeholder prompt. Rejected,
  because it would make up a request contract. Ruling needed. A09 is
  amended by dated note if the ruling differs.

- **Q4: Missing vs empty `LLM_PROVIDER`.** This document must assert that
  "missing" and "empty" behave differently, but the spec fixes one client
  response for "not configured". **Proposed:** the client response stays
  identical (A06), so configuration state never leaks. The difference shows
  up only in the operator log, as three distinct `console.warn` reasons
  (A12, exact wording in §10). Whitespace-only counts as empty. Ruling
  needed on (a) whether a warn line on every `501` request is acceptable log
  volume for an unreferenced function (proposed: yes), and (b) the exact
  wording, which A12 pins.

- **Q5: Architecture D8 disagrees with the spec, the plan and the user's
  instruction in four places.**
  - D8 says the scaffold proves "a Flutter-side repository call that hits
    it". The plan, spec §3 and this brief all say no Flutter code calls it.
    This document follows the plan and spec, and A18/A19 enforce that.
  - D8 includes "CORS". The spec sketch has none, and no browser caller
    exists. This document defers CORS (§3).
  - D8 names the file `llmAdapter.ts`. The plan and spec use
    `llm-adapter.ts`, which this document follows.
  - D8 says `501 Not Configured`. The spec gives the exact body
    `{"error": "AI provider not configured yet"}`, which this document
    follows.

  **Proposed:** add a dated amendment note to D8 in
  `docs/superpowers/specs/2026-10-19-backend-architecture.md` in this task,
  recording that the spec §3 and plan wording supersede it. Confirmation
  needed. Non-blocking.

- **Q6: Error body shapes.** The precedent is
  `storage-upload-url/index.ts`: plain text `new Response("Unauthorized",
  { status: 401 })`, with JSON `{"error": ...}` for every other error
  status. The spec §3 sketch uses the same split. **Proposed:** match the
  precedent exactly. `401` is plain text `Unauthorized` (`text/plain`,
  A02/A23), and `501` is JSON (A01/A09). The two functions then behave the
  same, and a future shared Flutter caller handles one convention. The
  alternative is a JSON `401` (`{"error": "Unauthorized"}`) for this
  function only. That would make the two functions inconsistent, and
  changing `storage-upload-url` to match is outside this task. Ruling
  requested. A02 and A23 are amended by dated note if JSON is chosen.

- **Q7: Updating foundation docs (A25).** The plan's global constraint
  says foundation docs are updated by the task that changes the reality
  they describe. `07-security.md` §4 does not mention `LLM_PROVIDER` or
  provider keys, and `01-tech-stack.md` does not mention Edge Functions
  beyond "Still later: Supabase Storage", which is already stale since F15.
  **Proposed:** make the two small edits in A25. Leave
  `docs/tracker.md` ("Supabase Edge Functions (none created)", also stale)
  and `project-handoff.md` to Task 11, as the plan assigns. Non-blocking.

- **Q8: The harness does not see Deno test names.** `.claude/harness.json`
  `test_paths` is `["test"]`, so the `assertion_coverage` hook does not scan
  `supabase/functions/**/*.test.ts`. Only A18 (the Dart guard) is
  mechanically coverage-checked. F15 had the same gap. **Proposed:** the
  contract-auditor checks F23's Deno test names manually, as for F15,
  without changing the harness config in this task. Adding `supabase` to
  `test_paths` is a harness change for the controller, not this task.
  Non-blocking.

- **Q9: Reminder, not a question for this task.** The LLM provider choice
  is still deferred. Per the user's instruction, raise it with the user
  after the whole backend-wiring plan is done (Task 11's handoff), not
  during this task.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: Local work complete (2026-10-20). A01-A21 + A25 PASS. A22-A24
deferred — gated live deploy not run, per §13 Q2 ruling.

[x] Gate 1  Interface documented (this document, §6)
[x] Gate 2  Unit — 16 Deno [U] tests (5 llm-adapter.test.ts + 11
    index.test.ts) plus the Dart guard test (A18), all passing
[x] Gate 3  Integration (real verifyFirebaseToken + local JWKS, real
    getLlmAdapter + Deno.env) — A04, A05, A06, all passing
[ ] Gate 4  Live run (gated deploy, §13 Q2 — controller/user go-ahead: ____ )

Assertions: 22/22 non-deferred PASS (A01-A21, A25). 3 deferred (A22-A24,
[L], pending the Gate 4 go-ahead).
Regression: none — storage-upload-url (5/5), firebase-auth (7/7) and the
full flutter test suite all pass unchanged; flutter analyze clean; nothing
under lib/ touched.
```
