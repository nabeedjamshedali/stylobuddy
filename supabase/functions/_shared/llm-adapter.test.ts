// F23 (Task 10) — Deno tests for the interface-only LLM adapter seam.
// Every assertion name is prefixed F23_Axx per
// docs/features/F23-ai-stylist-stub.md §11.
import { assertEquals, assertNotEquals } from "jsr:@std/assert@1";
import * as llmAdapterModule from "./llm-adapter.ts";
import { getLlmAdapter, type LlmAdapter } from "./llm-adapter.ts";

const ENV_KEY = "LLM_PROVIDER";
const CANARY_KEY = "F23_CANARY";
const CANARY_VALUE = "canary-secret-x";

/** Runs `fn` with `LLM_PROVIDER` temporarily set (or deleted), then restores
 * whatever the environment had before — unset or set — per §11's "Tests
 * that change LLM_PROVIDER restore its original state... in a finally
 * block." */
function withEnv<T>(value: string | undefined, fn: () => T): T {
  const original = Deno.env.get(ENV_KEY);
  try {
    if (value === undefined) {
      Deno.env.delete(ENV_KEY);
    } else {
      Deno.env.set(ENV_KEY, value);
    }
    return fn();
  } finally {
    if (original === undefined) {
      Deno.env.delete(ENV_KEY);
    } else {
      Deno.env.set(ENV_KEY, original);
    }
  }
}

/** Captures console.warn lines emitted while `fn` runs, restoring the real
 * console.warn afterward even if `fn` throws. */
function captureWarn(fn: () => void): string[] {
  const lines: string[] = [];
  const original = console.warn;
  console.warn = (...args: unknown[]) => {
    lines.push(args.map((a) => String(a)).join(" "));
  };
  try {
    fn();
  } finally {
    console.warn = original;
  }
  return lines;
}

Deno.test(
  "F23_A10 getLlmAdapter returns null when LLM_PROVIDER is not set in the environment",
  () => {
    withEnv(undefined, () => {
      assertEquals(getLlmAdapter(), null);
    });
  },
);

Deno.test(
  "F23_A11 getLlmAdapter returns null for every LLM_PROVIDER value with zero providers registered",
  () => {
    for (const value of ["", "   ", "anthropic", "openai", "claude", "ANTHROPIC"]) {
      withEnv(value, () => {
        assertEquals(getLlmAdapter(), null, `expected null for ${JSON.stringify(value)}`);
      });
    }
  },
);

Deno.test(
  "F23_A12 missing vs empty vs unregistered LLM_PROVIDER each emit exactly one, pairwise-different console.warn line",
  () => {
    const unsetLines = withEnv(undefined, () => captureWarn(() => getLlmAdapter()));
    assertEquals(unsetLines.length, 1);
    assertEquals(unsetLines[0].includes("LLM_PROVIDER is not set"), true);

    const emptyLines = withEnv("", () => captureWarn(() => getLlmAdapter()));
    assertEquals(emptyLines.length, 1);
    assertEquals(emptyLines[0].includes("LLM_PROVIDER is set but empty"), true);

    const whitespaceLines = withEnv("   ", () => captureWarn(() => getLlmAdapter()));
    assertEquals(whitespaceLines.length, 1);
    assertEquals(whitespaceLines[0].includes("LLM_PROVIDER is set but empty"), true);

    const unregisteredLines = withEnv("anthropic", () => captureWarn(() => getLlmAdapter()));
    assertEquals(unregisteredLines.length, 1);
    assertEquals(
      unregisteredLines[0].includes('LLM_PROVIDER "anthropic" is not a registered provider'),
      true,
    );

    // Pairwise different.
    assertNotEquals(unsetLines[0], emptyLines[0]);
    assertNotEquals(unsetLines[0], unregisteredLines[0]);
    assertNotEquals(emptyLines[0], unregisteredLines[0]);

    // No line leaks an unrelated environment variable's value.
    const otherValueLines = withEnv("provider-marker-55d0", () =>
      captureWarn(() => getLlmAdapter()));
    assertEquals(
      otherValueLines[0].includes("provider-marker-55d0") &&
        !otherValueLines[0].includes("is not a registered provider"),
      false,
    );

    // Fix round, Important finding 3: the check above is a tautology that
    // can never fail — every real warn line always contains "is not a
    // registered provider" (or one of the other fixed phrases), so the
    // second half of that AND is always false regardless of what the
    // first half finds. It still passed when the implementer dumped the
    // ENTIRE process environment via Deno.env.toObject() into the warn
    // call. This sets a dedicated canary env var for the duration of the
    // test and asserts NONE of the captured warn lines across all three
    // null-returning cases contain its value.
    const canaryOriginal = Deno.env.get(CANARY_KEY);
    Deno.env.set(CANARY_KEY, CANARY_VALUE);
    try {
      const canaryUnsetLines = withEnv(undefined, () => captureWarn(() => getLlmAdapter()));
      const canaryEmptyLines = withEnv("", () => captureWarn(() => getLlmAdapter()));
      const canaryUnregisteredLines = withEnv("anthropic", () =>
        captureWarn(() => getLlmAdapter()));
      for (const lines of [canaryUnsetLines, canaryEmptyLines, canaryUnregisteredLines]) {
        for (const line of lines) {
          assertEquals(line.includes(CANARY_VALUE), false, `warn line leaked canary value: ${line}`);
        }
      }
    } finally {
      if (canaryOriginal === undefined) {
        Deno.env.delete(CANARY_KEY);
      } else {
        Deno.env.set(CANARY_KEY, canaryOriginal);
      }
    }
  },
);

