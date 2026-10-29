// F26 -- Deno tests for _shared/gemini-adapter.ts (A29-A32). Every fetch is a
// double; nothing here reaches the network.
import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  createGeminiAdapter,
  GEMINI_DEFAULT_MODEL,
  GEMINI_TIMEOUT_MS,
  geminiAdapterFromEnv,
  LlmProviderError,
} from "./gemini-adapter.ts";
import {
  captureConsole,
  geminiBody,
  hangingFetch,
  recordingFetch,
  withEnvVars,
} from "./test-support.ts";

const EXPECTED_SCHEMA = {
  type: "OBJECT",
  properties: {
    outfits: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          name: { type: "STRING" },
          why: { type: "STRING" },
          itemIds: { type: "ARRAY", items: { type: "STRING" } },
        },
        required: ["name", "why", "itemIds"],
      },
    },
  },
  required: ["outfits"],
};

async function codeOf(promise: Promise<unknown>): Promise<string> {
  const error = await assertRejects(() => promise, LlmProviderError);
  return (error as LlmProviderError).code;
}

Deno.test("F26_A29 the Gemini call: URL, method, headers, body, abort signal", async () => {
  const { fetch, calls } = recordingFetch(() => new Response(geminiBody("ok"), { status: 200 }));
  const adapter = createGeminiAdapter({ apiKey: "k-marker", fetch });
  const text = await adapter.generateOutfitSuggestion("P");

  assertEquals(text, "ok");
  assertEquals(calls.length, 1);
  const call = calls[0];
  assertEquals(
    call.url,
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
  );
  assertEquals(call.url.includes("?"), false);
  assertEquals(call.url.includes("k-marker"), false);
  assertEquals(call.init.method, "POST");
  assertEquals(call.headers.get("x-goog-api-key"), "k-marker");
  assertEquals(call.headers.get("content-type"), "application/json");
  assertEquals(call.init.signal instanceof AbortSignal, true);
  assertEquals(call.body, {
    contents: [{ role: "user", parts: [{ text: "P" }] }],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 1024,
      responseMimeType: "application/json",
      responseSchema: EXPECTED_SCHEMA,
      thinkingConfig: { thinkingBudget: 0 },
    },
  });
  assertEquals(Object.keys(call.body as object).sort(), ["contents", "generationConfig"]);
  assertEquals(GEMINI_TIMEOUT_MS, 12000);
  assertEquals(GEMINI_DEFAULT_MODEL, "gemini-2.5-flash");
});

Deno.test("F26_A30 geminiAdapterFromEnv model selection and warnings", async () => {
  const original = globalThis.fetch;
  const modelUrl = async (model: string | undefined) => {
    const { fetch, calls } = recordingFetch(() => new Response(geminiBody("ok"), { status: 200 }));
    globalThis.fetch = fetch;
    try {
      const { lines } = await captureConsole(() =>
        withEnvVars({ GEMINI_API_KEY: "k-marker", GEMINI_MODEL: model }, async () => {
          const adapter = geminiAdapterFromEnv();
          await adapter!.generateOutfitSuggestion("P");
        })
      );
      return { url: calls[0].url, warns: lines.filter((l) => l.method === "warn").map((l) => l.text) };
    } finally {
      globalThis.fetch = original;
    }
  };
  const base = "https://generativelanguage.googleapis.com/v1beta/models/";
  const def = `${base}gemini-2.5-flash:generateContent`;

  let r = await modelUrl(undefined);
  assertEquals([r.url, r.warns], [def, []]);

  r = await modelUrl("gemini-2.5-flash-lite");
  assertEquals([r.url, r.warns], [`${base}gemini-2.5-flash-lite:generateContent`, []]);

  for (const empty of ["", "   "]) {
    r = await modelUrl(empty);
    assertEquals(r.url, def);
    assertEquals(r.warns, ["GEMINI_MODEL is set but empty; using gemini-2.5-flash"]);
  }
  for (const bad of ["../x", "a b", "models/x?key=1", "Gemini-Flash", "a".repeat(65)]) {
    r = await modelUrl(bad);
    assertEquals(r.url, def, bad);
    assertEquals(r.warns, ["GEMINI_MODEL is invalid; using gemini-2.5-flash"], bad);
    for (const w of r.warns) assertEquals(w.includes(bad), false);
  }
});

