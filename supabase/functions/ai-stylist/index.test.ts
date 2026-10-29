// F23 (Task 10) — Deno tests for the ai-stylist stub Edge Function.
// Assertion names are prefixed F23_Axx per
// docs/features/F23-ai-stylist-stub.md §11. [U] tests inject every
// collaborator; [I] tests wire the real verifyFirebaseToken (local test
// JWKS, no network) and the real getLlmAdapter (real Deno.env).
import { assertEquals, assertNotEquals, assertStrictEquals } from "jsr:@std/assert@1";
import {
  generateKeyPair,
  exportJWK,
  SignJWT,
  type KeyLike,
} from "npm:jose@5";
import { handleRequest, type HandleRequestDeps } from "./index.ts";
import { createLocalJWKSet, verifyFirebaseToken } from "../_shared/firebase-auth.ts";
import { getLlmAdapter, type LlmAdapter } from "../_shared/llm-adapter.ts";
import { LlmProviderError } from "../_shared/gemini-adapter.ts";
import { hashUid, type UsageDecision } from "../_shared/usage-limit.ts";
import {
  A04_TEXT,
  captureConsole,
  geminiBody,
  type RecordedCall,
  recordingFetch,
  validRequestBody,
  withEnvVars,
} from "../_shared/test-support.ts";

const PROJECT_ID = "stylobuddy-b7e46";
const ENV_KEY = "LLM_PROVIDER";

function request(authHeader?: string, init: RequestInit = {}): Request {
  const headers = new Headers(init.headers);
  if (authHeader !== undefined) headers.set("Authorization", authHeader);
  return new Request("https://example.com/ai-stylist", { ...init, headers });
}

// `fn` is awaited *inside* the try block (not just returned) so the
// restoration in `finally` cannot run until any async work inside `fn` —
// e.g. a `handleRequest` call that reads LLM_PROVIDER after its own
// `await verify(req)` — has actually completed. Returning an unawaited
// promise from `try` would let `finally` race ahead of it.
async function withEnv<T>(value: string | undefined, fn: () => T | Promise<T>): Promise<T> {
  const original = Deno.env.get(ENV_KEY);
  try {
    if (value === undefined) {
      Deno.env.delete(ENV_KEY);
    } else {
      Deno.env.set(ENV_KEY, value);
    }
    return await fn();
  } finally {
    if (original === undefined) {
      Deno.env.delete(ENV_KEY);
    } else {
      Deno.env.set(ENV_KEY, original);
    }
  }
}

/** Captures console.warn lines emitted while `fn` runs, restoring the real
 * console.warn afterward even if `fn` throws. Mirrors
 * llm-adapter.test.ts's captureWarn so A05/A06 can prove the real
 * getLlmAdapter actually observed the LLM_PROVIDER value under test,
 * instead of only checking the response status/body came back right
 * (fix round, Important finding 2). */
async function captureWarnAsync<T>(fn: () => Promise<T>): Promise<{ result: T; lines: string[] }> {
  const lines: string[] = [];
  const original = console.warn;
  console.warn = (...args: unknown[]) => {
    lines.push(args.map((a) => String(a)).join(" "));
  };
  try {
    const result = await fn();
    return { result, lines };
  } finally {
    console.warn = original;
  }
}

// --- [U] unit tests: every collaborator injected -----------------------

Deno.test(
  "F23_A01 valid token + no adapter returns 501 application/json {\"error\":\"AI provider not configured yet\"}",
  async () => {
    const response = await handleRequest(request("Bearer good-token"), {
      verify: () => Promise.resolve("uid-123"),
      getAdapter: () => null,
    });

    assertEquals(response.status, 501);
    assertEquals(response.headers.get("content-type"), "application/json");
    const body = await response.json();
    assertEquals(body, { error: "AI provider not configured yet" });
    assertEquals(Object.keys(body).length, 1);
  },
);

Deno.test(
  "F23_A02 missing/invalid token returns 401 \"Unauthorized\" (plain text) and never calls getAdapter",
  async () => {
    let adapterCalls = 0;
    const response = await handleRequest(request(), {
      verify: () => Promise.resolve(null),
      getAdapter: () => {
        adapterCalls++;
        return null;
      },
    });

    assertEquals(response.status, 401);
    const text = await response.text();
    assertEquals(text, "Unauthorized");
    const contentType = response.headers.get("content-type") ?? "";
    assertEquals(contentType.includes("application/json"), false);
    // Explicit positive check per the doc's parenthetical (§6: "a
    // content-type that is not application/json (text/plain)") — M3 fix
    // round. The earlier assertion only ruled out JSON; this pins the
    // actual expected type rather than any non-JSON type.
    assertEquals(contentType.startsWith("text/plain"), true);
    assertEquals(adapterCalls, 0);
  },
);

Deno.test(
  "F23_A03 verify is called once with the same Request, getAdapter once, verify then getAdapter",
  async () => {
    const calls: string[] = [];
    let verifyArg: Request | null = null;
    const req = request("Bearer good-token");

    const response = await handleRequest(req, {
      verify: (r: Request) => {
        calls.push("verify");
        verifyArg = r;
        return Promise.resolve("uid-123");
      },
      getAdapter: () => {
        calls.push("getAdapter");
        return null;
      },
    });

    assertEquals(calls, ["verify", "getAdapter"]);
    // assertStrictEquals (reference equality), not assertEquals (value
    // equality) — proves the exact same Request object was passed through,
    // not merely an equal-looking one (M1 fix round).
    assertStrictEquals(verifyArg, req);
    assertEquals(response.status, 501);
  },
);

Deno.test(
  "F23_A07 no response body ever contains the verified uid, the bearer token, or the LLM_PROVIDER value",
  async () => {
    const markerUid = "uid-marker-7f3a";
    const markerToken = "tok-marker-91c2";
    const markerProvider = "provider-marker-55d0";

    // M2 fix round: uses the real getLlmAdapter (driven by the real
    // LLM_PROVIDER set below), not an injected `() => null`, so an actual
    // provider-value leak into the 501 body would be caught by this test —
    // an injected null adapter can never leak anything, since it never
    // touches LLM_PROVIDER at all.
    const res501 = await withEnv(markerProvider, () =>
      handleRequest(request(`Bearer ${markerToken}`), {
        verify: () => Promise.resolve(markerUid),
        getAdapter: getLlmAdapter,
      }));
    const body501 = await res501.text();
    assertEquals(body501.includes(markerUid), false);
    assertEquals(body501.includes(markerToken), false);
    assertEquals(body501.includes(markerProvider), false);

    const res401 = await handleRequest(request(`Bearer ${markerToken}`), {
      verify: () => Promise.resolve(null),
      getAdapter: () => null,
    });
    const body401 = await res401.text();
    assertEquals(body401.includes(markerUid), false);
    assertEquals(body401.includes(markerToken), false);
    assertEquals(body401.includes(markerProvider), false);
  },
);

