// Gemini provider for the LlmAdapter seam (F26, docs/features/F26-real-ai-stylist.md
// section 6.2). Plain REST with the platform fetch: no SDK, no npm/jsr
// dependency. The API credential travels only in the x-goog-api-key request
// header; it is never placed in a URL, an error, or a log line.
//
// This module never parses outfits: it returns the model's text, and the
// handler validates it. Every failure is a LlmProviderError carrying one of a
// fixed set of codes (never the provider's response text).
import type { LlmAdapter } from "./llm-adapter.ts";

export const GEMINI_DEFAULT_MODEL = "gemini-2.5-flash";
export const GEMINI_TIMEOUT_MS = 12000;

const GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models";
const MODEL_PATTERN = /^[a-z0-9][a-z0-9.-]{0,63}$/;

export class LlmProviderError extends Error {
  readonly code: string;

  constructor(code: string) {
    super(code);
    this.name = "LlmProviderError";
    this.code = code;
  }
}

export interface GeminiAdapterOptions {
  apiKey: string;
  model?: string;
  fetch?: typeof fetch;
  timeoutMs?: number;
}

const RESPONSE_SCHEMA = {
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

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** Maps a parsed 2xx Gemini body to the model's text, or throws. */
function extractText(parsed: unknown): string {
  if (!isRecord(parsed)) throw new LlmProviderError("bad_response");

  const feedback = parsed["promptFeedback"];
  if (
    isRecord(feedback) &&
    feedback["blockReason"] !== undefined &&
    feedback["blockReason"] !== null
  ) {
    throw new LlmProviderError("blocked");
  }

  const candidates = parsed["candidates"];
  if (!Array.isArray(candidates) || candidates.length === 0) {
    throw new LlmProviderError("no_candidates");
  }

  const first = candidates[0];
  if (!isRecord(first) || first["finishReason"] !== "STOP") {
    throw new LlmProviderError("finish_reason");
  }

  const content = first["content"];
  const parts = isRecord(content) ? content["parts"] : undefined;
  let text = "";
  if (Array.isArray(parts)) {
    for (const part of parts) {
      if (!isRecord(part) || part["thought"] === true) continue;
      const piece = part["text"];
      if (typeof piece === "string") text += piece;
    }
  }
  if (text === "") throw new LlmProviderError("empty_text");
  return text;
}

export function createGeminiAdapter(options: GeminiAdapterOptions): LlmAdapter {
  const apiKey = options.apiKey;
  const model = options.model ?? GEMINI_DEFAULT_MODEL;
  const timeoutMs = options.timeoutMs ?? GEMINI_TIMEOUT_MS;
  const url = `${GEMINI_BASE_URL}/${encodeURIComponent(model)}:generateContent`;

  async function call(prompt: string, signal: AbortSignal): Promise<string> {
    // Resolved per call so a test (or the platform) can swap globalThis.fetch.
    const doFetch = options.fetch ?? globalThis.fetch;
    const body = JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1024,
        responseMimeType: "application/json",
        responseSchema: RESPONSE_SCHEMA,
        thinkingConfig: { thinkingBudget: 0 },
      },
    });

    let response: Response;
    try {
      response = await doFetch(url, {
        method: "POST",
        headers: {
          "x-goog-api-key": apiKey,
          "content-type": "application/json",
        },
        body,
        signal,
      });
    } catch (_error) {
      throw new LlmProviderError(signal.aborted ? "timeout" : "network");
    }

    if (response.status < 200 || response.status > 299) {
      throw new LlmProviderError(`http_${response.status}`);
    }

    let raw: string;
    try {
      raw = await response.text();
    } catch (_error) {
      throw new LlmProviderError(signal.aborted ? "timeout" : "network");
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch (_error) {
      throw new LlmProviderError("bad_response");
    }
    return extractText(parsed);
  }

  return {
    async generateOutfitSuggestion(prompt: string): Promise<string> {
      const controller = new AbortController();
      let timer: ReturnType<typeof setTimeout> | undefined;
      const timeout = new Promise<never>((_resolve, reject) => {
        timer = setTimeout(() => {
          controller.abort();
          reject(new LlmProviderError("timeout"));
        }, timeoutMs);
      });
      try {
        return await Promise.race([call(prompt, controller.signal), timeout]);
      } finally {
        clearTimeout(timer);
      }
    },
  };
}

/**
 * Builds the adapter from GEMINI_API_KEY / GEMINI_MODEL, the only environment
 * reads in this file. Returns null (with a warning that never contains the
 * key or a rejected model value) when the key is missing or empty.
 */
export function geminiAdapterFromEnv(): LlmAdapter | null {
  const rawKey = Deno.env.get("GEMINI_API_KEY");
  if (rawKey === undefined) {
    console.warn("GEMINI_API_KEY is not set");
    return null;
  }
  const apiKey = rawKey.trim();
  if (apiKey.length === 0) {
    console.warn("GEMINI_API_KEY is set but empty");
    return null;
  }

  let model = GEMINI_DEFAULT_MODEL;
  const rawModel = Deno.env.get("GEMINI_MODEL");
  if (rawModel !== undefined) {
    const trimmed = rawModel.trim();
    if (trimmed.length === 0) {
      console.warn(`GEMINI_MODEL is set but empty; using ${GEMINI_DEFAULT_MODEL}`);
    } else if (!MODEL_PATTERN.test(trimmed)) {
      console.warn(`GEMINI_MODEL is invalid; using ${GEMINI_DEFAULT_MODEL}`);
    } else {
      model = trimmed;
    }
  }
  return createGeminiAdapter({ apiKey, model });
}
