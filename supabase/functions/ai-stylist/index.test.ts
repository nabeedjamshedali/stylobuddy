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
import { handleRequest } from "./index.ts";
import { createLocalJWKSet, verifyFirebaseToken } from "../_shared/firebase-auth.ts";
import { getLlmAdapter, type LlmAdapter } from "../_shared/llm-adapter.ts";

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

Deno.test(
  "F23_A09 adapter-present branch returns a defined 501 and never calls generateOutfitSuggestion",
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
    });

    assertNotEquals(response, undefined);
    assertEquals(response.status, 501);
    assertEquals(response.headers.get("content-type"), "application/json");
    const body = await response.json();
    assertEquals(body, { error: "AI stylist not implemented yet" });
    assertEquals(generateCalls, 0);
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
  "F23_A15 ai-stylist/index.ts imports exactly the two shared modules, no Supabase/provider SDK, no Deno.env access of its own",
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
      new Set(["../_shared/firebase-auth.ts", "../_shared/llm-adapter.ts"]),
      `unexpected import specifier set: ${JSON.stringify([...allSpecifiers])}`,
    );

    assertEquals(source.includes("supabase-js"), false);
    assertEquals(source.includes("Deno.env"), false);
    assertEquals(source.includes("SUPABASE_SERVICE_ROLE_KEY"), false);
    assertEquals(source.includes("SUPABASE_URL"), false);
  },
);