Deno.test(
  "F23_A08 the request body is never read regardless of method/body shape",
  async () => {
    const cases: Array<[string, BodyInit | undefined]> = [
      ["POST", undefined],
      ["POST", "{{not json"],
      ["POST", JSON.stringify({ prompt: "x" })],
      ["GET", undefined],
    ];

    const responses: Response[] = [];
    for (const [method, body] of cases) {
      const req = request("Bearer good-token", { method, body });
      const response = await handleRequest(req, {
        verify: () => Promise.resolve("uid-123"),
        getAdapter: () => null,
      });
      assertEquals(req.bodyUsed, false);
      responses.push(response);
    }

    const bodies = await Promise.all(responses.map((r) => r.json()));
    for (const b of bodies) {
      assertEquals(b, { error: "AI provider not configured yet" });
    }
    for (const r of responses) assertEquals(r.status, 501);
  },
);

// Amended 2026-10-30 (F26): the adapter-present branch now answers for real
// instead of a stub 501. Was: "Adapter-present branch (pending section 13 Q3):
// with getAdapter injected to return a test-double LlmAdapter that records
// calls, handleRequest resolves to a defined Response (never undefined, never
// throws) with status 501, content-type application/json and body deep-equal
// to {"error": "AI stylist not implemented yet"}, and the double's
// generateOutfitSuggestion is called zero times". What still holds: the
// response is defined, and with no request body to act on the provider is not
// called (here: 400, never the retired 501 string).
Deno.test(
  "F23_A09 adapter-present branch answers for real: a bodiless request is a 400 and the provider is never called",
  async () => {
    let generateCalls = 0;
    const doubleAdapter: LlmAdapter = {
      generateOutfitSuggestion: (_prompt: string) => {
        generateCalls++;
        return Promise.resolve("should-not-happen");
      },
    };

    const response = await handleRequest(request("Bearer good-token"), {
      verify: () => Promise.resolve("uid-123"),
      getAdapter: () => doubleAdapter,
      checkUsage: () => Promise.resolve("allowed"),
    });

    assertNotEquals(response, undefined);
    assertEquals(response.status, 400);
    assertEquals(response.headers.get("content-type"), "application/json");
    assertEquals(await response.json(), { error: "Invalid request body" });
    assertEquals(generateCalls, 0);
    assertEquals(
      Deno.readTextFileSync(new URL("./index.ts", import.meta.url)).includes(
        "AI stylist not implemented yet",
      ),
      false,
    );
  },
);