Deno.test(
  "F23_A13 LlmAdapter's shape is pinned at the type level under deno test's type-check",
  () => {
    const valid: LlmAdapter = {
      generateOutfitSuggestion: (_prompt: string) => Promise.resolve("ok"),
    };
    void valid;

    // @ts-expect-error - missing generateOutfitSuggestion must not satisfy LlmAdapter
    const missingMethod: LlmAdapter = {};
    void missingMethod;

    const badGenerate = (_prompt: string) => Promise.resolve(42);
    // @ts-expect-error - generateOutfitSuggestion must resolve a string, not a number
    const wrongReturnType: LlmAdapter = { generateOutfitSuggestion: badGenerate };
    void wrongReturnType;

    assertEquals(typeof valid.generateOutfitSuggestion, "function");
  },
);

Deno.test(
  "F23_A14 llm-adapter.ts stays a pure interface-only seam (static check)",
  () => {
    const source = Deno.readTextFileSync(
      new URL("./llm-adapter.ts", import.meta.url),
    );
    assertEquals(/^\s*import\s/m.test(source), false, "no static import statement");
    // Fix round, Important finding 5(c): the old regex only caught the
    // static `import` keyword at line-start, missing the dynamic
    // `import(...)` call form (e.g. `async function sneaky() { return
    // await import("./firebase-auth.ts"); }` previously slipped through).
    assertEquals(/\bimport\s*\(/.test(source), false, "no dynamic import( call");
    assertEquals(source.includes("fetch("), false, "no fetch( call");
    assertEquals(/\b(npm:|jsr:)/.test(source), false, "no npm:/jsr: specifier");

    const occurrences = source.split("generateOutfitSuggestion").length - 1;
    assertEquals(occurrences, 1, "generateOutfitSuggestion must appear exactly once");

    const envGetCalls = [...source.matchAll(/Deno\.env\.get\(\s*(["'`])(.*?)\1\s*\)/g)];
    assertEquals(envGetCalls.length > 0, true, "must read LLM_PROVIDER");
    for (const match of envGetCalls) {
      assertEquals(match[2], "LLM_PROVIDER");
    }

    // Fix round, Important finding 3 (extension): no Deno.env.toObject()
    // call (which would dump the entire process environment), and no
    // Deno.env member access at all other than the `.get("LLM_PROVIDER")`
    // calls already checked above (e.g. Deno.env.toObject, Deno.env.set,
    // Deno.env.delete, Deno.env.has are all forbidden here).
    assertEquals(source.includes("Deno.env.toObject"), false, "no Deno.env.toObject() call");
    const envMemberAccesses = [...source.matchAll(/Deno\.env\.(\w+)/g)].map((m) => m[1]);
    for (const member of envMemberAccesses) {
      assertEquals(member, "get", `unexpected Deno.env.${member} access`);
    }
    assertEquals(envMemberAccesses.length, envGetCalls.length, "Deno.env access count mismatch");

    assertEquals(source.includes("class "), false, "no class implementing LlmAdapter");

    // Fix round, Important finding 5(a): appending `export const
    // extraExport = 1;` to a scratch copy previously still passed this
    // test. The module's runtime export surface must be exactly
    // {getLlmAdapter} (the LlmAdapter interface is erased at runtime, so
    // it never appears in Object.keys of the imported module).
    assertEquals(Object.keys(llmAdapterModule), ["getLlmAdapter"]);

    // Fix round, Important finding 5(b): a static check that `export
    // interface LlmAdapter` is the only OTHER top-level export besides
    // `function getLlmAdapter` — catches an added export (interface,
    // const, class, type, ...) at the source level even though the
    // runtime Object.keys check above can't see type-only exports.
    const topLevelExports = [
      ...source.matchAll(/^export\s+(?:async\s+)?(interface|function|const|let|var|class|type)\s+(\w+)/gm),
    ].map((m) => `${m[1]} ${m[2]}`);
    assertEquals(
      [...topLevelExports].sort(),
      ["function getLlmAdapter", "interface LlmAdapter"],
      `unexpected top-level export set: ${JSON.stringify(topLevelExports)}`,
    );
  },
);