Deno.test("F26_A31 success extraction concatenates non-thought parts in order", async () => {
  const body = (parts: unknown[]) =>
    JSON.stringify({ candidates: [{ content: { parts }, finishReason: "STOP" }] });
  const run = async (raw: string) => {
    const { fetch } = recordingFetch(() => new Response(raw, { status: 200 }));
    return await createGeminiAdapter({ apiKey: "k", fetch }).generateOutfitSuggestion("P");
  };
  assertEquals(await run(body([{ text: '{"outfits":' }, { text: "[]}" }])), '{"outfits":[]}');
  assertEquals(
    await run(body([{ text: "hidden", thought: true }, { text: "A" }, { text: "B" }])),
    "AB",
  );
});

Deno.test("F26_A32 every failure maps to a fixed LlmProviderError code and leaks nothing", async () => {
  const adapterFor = (respond: () => Response | Promise<Response>, timeoutMs?: number) =>
    createGeminiAdapter({
      apiKey: "k-secret-marker",
      fetch: recordingFetch(respond).fetch,
      timeoutMs,
    });
  const code = (respond: () => Response | Promise<Response>) =>
    codeOf(adapterFor(respond).generateOutfitSuggestion("P"));
  const json = (value: unknown, status = 200) => () =>
    new Response(JSON.stringify(value), { status });

  assertEquals(
    await codeOf(
      createGeminiAdapter({
        apiKey: "k",
        fetch: (() => Promise.reject(new TypeError("boom"))) as typeof fetch,
      }).generateOutfitSuggestion("P"),
    ),
    "network",
  );

  // Timeout: the fetch never resolves; the signal must be aborted.
  const hang = hangingFetch();
  const timeoutCode = await codeOf(
    createGeminiAdapter({ apiKey: "k", fetch: hang.fetch, timeoutMs: 50 })
      .generateOutfitSuggestion("P"),
  );
  assertEquals(timeoutCode, "timeout");
  assertEquals(hang.signals.length, 1);
  assertEquals(hang.signals[0].aborted, true);

  for (const status of [400, 403, 429, 500, 503]) {
    assertEquals(await code(() => new Response("resp-marker-19", { status })), `http_${status}`);
  }
  assertEquals(await code(() => new Response("<html>", { status: 200 })), "bad_response");
  assertEquals(await code(json("a string")), "bad_response");
  assertEquals(await code(json({ promptFeedback: { blockReason: "SAFETY" } })), "blocked");
  assertEquals(await code(json({})), "no_candidates");
  assertEquals(await code(json({ candidates: [] })), "no_candidates");
  assertEquals(await code(json({ candidates: "x" })), "no_candidates");
  for (const reason of ["SAFETY", "MAX_TOKENS", "RECITATION", "OTHER", undefined]) {
    assertEquals(
      await code(json({ candidates: [{ content: { parts: [{ text: "x" }] }, finishReason: reason }] })),
      "finish_reason",
      String(reason),
    );
  }
  const stop = (content: unknown) => json({ candidates: [{ content, finishReason: "STOP" }] });
  assertEquals(await code(stop(undefined)), "empty_text");
  assertEquals(await code(stop({ parts: [] })), "empty_text");
  assertEquals(await code(stop({ parts: [{ text: "" }] })), "empty_text");
  assertEquals(await code(stop({ parts: [{ text: "secret", thought: true }] })), "empty_text");

  // No error leaks the response text or the key.
  for (
    const respond of [
      () => new Response("resp-marker-19", { status: 500 }),
      () => new Response("resp-marker-19 <html>", { status: 200 }),
    ]
  ) {
    const error = await assertRejects(
      () => adapterFor(respond).generateOutfitSuggestion("P"),
      LlmProviderError,
    );
    const shown = `${error.message} ${(error as LlmProviderError).code} ${error.name}`;
    assertEquals(shown.includes("resp-marker-19"), false);
    assertEquals(shown.includes("k-secret-marker"), false);
  }
});

Deno.test("F26_A33 (adapter half) geminiAdapterFromEnv returns null with distinct warnings and never logs the key", async () => {
  const { result, lines } = await captureConsole(() =>
    withEnvVars({ GEMINI_API_KEY: undefined }, () => geminiAdapterFromEnv())
  );
  assertEquals(result, null);
  assertEquals(lines.map((l) => l.text), ["GEMINI_API_KEY is not set"]);

  for (const blank of ["", "   "]) {
    const empty = await captureConsole(() =>
      withEnvVars({ GEMINI_API_KEY: blank }, () => geminiAdapterFromEnv())
    );
    assertEquals(empty.result, null);
    assertEquals(empty.lines.map((l) => l.text), ["GEMINI_API_KEY is set but empty"]);
  }

  const ok = await captureConsole(() =>
    withEnvVars({ GEMINI_API_KEY: "k-marker-0a", GEMINI_MODEL: undefined }, () => geminiAdapterFromEnv())
  );
  assertEquals(ok.result !== null, true);
  assertEquals(ok.lines.length, 0);
});