Deno.test(
  "F23_A16 Deno.serve appears only inside the import.meta.main guard, and no test disables the default sanitizers",
  () => {
    // Fix round, Important finding 1: the previous version of this test was
    // a copy of A01 and asserted nothing about the guard itself — changing
    // `if (import.meta.main)` to `if (true)` in index.ts still passed
    // 11/11 under --allow-net, because the leaked Deno.serve listener opens
    // at module load (outside any test body), so Deno's per-test resource
    // sanitizers never see it. This replaces that with a static source
    // scan: every `Deno.serve(` occurrence must fall textually inside the
    // `if (import.meta.main) { ... }` block's braces, and nowhere else.
    const source = Deno.readTextFileSync(new URL("./index.ts", import.meta.url));

    const guardMatch = source.match(/if\s*\(\s*import\.meta\.main\s*\)\s*\{/);
    assertEquals(guardMatch !== null, true, "no `if (import.meta.main) {` guard found");
    const guardOpenBrace = guardMatch!.index! + guardMatch![0].length - 1;

    // Find the guard block's matching closing brace by brace-depth counting.
    let depth = 0;
    let guardCloseBrace = -1;
    for (let i = guardOpenBrace; i < source.length; i++) {
      if (source[i] === "{") depth++;
      else if (source[i] === "}") {
        depth--;
        if (depth === 0) {
          guardCloseBrace = i;
          break;
        }
      }
    }
    assertEquals(guardCloseBrace !== -1, true, "guard block's closing brace not found");

    const serveCallRegex = /Deno\.serve\(/g;
    let match: RegExpExecArray | null;
    let serveCallCount = 0;
    while ((match = serveCallRegex.exec(source)) !== null) {
      serveCallCount++;
      const pos = match.index;
      assertEquals(
        pos > guardOpenBrace && pos < guardCloseBrace,
        true,
        `Deno.serve( at offset ${pos} falls outside the import.meta.main guard block (guard spans ${guardOpenBrace}-${guardCloseBrace})`,
      );
    }
    assertEquals(serveCallCount > 0, true, "expected at least one Deno.serve( call");

    // No test in either F23 suite may disable the sanitizers that make the
    // above matter at runtime too. The forbidden substrings are built by
    // concatenation so this very assertion's own source text never
    // contains them literally (otherwise this test would fail itself).
    const indexTestSource = Deno.readTextFileSync(new URL("./index.test.ts", import.meta.url));
    const adapterTestSource = Deno.readTextFileSync(
      new URL("../_shared/llm-adapter.test.ts", import.meta.url),
    );
    const forbiddenWords = ["sanitize" + "Ops", "sanitize" + "Resources"];
    for (const forbidden of forbiddenWords) {
      assertEquals(indexTestSource.includes(forbidden), false, `index.test.ts must not contain ${forbidden}`);
      assertEquals(
        adapterTestSource.includes(forbidden),
        false,
        `llm-adapter.test.ts must not contain ${forbidden}`,
      );
    }
  },
);

// --- [I] integration tests: real verifyFirebaseToken (local JWKS) ------

async function buildKeyPair() {
  const { publicKey, privateKey } = await generateKeyPair("RS256");
  const jwk = await exportJWK(publicKey);
  jwk.kid = "test-key-1";
  jwk.alg = "RS256";
  jwk.use = "sig";
  const jwks = createLocalJWKSet({ keys: [jwk] });
  return { privateKey, jwks };
}

function signToken(
  privateKey: KeyLike,
  overrides: {
    sub?: string;
    issuer?: string;
    audience?: string;
    expiresInSeconds?: number;
    issuedAtSecondsAgo?: number;
  } = {},
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({})
    .setProtectedHeader({ alg: "RS256", kid: "test-key-1" })
    .setSubject(overrides.sub ?? "uid-abc-123")
    .setIssuer(overrides.issuer ?? `https://securetoken.google.com/${PROJECT_ID}`)
    .setAudience(overrides.audience ?? PROJECT_ID)
    .setIssuedAt(now - (overrides.issuedAtSecondsAgo ?? 0))
    .setExpirationTime(now + (overrides.expiresInSeconds ?? 3600))
    .sign(privateKey);
}

Deno.test(
  "F23_A04 handleRequest wired to the real verifyFirebaseToken (local JWKS) returns 401 for every bad-token shape, getAdapter never called",
  async () => {
    const { privateKey, jwks } = await buildKeyPair();
    const realVerify = (req: Request) =>
      verifyFirebaseToken(req, { projectId: PROJECT_ID, jwks });

    const expiredToken = await signToken(privateKey, {
      expiresInSeconds: -10,
      issuedAtSecondsAgo: 20,
    });
    const wrongAudienceToken = await signToken(privateKey, {
      audience: "some-other-project",
    });
    const forgedKeyPair = await generateKeyPair("RS256");
    const forgedToken = await new SignJWT({})
      .setProtectedHeader({ alg: "RS256", kid: "test-key-1" })
      .setSubject("uid-real-1")
      .setIssuer(`https://securetoken.google.com/${PROJECT_ID}`)
      .setAudience(PROJECT_ID)
      .setIssuedAt()
      .setExpirationTime("1h")
      .sign(forgedKeyPair.privateKey);

    const badAuthHeaders: Array<string | undefined> = [
      undefined,
      "Bearer ",
      "Basic dXNlcjpwYXNz",
      "Bearer not-a-jwt",
      `Bearer ${expiredToken}`,
      `Bearer ${wrongAudienceToken}`,
      `Bearer ${forgedToken}`,
    ];

    for (const authHeader of badAuthHeaders) {
      let adapterCalls = 0;
      const response = await handleRequest(request(authHeader), {
        verify: realVerify,
        getAdapter: () => {
          adapterCalls++;
          return null;
        },
      });
      assertEquals(response.status, 401, `expected 401 for ${JSON.stringify(authHeader)}`);
      assertEquals(await response.text(), "Unauthorized");
      assertEquals(adapterCalls, 0);
    }
  },
);

Deno.test(
  "F23_A05 real verify + real getLlmAdapter with LLM_PROVIDER deleted returns 501 matching A01's exact body",
  async () => {
    const { privateKey, jwks } = await buildKeyPair();
    const token = await signToken(privateKey, { sub: "uid-real-1" });
    const realVerify = (req: Request) =>
      verifyFirebaseToken(req, { projectId: PROJECT_ID, jwks });

    // Fix round, Important finding 2: console.warn is stubbed/captured so
    // this test proves the real getLlmAdapter call actually saw
    // LLM_PROVIDER deleted (the "is not set" reason), not just that a
    // response of the right status code came back. Before this fix,
    // reverting withEnv's `return await fn()` to `return fn()` still
    // passed this test with the wrong warn message logged.
    const { result: response, lines } = await captureWarnAsync(() =>
      withEnv(undefined, () =>
        handleRequest(request(`Bearer ${token}`), {
          verify: realVerify,
          getAdapter: getLlmAdapter,
        })));

    assertEquals(response.status, 501);
    assertEquals(response.headers.get("content-type"), "application/json");
    assertEquals(await response.json(), { error: "AI provider not configured yet" });
    assertEquals(lines.length, 1);
    assertEquals(lines[0].includes("is not set"), true, `unexpected warn line: ${lines[0]}`);
  },
);

Deno.test(
  "F23_A06 the same wiring as A05 returns the identical 501 for LLM_PROVIDER=\"\" and LLM_PROVIDER=\"anthropic\"",
  async () => {
    const { privateKey, jwks } = await buildKeyPair();
    const token = await signToken(privateKey, { sub: "uid-real-1" });
    const realVerify = (req: Request) =>
      verifyFirebaseToken(req, { projectId: PROJECT_ID, jwks });

    // Fix round, Important finding 2: per-case expected warn-line
    // substring, captured via console.warn stubbing (as in A05 and in
    // llm-adapter.test.ts's captureWarn), so each case is proven to have
    // actually driven getLlmAdapter with the env value under test.
    const cases: Array<[string, string]> = [
      ["", "is set but empty"],
      ["anthropic", '"anthropic" is not a registered provider'],
    ];

    for (const [value, expectedSubstring] of cases) {
      const { result: response, lines } = await captureWarnAsync(() =>
        withEnv(value, () =>
          handleRequest(request(`Bearer ${token}`), {
            verify: realVerify,
            getAdapter: getLlmAdapter,
          })));
      assertEquals(response.status, 501);
      assertEquals(response.headers.get("content-type"), "application/json");
      assertEquals(await response.json(), { error: "AI provider not configured yet" });
      assertEquals(lines.length, 1, `expected exactly one warn line for ${JSON.stringify(value)}`);
      assertEquals(
        lines[0].includes(expectedSubstring),
        true,
        `expected warn line for ${JSON.stringify(value)} to include ${JSON.stringify(expectedSubstring)}, got: ${lines[0]}`,
      );
    }
  },
);

// --- static checks -------------------------------------------------------

Deno.test(
  // Amended 2026-10-30 (F26): the handler also imports the usage limiter and the
  // pure contract module. Was: "imports only ../_shared/firebase-auth.ts and
  // ../_shared/llm-adapter.ts". Every other clause is unchanged.
  "F23_A15 ai-stylist/index.ts imports exactly the four allowed modules, no Supabase/provider SDK, no Deno.env access of its own",
  () => {
    // Fix round, Important finding 4: the old regex
    // /^import .*from\s+["'](.+)["'];?$/gm only matched single-line
    // imports and the provider-SDK check only looked for the
    // "supabase-js" substring — a prepended multi-line
    // `import {\n  OpenAI,\n} from "npm:openai@4";` still passed. This
    // version collects every `from "..."` specifier regardless of how
    // many lines the import statement spans, plus side-effect imports and
    // a hard ban on dynamic `import(`, and asserts the resulting set is
    // EXACTLY the two shared modules.
    const source = Deno.readTextFileSync(new URL("./index.ts", import.meta.url));

    assertEquals(/\bimport\s*\(/.test(source), false, "dynamic import( is forbidden");

    const fromSpecifiers = [...source.matchAll(/from\s*["']([^"']+)["']/g)].map((m) => m[1]);
    const sideEffectSpecifiers = [
      ...source.matchAll(/^\s*import\s*["']([^"']+)["']/gm),
    ].map((m) => m[1]);
    const allSpecifiers = new Set([...fromSpecifiers, ...sideEffectSpecifiers]);

    assertEquals(
      allSpecifiers,
      new Set([
        "../_shared/firebase-auth.ts",
        "../_shared/llm-adapter.ts",
        "../_shared/usage-limit.ts",
        "./stylist-contract.ts",
      ]),
      `unexpected import specifier set: ${JSON.stringify([...allSpecifiers])}`,
    );

    assertEquals(source.includes("supabase-js"), false);
    assertEquals(source.includes("Deno.env"), false);
    assertEquals(source.includes("SUPABASE_SERVICE_ROLE_KEY"), false);
    assertEquals(source.includes("SUPABASE_URL"), false);
  },
);

// =========================================================================
// F26 -- real AI stylist handler tests (A01-A18, A28, A34, A40-A44)
// =========================================================================

const POST_URL = "https://example.com/ai-stylist";

function post(body: BodyInit | undefined, extraHeaders: Record<string, string> = {}): Request {
  return new Request(POST_URL, {
    method: "POST",
    headers: { Authorization: "Bearer good-token", ...extraHeaders },
    body,
  });
}

function postJson(body: unknown, extraHeaders: Record<string, string> = {}): Request {
  return post(JSON.stringify(body), extraHeaders);
}

interface Harness {
  calls: string[];
  usageUids: string[];
  prompts: string[];
  deps: HandleRequestDeps;
}

/** Fully injected deps that record every collaborator call. */
function harness(options: {
  uid?: string | null;
  adapter?: LlmAdapter | null;
  text?: unknown;
  usage?: () => Promise<UsageDecision>;
  generate?: (prompt: string) => Promise<string>;
} = {}): Harness {
  const h: Harness = { calls: [], usageUids: [], prompts: [], deps: {} };
  const adapter: LlmAdapter | null = options.adapter !== undefined ? options.adapter : {
    generateOutfitSuggestion: (prompt: string) => {
      h.calls.push("generate");
      h.prompts.push(prompt);
      if (options.generate) return options.generate(prompt);
      return Promise.resolve(("text" in options ? options.text : A04_TEXT) as string);
    },
  };
  h.deps = {
    verify: () => {
      h.calls.push("verify");
      return Promise.resolve(options.uid === undefined ? "uid-1" : options.uid);
    },
    getAdapter: () => {
      h.calls.push("getAdapter");
      return adapter;
    },
    checkUsage: (uid: string) => {
      h.calls.push("checkUsage");
      h.usageUids.push(uid);
      return options.usage ? options.usage() : Promise.resolve("allowed" as const);
    },
  };
  return h;
}

const SIX_MESSAGES = [
  "Request body too large",
  "Invalid request body",
  "Invalid mode",
  "Invalid styling options",
  "Invalid items",
  "Invalid selection",
];

interface InvalidCase {
  group: "body" | "mode" | "options" | "items" | "selection";
  label: string;
  message: string;
  make: () => Request;
}

function markedItems(marker: string, count = 5) {
  return Array.from({ length: count }, (_v, i) => ({
    id: String.fromCharCode(97 + i),
    name: `n-${marker}`,
    category: `c-${marker}`,
    color: `col-${marker}`,
    occasion: `o-${marker}`,
    season: `s-${marker}`,
  }));
}

function markedBody(marker: string, overrides: Record<string, unknown> = {}) {
  return {
    occasion: `occ-${marker}`,
    styleDirection: `dir-${marker}`,
    weather: `wea-${marker}`,
    includeAccessories: true,
    mode: "auto",
    lockedIds: [],
    selectedIds: [],
    items: markedItems(marker),
    junk: marker,
    ...overrides,
  };
}

/** Every invalid-request case of A05-A10, each carrying `marker` in its strings. */
function invalidCases(marker: string): InvalidCase[] {
  const cases: InvalidCase[] = [];
  const add = (
    group: InvalidCase["group"],
    label: string,
    message: string,
    make: () => Request,
  ) => cases.push({ group, label, message, make });
  const json = (group: InvalidCase["group"], label: string, message: string, body: unknown) =>
    add(group, label, message, () => postJson(body));

  // body (A05, A06)
  add("body", "content-length 65537", "Request body too large", () =>
    post("{}", { "content-length": "65537" }));
  add("body", "70000 streamed", "Request body too large", () => post("x".repeat(70000)));
  add("body", "empty post", "Invalid request body", () => post(undefined));
  add("body", "get", "Invalid request body", () =>
    new Request(POST_URL, { method: "GET", headers: { Authorization: "Bearer t" } }));
  for (const text of ["{{not json", "[]", "null", "42", '"text"']) {
    add("body", text, "Invalid request body", () => post(text));
  }
  add("body", "bad utf8", "Invalid request body", () => post(new Uint8Array([0xff, 0xfe])));

  // mode (A07)
  for (const mode of [undefined, "", "AUTO", "chat", 1, null]) {
    json("mode", `mode ${String(mode)}`, "Invalid mode", markedBody(marker, { mode }));
  }

  // options (A08)
  for (const key of ["occasion", "styleDirection", "weather"]) {
    for (const value of [undefined, "", "   ", "x".repeat(61), 7, null]) {
      json(
        "options",
        `${key}=${JSON.stringify(value)}`,
        "Invalid styling options",
        markedBody(marker, { [key]: value }),
      );
    }
  }
  for (const value of [undefined, "true", 1, null]) {
    json(
      "options",
      `includeAccessories=${JSON.stringify(value)}`,
      "Invalid styling options",
      markedBody(marker, { includeAccessories: value }),
    );
  }

  // items (A09)
  const itemCase = (label: string, items: unknown) =>
    json("items", label, "Invalid items", markedBody(marker, { items }));
  itemCase("missing", undefined);
  itemCase("not array", "x");
  itemCase("empty", []);
  itemCase("121 entries", markedItems(marker, 121).map((it, i) => ({ ...it, id: `id-${i}` })));
  itemCase("non-object", [5]);
  itemCase("string entry", ["a"]);
  for (const key of ["id", "name", "category", "color", "occasion", "season"]) {
    const it = markedItems(marker, 2);
    delete (it[0] as Record<string, unknown>)[key];
    itemCase(`missing ${key}`, it);
    const wrongType = markedItems(marker, 2);
    (wrongType[0] as Record<string, unknown>)[key] = 5;
    itemCase(`non-string ${key}`, wrongType);
    const tooLong = markedItems(marker, 2);
    (tooLong[0] as Record<string, unknown>)[key] = "x".repeat(61);
    itemCase(`61-char ${key}`, tooLong);
  }
  for (const badId of ["", "  ", " a"]) {
    const it = markedItems(marker, 2);
    it[0].id = badId;
    itemCase(`id ${JSON.stringify(badId)}`, it);
  }
  const dup = markedItems(marker, 2);
  dup[1].id = dup[0].id;
  itemCase("duplicate ids", dup);

  // selection (A10)
  const sel = (label: string, overrides: Record<string, unknown>) =>
    json("selection", label, "Invalid selection", markedBody(marker, overrides));
  sel("locked missing", { lockedIds: undefined });
  sel("selected missing", { selectedIds: undefined });
  for (const key of ["lockedIds", "selectedIds"]) {
    sel(`${key} not array`, { [key]: "a" });
    sel(`${key} non-string`, { [key]: [1] });
    sel(`${key} unknown id`, { [key]: ["zzz"] });
    sel(`${key} duplicate`, { mode: "match", lockedIds: ["a"], selectedIds: ["a"], [key]: ["a", "a"] });
    sel(`auto ${key} non-empty`, { [key]: ["a"] });
  }
  sel("match selected empty", { mode: "match", selectedIds: [], lockedIds: [] });
  sel("match locked not selected", { mode: "match", selectedIds: ["a"], lockedIds: ["b"] });
  json(
    "selection",
    "match 7 locked",
    "Invalid selection",
    markedBody(marker, {
      mode: "match",
      items: markedItems(marker, 8),
      selectedIds: ["a", "b", "c", "d", "e", "f", "g"],
      lockedIds: ["a", "b", "c", "d", "e", "f", "g"],
    }),
  );
  return cases;
}

async function runInvalid(cases: InvalidCase[], marker = "echo-marker-3b1") {
  for (const c of cases) {
    const h = harness();
    const response = await handleRequest(c.make(), h.deps);
    assertEquals(response.status, 400, c.label);
    assertEquals(response.headers.get("content-type"), "application/json", c.label);
    const text = await response.text();
    assertEquals(JSON.parse(text), { error: c.message }, c.label);
    assertEquals(text.includes(marker), false, c.label);
    // A12: an invalid request never consumes quota or reaches the provider.
    assertEquals(h.calls.includes("checkUsage"), false, `${c.label}: checkUsage`);
    assertEquals(h.calls.includes("generate"), false, `${c.label}: generate`);
  }
}

Deno.test("F26_A01 a bad token is 401 plain-text Unauthorized before anything else runs", async () => {
  const h = harness({ uid: null });
  const req = postJson(validRequestBody());
  const response = await handleRequest(req, h.deps);
  assertEquals(response.status, 401);
  assertEquals(await response.text(), "Unauthorized");
  assertEquals((response.headers.get("content-type") ?? "").startsWith("text/plain"), true);
  assertEquals(h.calls, ["verify"]);
  assertEquals(req.bodyUsed, false);
});

Deno.test("F26_A02 no adapter is 501 for every request shape, body unread, no usage check", async () => {
  const shapes: Array<() => Request> = [
    () => post(undefined),
    () => post("{{not json"),
    () => postJson(validRequestBody()),
    () => new Request(POST_URL, { method: "GET", headers: { Authorization: "Bearer t" } }),
  ];
  for (const make of shapes) {
    const h = harness({ adapter: null });
    const req = make();
    const response = await handleRequest(req, h.deps);
    assertEquals(response.status, 501);
    assertEquals(response.headers.get("content-type"), "application/json");
    assertEquals(await response.json(), { error: "AI provider not configured yet" });
    assertEquals(req.bodyUsed, false);
    assertEquals(h.calls.includes("checkUsage"), false);
  }
});

Deno.test("F26_A03 happy path call order and arguments", async () => {
  const h = harness({ uid: "uid-order" });
  let verifyArg: Request | null = null;
  const inner = h.deps.verify!;
  h.deps.verify = (r: Request) => {
    verifyArg = r;
    return inner(r);
  };
  const req = postJson(validRequestBody());
  const response = await handleRequest(req, h.deps);
  assertEquals(response.status, 200);
  assertEquals(h.calls, ["verify", "getAdapter", "checkUsage", "generate"]);
  assertStrictEquals(verifyArg, req);
  assertEquals(h.usageUids, ["uid-order"]);
  assertEquals(h.prompts.length, 1);
  assertEquals(typeof h.prompts[0], "string");
});

Deno.test("F26_A04 200 returns exactly the validated outfits", async () => {
  const h = harness();
  const response = await handleRequest(postJson(validRequestBody()), h.deps);
  assertEquals(response.status, 200);
  assertEquals(response.headers.get("content-type"), "application/json");
  const body = await response.json();
  assertEquals(body, {
    outfits: [
      { name: "City Day", why: "Crisp and easy.", itemIds: ["a", "b", "c"] },
      { name: "Soft Weekend", why: "Relaxed layers.", itemIds: ["d", "e"] },
    ],
  });
  assertEquals(Object.keys(body), ["outfits"]);
  for (const outfit of body.outfits) {
    assertEquals(Object.keys(outfit).sort(), ["itemIds", "name", "why"]);
  }
});

Deno.test("F26_A05 body size limit: header and streamed, boundary accepted", async () => {
  const h1 = harness();
  const withHeader = post("{}", { "content-length": "65537" });
  const r1 = await handleRequest(withHeader, h1.deps);
  assertEquals(r1.status, 400);
  assertEquals(await r1.json(), { error: "Request body too large" });
  assertEquals(withHeader.bodyUsed, false);
  assertEquals(h1.calls.includes("checkUsage") || h1.calls.includes("generate"), false);

  const h2 = harness();
  const r2 = await handleRequest(post("x".repeat(70000)), h2.deps);
  assertEquals(r2.status, 400);
  assertEquals(await r2.json(), { error: "Request body too large" });
  assertEquals(h2.calls.includes("checkUsage") || h2.calls.includes("generate"), false);

  // Reading stops soon after the limit: a long stream is not drained.
  let pulled = 0;
  const stream = new ReadableStream<Uint8Array>({
    pull(controller) {
      pulled++;
      if (pulled > 1000) {
        controller.close();
        return;
      }
      controller.enqueue(new Uint8Array(1000));
    },
  });
  const streamInit = {
    method: "POST",
    headers: { Authorization: "Bearer t" },
    body: stream,
    duplex: "half",
  } as RequestInit;
  const streamed = new Request(POST_URL, streamInit);
  const r3 = await handleRequest(streamed, harness().deps);
  assertEquals(r3.status, 400);
  assertEquals(pulled < 100, true, `stream pulled ${pulled} chunks`);

  // Exactly 65 536 bytes (trailing spaces) is accepted.
  const exact = JSON.stringify(validRequestBody());
  const padded = exact + " ".repeat(65536 - new TextEncoder().encode(exact).length);
  assertEquals(new TextEncoder().encode(padded).length, 65536);
  const r4 = await handleRequest(post(padded), harness().deps);
  assertEquals(r4.status, 200);
});

Deno.test("F26_A06 undecodable or non-object bodies are Invalid request body", async () => {
  await runInvalid(invalidCases("echo-marker-3b1").filter((c) =>
    c.group === "body" && c.message === "Invalid request body"
  ));
});

Deno.test("F26_A07 Invalid mode, and both modes accepted", async () => {
  await runInvalid(invalidCases("echo-marker-3b1").filter((c) => c.group === "mode"));
  for (const body of [
    validRequestBody({ mode: "auto" }),
    validRequestBody({ mode: "match", selectedIds: ["a", "b"], lockedIds: ["a"] }),
  ]) {
    const response = await handleRequest(postJson(body), harness().deps);
    assertEquals(response.status, 200);
  }
});

Deno.test("F26_A08 Invalid styling options; 60 chars and includeAccessories false accepted", async () => {
  await runInvalid(invalidCases("echo-marker-3b1").filter((c) => c.group === "options"));
  const ok = await handleRequest(
    postJson(validRequestBody({
      occasion: "o".repeat(60),
      styleDirection: "s".repeat(60),
      weather: "w".repeat(60),
      includeAccessories: false,
    })),
    harness().deps,
  );
  assertEquals(ok.status, 200);
});

Deno.test("F26_A09 Invalid items; 120 entries, 60-char fields and empty strings accepted", async () => {
  await runInvalid(invalidCases("echo-marker-3b1").filter((c) => c.group === "items"));

  const full = Array.from({ length: 120 }, (_v, i) => {
    const pad = (s: string) => s.padEnd(60, "x");
    return {
      id: pad(`id${i}-`),
      name: pad("n"),
      category: pad("c"),
      color: pad("k"),
      occasion: pad("o"),
      season: pad("s"),
    };
  });
  const h = harness({ text: JSON.stringify({ outfits: [{ name: "N", why: "W", itemIds: [full[0].id, full[1].id] }] }) });
  const r1 = await handleRequest(postJson(validRequestBody({ items: full })), h.deps);
  assertEquals(r1.status, 200);

  const blank = ["a", "b"].map((id) => ({
    id,
    name: "",
    category: "",
    color: "",
    occasion: "",
    season: "",
  }));
  const r2 = await handleRequest(postJson(validRequestBody({ items: blank })), harness().deps);
  assertEquals(r2.status, 200);
});

Deno.test("F26_A10 Invalid selection; valid match selections accepted", async () => {
  await runInvalid(invalidCases("echo-marker-3b1").filter((c) => c.group === "selection"));
  for (const over of [
    { mode: "match", selectedIds: ["a", "b"], lockedIds: ["a"] },
    { mode: "match", selectedIds: ["a", "b"], lockedIds: [] },
  ]) {
    const response = await handleRequest(postJson(validRequestBody(over)), harness().deps);
    assertEquals(response.status, 200);
  }
});

Deno.test("F26_A11 400 bodies are exactly one of six messages, in the documented order, never echoing input", async () => {
  const marker = "echo-marker-3b1";
  const all = invalidCases(marker);
  await runInvalid(all, marker);
  for (const c of all) assertEquals(SIX_MESSAGES.includes(c.message), true);

  // Order: oversized AND non-JSON -> too large.
  const r1 = await handleRequest(post("{{" + "x".repeat(70000)), harness().deps);
  assertEquals(await r1.json(), { error: "Request body too large" });
  // mode invalid AND items [] -> mode.
  const r2 = await handleRequest(postJson(markedBody(marker, { mode: "chat", items: [] })), harness().deps);
  assertEquals(await r2.json(), { error: "Invalid mode" });
  // options invalid AND selection invalid -> options.
  const r3 = await handleRequest(
    postJson(markedBody(marker, { occasion: "", mode: "auto", lockedIds: ["zzz"] })),
    harness().deps,
  );
  assertEquals(await r3.json(), { error: "Invalid styling options" });
  // items invalid AND selection invalid -> items.
  const r4 = await handleRequest(
    postJson(markedBody(marker, { items: [], lockedIds: ["zzz"] })),
    harness().deps,
  );
  assertEquals(await r4.json(), { error: "Invalid items" });
});

Deno.test("F26_A12 no 400 ever calls checkUsage or generateOutfitSuggestion", async () => {
  // runInvalid asserts this per case; here over every case in one place.
  await runInvalid(invalidCases("echo-marker-3b1"));
});

Deno.test("F26_A13 a limited user gets 429 and the provider is not called", async () => {
  const h = harness({ usage: () => Promise.resolve("limited") });
  const response = await handleRequest(postJson(validRequestBody()), h.deps);
  assertEquals(response.status, 429);
  assertEquals(response.headers.get("content-type"), "application/json");
  assertEquals(await response.json(), { error: "Daily AI styling limit reached" });
  assertEquals(h.calls.includes("generate"), false);
});

Deno.test("F26_A14 provider failures are an opaque 502", async () => {
  const failures: Array<() => Promise<string>> = [
    () => Promise.reject(new LlmProviderError("http_429")),
    () => Promise.reject(new Error("provider-text-marker-77")),
    () => {
      throw new Error("provider-text-marker-77");
    },
  ];
  for (const generate of failures) {
    const h = harness({ generate });
    const { result: response } = await captureConsole(() =>
      handleRequest(postJson(validRequestBody()), h.deps)
    );
    assertEquals(response.status, 502);
    assertEquals(response.headers.get("content-type"), "application/json");
    const text = await response.text();
    assertEquals(JSON.parse(text), { error: "AI styling failed" });
    assertEquals(text.includes("provider-text-marker-77"), false);
    assertEquals(text.includes("http_429"), false);
  }
});

Deno.test("F26_A15 unusable model output is an opaque 502", async () => {
  const outputs = [
    "",
    "not json",
    "[]",
    "{}",
    '{"outfits":"x"}',
    '{"outfits":[]}',
    '{"outfits":[{"name":"A","why":"B","itemIds":["ghost-1","ghost-2"]}]}',
    '{"outfits":[{"name":"A","why":"B","itemIds":["a"]}]}',
  ];
  for (const text of outputs) {
    const h = harness({ text });
    const { result: response, lines } = await captureConsole(() =>
      handleRequest(postJson(validRequestBody()), h.deps)
    );
    assertEquals(response.status, 502, text);
    assertEquals(await response.json(), { error: "AI styling failed" });
    assertEquals(lines.map((l) => l.text), ["ai-stylist: provider output had no valid outfits"]);
  }
});

Deno.test("F26_A16 the handler never throws, fails open on a throwing limiter and survives odd provider values", async () => {
  // checkUsage throwing -> allowed + exactly one console.error.
  const h = harness({ usage: () => Promise.reject(new Error("db down")) });
  const { result, lines } = await captureConsole(() =>
    handleRequest(postJson(validRequestBody()), h.deps)
  );
  assertEquals(result.status, 200);
  assertEquals(lines.filter((l) => l.method === "error").length, 1);

  // Non-string provider values -> 502, never a rejection.
  const weird = { toString: () => { throw new Error("no"); } };
  for (const value of [42, null, weird]) {
    const hh = harness({ text: value });
    const { result: response } = await captureConsole(() =>
      handleRequest(postJson(validRequestBody()), hh.deps)
    );
    assertEquals(response.status, 502);
    assertEquals(await response.json(), { error: "AI styling failed" });
  }

  // An unexpected throw anywhere after auth is an opaque 502, never undefined.
  const throwing = harness();
  throwing.deps.getAdapter = () => {
    throw new TypeError("kaboom");
  };
  const { result: r2, lines: l2 } = await captureConsole(() =>
    handleRequest(postJson(validRequestBody()), throwing.deps)
  );
  assertNotEquals(r2, undefined);
  assertEquals(r2.status, 502);
  assertEquals(l2.map((l) => l.text), ["ai-stylist: unexpected error (TypeError)"]);
});

// --- privacy (A17, A18, A28): real modules, faked network ----------------

const PRIV = {
  uid: "uid-marker-7f3a",
  token: "tok-marker-91c2",
  key: "AIza-key-marker-5c",
  itemName: "item-name-marker-2d",
  occasion: "occasion-marker-4e",
  providerText: "provider-text-marker-77",
};

type Router = (url: string, body: unknown) => Response | Promise<Response>;

/** Replaces globalThis.fetch for `fn`; any URL the router does not handle fails the test. */
async function withFakeNetwork<T>(
  router: Router,
  fn: (calls: RecordedCall[]) => Promise<T>,
): Promise<T> {
  const original = globalThis.fetch;
  const recorded = recordingFetch((call) => router(call.url, call.body));
  globalThis.fetch = recorded.fetch;
  try {
    return await fn(recorded.calls);
  } finally {
    globalThis.fetch = original;
  }
}

const RPC_PATH = "/rest/v1/rpc/ai_usage_try_increment";
const GEMINI_HOST = "generativelanguage.googleapis.com";

function okRouter(rpc: () => Response = () => new Response("true"), gemini?: () => Response): Router {
  return (url) => {
    if (url.includes(RPC_PATH)) return rpc();
    if (url.includes(GEMINI_HOST)) {
      return gemini ? gemini() : new Response(geminiBody(A04_TEXT), { status: 200 });
    }
    throw new Error(`unexpected network call to ${new URL(url).host}`);
  };
}

const WIRED_ENV = {
  LLM_PROVIDER: "gemini",
  GEMINI_API_KEY: PRIV.key,
  GEMINI_MODEL: undefined,
  SUPABASE_URL: "https://db.test",
  SUPABASE_SERVICE_ROLE_KEY: "srk-marker",
  AI_DAILY_LIMIT: undefined,
};

function privBody() {
  const body = validRequestBody({ occasion: PRIV.occasion });
  (body.items as Array<Record<string, string>>)[0].name = PRIV.itemName;
  return body;
}

/** Runs every response status once with the privacy markers in play. */
async function privacyRun() {
  const bodies: Array<{ status: number; text: string }> = [];
  const verifyOk = () => Promise.resolve(PRIV.uid);
  const auth = { Authorization: `Bearer ${PRIV.token}` };

  const { lines } = await captureConsole(async () => {
    const record = async (status: number, response: Response) => {
      assertEquals(response.status, status);
      bodies.push({ status, text: await response.text() });
    };
    const wired = (verify: HandleRequestDeps["verify"] = verifyOk): HandleRequestDeps => ({ verify });

    await withEnvVars(WIRED_ENV, async () => {
      await withFakeNetwork(okRouter(), async () => {
        await record(200, await handleRequest(postJson(privBody(), auth), wired()));
        await record(400, await handleRequest(post("{{", auth), wired()));
        await record(401, await handleRequest(postJson(privBody(), auth), wired(() => Promise.resolve(null))));
      });
      await withFakeNetwork(okRouter(() => new Response("false")), async () => {
        await record(429, await handleRequest(postJson(privBody(), auth), wired()));
      });
      await withFakeNetwork(okRouter(undefined, () => new Response("busy", { status: 503 })), async () => {
        await record(502, await handleRequest(postJson(privBody(), auth), wired()));
      });
      // A provider that throws free text.
      const noisy = harness({ generate: () => Promise.reject(new Error(PRIV.providerText)) });
      await record(502, await handleRequest(postJson(privBody(), auth), noisy.deps));
    });
    await withEnvVars({ ...WIRED_ENV, GEMINI_API_KEY: undefined }, async () => {
      await withFakeNetwork(okRouter(), async () => {
        await record(501, await handleRequest(postJson(privBody(), auth), wired()));
      });
    });
  });
  return { bodies, lines };
}

Deno.test("F26_A17 no response body leaks the uid, its hash, the token, the key or an item name", async () => {
  const { bodies } = await privacyRun();
  assertEquals(bodies.map((b) => b.status).sort(), [200, 400, 401, 429, 501, 502, 502]);
  const hash = await hashUid(PRIV.uid);
  for (const { status, text } of bodies) {
    for (const secret of [PRIV.uid, hash, PRIV.token, PRIV.key, PRIV.providerText]) {
      assertEquals(text.includes(secret), false, `${status} body leaked ${secret}`);
    }
    if (status === 200) assertEquals(text.includes(PRIV.itemName), false);
  }
});

Deno.test("F26_A18 no log line leaks a secret, the prompt or request content", async () => {
  const { lines } = await privacyRun();
  const hash = await hashUid(PRIV.uid);
  assertEquals(lines.length > 0, true);
  const allowed = [
    /^LLM_PROVIDER /,
    /^GEMINI_API_KEY is /,
    /^ai-stylist: provider call failed \([a-z0-9_]+\)$/,
    /^ai-stylist: provider output had no valid outfits$/,
    /^ai-stylist: usage check unavailable; allowing request \(/,
    /^ai-stylist: usage limiter not configured; allowing request$/,
    /^ai-stylist: unexpected error \(/,
  ];
  for (const { text } of lines) {
    for (const secret of [
      PRIV.uid,
      hash,
      PRIV.token,
      PRIV.key,
      PRIV.itemName,
      PRIV.occasion,
      PRIV.providerText,
      "Use only item ids from the ITEMS list",
    ]) {
      assertEquals(text.includes(secret), false, `log leaked ${secret}: ${text}`);
    }
    assertEquals(allowed.some((re) => re.test(text)), true, `unlisted log line: ${text}`);
  }
});

Deno.test("F26_A28 the prompt contains only validated request fields", async () => {
  const markers = {
    uid: "extra-uid-marker",
    email: "extra-email-marker",
    displayName: "extra-name-marker",
    gender: "extra-gender-marker",
    token: "extra-token-marker",
  };
  const itemMarkers = {
    imageUrl: "item-imageurl-marker",
    sourceId: "item-sourceid-marker",
    wears: "item-wears-marker",
    photo: "item-photo-marker",
  };
  const body = validRequestBody({ ...markers });
  for (const item of body.items as Array<Record<string, string>>) Object.assign(item, itemMarkers);

  const h = harness({ uid: PRIV.uid });
  const response = await handleRequest(postJson(body, { Authorization: `Bearer ${PRIV.token}` }), h.deps);
  assertEquals(response.status, 200);
  assertEquals(h.prompts.length, 1);
  const hash = await hashUid(PRIV.uid);
  for (
    const marker of [
      ...Object.values(markers),
      ...Object.values(itemMarkers),
      PRIV.uid,
      hash,
      PRIV.token,
    ]
  ) {
    assertEquals(h.prompts[0].includes(marker), false, marker);
  }
});

// --- [I] real modules, faked network (A41-A44) ---------------------------

async function realVerifyAndToken(sub = "uid-real-1") {
  const { privateKey, jwks } = await buildKeyPair();
  const token = await signToken(privateKey, { sub });
  const verify = (req: Request) => verifyFirebaseToken(req, { projectId: PROJECT_ID, jwks });
  return { token, verify, privateKey };
}

Deno.test("F26_A41 real verify + real getLlmAdapter + real limiter: 200 with RPC then Gemini", async () => {
  const { token, verify } = await realVerifyAndToken();
  const { result, lines } = await captureConsole(() =>
    withEnvVars(WIRED_ENV, () =>
      withFakeNetwork(okRouter(), async (calls) => {
        const response = await handleRequest(postJson(validRequestBody(), { Authorization: `Bearer ${token}` }), {
          verify,
        });
        return { response, calls: [...calls] };
      }))
  );
  assertEquals(result.response.status, 200);
  assertEquals((await result.response.json()).outfits.length, 2);
  assertEquals(result.calls.length, 2);
  assertEquals(result.calls[0].url.endsWith(RPC_PATH), true);
  assertEquals(result.calls[1].url.includes(GEMINI_HOST), true);
  assertEquals((result.calls[0].body as { p_limit: number }).p_limit, 30);
  assertEquals(result.calls[1].headers.get("x-goog-api-key"), PRIV.key);
  assertEquals(result.calls[1].url.includes(PRIV.key), false);
  assertEquals(lines.length, 0);
});

Deno.test("F26_A42 limiter and provider outcomes with the real wiring", async () => {
  const { token, verify } = await realVerifyAndToken();
  const send = () =>
    handleRequest(postJson(validRequestBody(), { Authorization: `Bearer ${token}` }), { verify });

  // RPC false -> 429, no Gemini call.
  await captureConsole(() =>
    withEnvVars(WIRED_ENV, () =>
      withFakeNetwork(okRouter(() => new Response("false")), async (calls) => {
        const response = await send();
        assertEquals(response.status, 429);
        assertEquals(await response.json(), { error: "Daily AI styling limit reached" });
        assertEquals(calls.length, 1);
        assertEquals(calls.some((c) => c.url.includes(GEMINI_HOST)), false);
      }))
  );

  // RPC 500 -> fail open: one console.error, Gemini called, 200.
  const open = await captureConsole(() =>
    withEnvVars(WIRED_ENV, () =>
      withFakeNetwork(okRouter(() => new Response("oops", { status: 500 })), async (calls) => {
        const response = await send();
        return { status: response.status, gemini: calls.some((c) => c.url.includes(GEMINI_HOST)) };
      }))
  );
  assertEquals(open.result, { status: 200, gemini: true });
  assertEquals(open.lines.map((l) => [l.method, l.text]), [
    ["error", "ai-stylist: usage check unavailable; allowing request (http_500)"],
  ]);

  // Gemini 503 -> 502.
  await captureConsole(() =>
    withEnvVars(WIRED_ENV, () =>
      withFakeNetwork(okRouter(undefined, () => new Response("down", { status: 503 })), async () => {
        const response = await send();
        assertEquals(response.status, 502);
        assertEquals(await response.json(), { error: "AI styling failed" });
      }))
  );

  // AI_DAILY_LIMIT=0 -> 429 with zero network calls.
  await withEnvVars({ ...WIRED_ENV, AI_DAILY_LIMIT: "0" }, () =>
    withFakeNetwork(okRouter(), async (calls) => {
      const response = await send();
      assertEquals(response.status, 429);
      assertEquals(calls.length, 0);
    })
  );
});

Deno.test("F26_A43 gemini without a usable key is the F23 501 with zero network calls", async () => {
  const { token, verify } = await realVerifyAndToken();
  const cases: Array<[string | undefined, string]> = [
    [undefined, "GEMINI_API_KEY is not set"],
    ["", "GEMINI_API_KEY is set but empty"],
  ];
  for (const [key, expected] of cases) {
    const { result, lines } = await captureConsole(() =>
      withEnvVars({ ...WIRED_ENV, GEMINI_API_KEY: key }, () =>
        withFakeNetwork(okRouter(), async (calls) => {
          const req = postJson(validRequestBody(), { Authorization: `Bearer ${token}` });
          const response = await handleRequest(req, { verify });
          return { response, calls: calls.length, bodyUsed: req.bodyUsed };
        }))
    );
    assertEquals(result.response.status, 501);
    assertEquals(await result.response.json(), { error: "AI provider not configured yet" });
    assertEquals(result.calls, 0);
    assertEquals(result.bodyUsed, false);
    assertEquals(lines.length, 1);
    assertEquals(lines[0].method, "warn");
    assertEquals(lines[0].text.includes(expected), true, lines[0].text);
  }
});

Deno.test("F26_A44 every bad-token shape is 401 with zero network calls", async () => {
  const { privateKey, verify } = await realVerifyAndToken();
  const expired = await signToken(privateKey, { expiresInSeconds: -10, issuedAtSecondsAgo: 20 });
  const wrongAudience = await signToken(privateKey, { audience: "some-other-project" });
  const forged = await new SignJWT({})
    .setProtectedHeader({ alg: "RS256", kid: "test-key-1" })
    .setSubject("uid-real-1")
    .setIssuer(`https://securetoken.google.com/${PROJECT_ID}`)
    .setAudience(PROJECT_ID)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign((await generateKeyPair("RS256")).privateKey);
  const headers: Array<string | undefined> = [
    undefined,
    "Bearer ",
    "Basic dXNlcjpwYXNz",
    "Bearer not-a-jwt",
    `Bearer ${expired}`,
    `Bearer ${wrongAudience}`,
    `Bearer ${forged}`,
  ];
  await captureConsole(() =>
    withEnvVars(WIRED_ENV, () =>
      withFakeNetwork(okRouter(), async (calls) => {
        for (const header of headers) {
          const req = new Request(POST_URL, {
            method: "POST",
            headers: header === undefined ? {} : { Authorization: header },
            body: JSON.stringify(validRequestBody()),
          });
          const response = await handleRequest(req, { verify });
          assertEquals(response.status, 401, String(header));
          assertEquals(await response.text(), "Unauthorized");
          assertEquals(req.bodyUsed, false);
        }
        assertEquals(calls.length, 0);
      }))
  );
});

// --- static checks (A34, A40) --------------------------------------------

function readSource(relative: string): string {
  return Deno.readTextFileSync(new URL(relative, import.meta.url));
}

function importSpecifiers(source: string): string[] {
  const from = [...source.matchAll(/from\s*["']([^"']+)["']/g)].map((m) => m[1]);
  const bare = [...source.matchAll(/^\s*import\s*["']([^"']+)["']/gm)].map((m) => m[1]);
  return [...from, ...bare];
}

Deno.test("F26_A34 static boundaries between index, contract, adapters and limiter", () => {
  const files = {
    index: readSource("./index.ts"),
    contract: readSource("./stylist-contract.ts"),
    llm: readSource("../_shared/llm-adapter.ts"),
    gemini: readSource("../_shared/gemini-adapter.ts"),
    usage: readSource("../_shared/usage-limit.ts"),
  };

  // llm-adapter.ts: sole import is the provider module (amended F23-A14).
  assertEquals(importSpecifiers(files.llm), ["./gemini-adapter.ts"]);

  // gemini-adapter.ts: exactly one, type-only import; no npm:/jsr:; env + key hygiene.
  assertEquals(importSpecifiers(files.gemini), ["./llm-adapter.ts"]);
  assertEquals(
    files.gemini.includes('import type { LlmAdapter } from "./llm-adapter.ts"'),
    true,
  );
  assertEquals(/\b(npm:|jsr:)/.test(files.gemini), false);
  const envReads = [...files.gemini.matchAll(/Deno\.env\.(\w+)\(\s*["']([^"']+)["']\s*\)/g)]
    .map((m) => `${m[1]}:${m[2]}`);
  assertEquals(envReads.sort(), ["get:GEMINI_API_KEY", "get:GEMINI_MODEL"]);
  assertEquals([...files.gemini.matchAll(/Deno\.env/g)].length, 2);
  assertEquals(files.gemini.includes("key="), false);

  // usage-limit.ts: no import, and the only file naming the Supabase/limit variables.
  assertEquals(importSpecifiers(files.usage), []);
  for (const name of ["SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY", "AI_DAILY_LIMIT"]) {
    for (const [file, source] of Object.entries(files)) {
      assertEquals(source.includes(name), file === "usage", `${name} in ${file}`);
    }
  }

  // stylist-contract.ts: pure.
  assertEquals(importSpecifiers(files.contract), []);
  assertEquals(files.contract.includes("Deno.env"), false);
  assertEquals(files.contract.includes("fetch("), false);

  // index.ts: amended F23-A15 set is asserted by F23_A15; here, no SDK / env dump anywhere.
  for (const source of Object.values(files)) {
    assertEquals(source.includes("supabase-js"), false);
    assertEquals(source.includes("Deno.env.toObject"), false);
  }
});

Deno.test("F26_A40 hygiene: no disabled sanitizers in any function test, and the sources type-check", () => {
  const forbidden = ["sanitize" + "Ops", "sanitize" + "Resources"];
  const roots = ["../_shared/", "./", "../storage-upload-url/"];
  let scanned = 0;
  for (const root of roots) {
    for (const entry of Deno.readDirSync(new URL(root, import.meta.url))) {
      if (!entry.isFile || !entry.name.endsWith(".test.ts")) continue;
      const source = Deno.readTextFileSync(new URL(root + entry.name, import.meta.url));
      for (const word of forbidden) {
        assertEquals(source.includes(word), false, `${entry.name} contains ${word}`);
      }
      scanned++;
    }
  }
  assertEquals(scanned >= 7, true, `only ${scanned} test files scanned`);
});
