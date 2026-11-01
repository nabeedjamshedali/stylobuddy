// Test-only helpers shared by the F26 Deno suites. Not imported by any
// function entry point, so it is never part of a deployed bundle.

export type ConsoleMethod = "log" | "info" | "warn" | "error" | "debug";
export interface CapturedLine {
  method: ConsoleMethod;
  text: string;
}

const METHODS: ConsoleMethod[] = ["log", "info", "warn", "error", "debug"];

/** Captures every console method while `fn` runs; always restores them. */
export async function captureConsole<T>(
  fn: () => T | Promise<T>,
): Promise<{ result: T; lines: CapturedLine[] }> {
  const lines: CapturedLine[] = [];
  const originals = METHODS.map((m) => console[m]);
  for (const method of METHODS) {
    console[method] = (...args: unknown[]) => {
      lines.push({ method, text: args.map((a) => String(a)).join(" ") });
    };
  }
  try {
    const result = await fn();
    return { result, lines };
  } finally {
    METHODS.forEach((m, i) => {
      console[m] = originals[i];
    });
  }
}

/** Sets (string) or deletes (undefined) env vars for `fn`, restoring each in finally. */
export async function withEnvVars<T>(
  vars: Record<string, string | undefined>,
  fn: () => T | Promise<T>,
): Promise<T> {
  const originals = new Map<string, string | undefined>();
  for (const key of Object.keys(vars)) originals.set(key, Deno.env.get(key));
  try {
    for (const [key, value] of Object.entries(vars)) {
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
    return await fn();
  } finally {
    for (const [key, value] of originals) {
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
  }
}

export interface RecordedCall {
  url: string;
  init: RequestInit;
  headers: Headers;
  body: unknown;
}

/** A fetch double: records every call and answers via `respond` (default 200 `true`). */
export function recordingFetch(
  respond: (call: RecordedCall) => Response | Promise<Response> = () =>
    new Response("true", { status: 200 }),
): { fetch: typeof fetch; calls: RecordedCall[] } {
  const calls: RecordedCall[] = [];
  const fake = (input: string | URL | Request, init: RequestInit = {}) => {
    const rawBody = typeof init.body === "string" ? init.body : undefined;
    let body: unknown = rawBody;
    try {
      body = rawBody === undefined ? undefined : JSON.parse(rawBody);
    } catch (_error) {
      body = rawBody;
    }
    const call: RecordedCall = {
      url: String(input),
      init,
      headers: new Headers(init.headers),
      body,
    };
    calls.push(call);
    return Promise.resolve(respond(call));
  };
  return { fetch: fake as typeof fetch, calls };
}

/** A fetch that never settles by itself (for timeout tests). */
export function hangingFetch(): { fetch: typeof fetch; signals: AbortSignal[] } {
  const signals: AbortSignal[] = [];
  const fake = (_input: string | URL | Request, init: RequestInit = {}) => {
    if (init.signal) signals.push(init.signal);
    return new Promise<Response>(() => {});
  };
  return { fetch: fake as typeof fetch, signals };
}

export function geminiBody(text: string, finishReason = "STOP"): string {
  return JSON.stringify({
    candidates: [{ content: { parts: [{ text }] }, finishReason }],
  });
}

export const SEARCH_ITEMS = ["a", "b", "c", "d", "e"].map((id) => ({
  id,
  name: `Item ${id}`,
  category: "Shirts",
  color: "White",
  occasion: "Office",
  season: "All season",
}));

/** A valid auto-mode request body (section 6.1) with 5 items a..e. */
export function validRequestBody(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    occasion: "Office",
    styleDirection: "Smart casual",
    weather: "Mild / all season",
    includeAccessories: true,
    mode: "auto",
    lockedIds: [],
    selectedIds: [],
    items: SEARCH_ITEMS.map((item) => ({ ...item })),
    ...overrides,
  };
}

export const A04_TEXT =
  '{"outfits":[{"name":"City Day","why":"Crisp and easy.","itemIds":["a","b","c"]},{"name":"Soft Weekend","why":"Relaxed layers.","itemIds":["d","e"]}]}';
