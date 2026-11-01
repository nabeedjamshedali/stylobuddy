// ai-stylist Edge Function (F23 stub, made real by F26 — see
// docs/features/F26-real-ai-stylist.md section 5.1). Verifies the caller's
// Firebase ID token, resolves the LLM adapter, reads and validates the
// request, applies the per-user daily cap, asks the model and validates what
// comes back, so a response only ever names items the caller sent.
//
// Mirrors storage-upload-url/index.ts's handleRequest(req, deps) shape,
// including the injectable-dependency pattern and the import.meta.main guard,
// so importing this module from a test never starts a real listener.
import { verifyFirebaseToken } from "../_shared/firebase-auth.ts";
import { getLlmAdapter } from "../_shared/llm-adapter.ts";
import { checkDailyUsage, type UsageDecision } from "../_shared/usage-limit.ts";
import {
  BAD_REQUEST,
  buildPrompt,
  MAX_BODY_BYTES,
  parseStylistRequest,
  validateOutfits,
} from "./stylist-contract.ts";

export interface HandleRequestDeps {
  verify?: typeof verifyFirebaseToken;
  getAdapter?: typeof getLlmAdapter;
  checkUsage?: (uid: string) => Promise<UsageDecision>;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function badRequest(message: string): Response {
  return jsonResponse({ error: message }, 400);
}

const PROVIDER_FAILED = { error: "AI styling failed" };

/** A safe, fixed-vocabulary label for a thrown value; never its message. */
function providerErrorCode(error: unknown): string {
  if (error instanceof Error && error.name === "LlmProviderError") {
    const code = (error as Error & { code?: unknown }).code;
    if (typeof code === "string" && /^[a-z0-9_]{1,32}$/.test(code)) return code;
  }
  return "unknown";
}

function errorName(error: unknown): string {
  if (error instanceof Error && /^[A-Za-z0-9_]{1,40}$/.test(error.name)) return error.name;
  return "unknown";
}

/**
 * Reads the body without ever buffering more than MAX_BODY_BYTES + one chunk.
 * Returns the decoded text, or "tooLarge" / "invalid" for the 400 messages.
 */
async function readBody(req: Request): Promise<string | "tooLarge" | "invalid"> {
  const declared = req.headers.get("content-length");
  if (declared !== null && Number(declared) > MAX_BODY_BYTES) return "tooLarge";

  const chunks: Uint8Array[] = [];
  let total = 0;
  if (req.body !== null) {
    const reader = req.body.getReader();
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > MAX_BODY_BYTES) {
        await reader.cancel().catch(() => undefined);
        return "tooLarge";
      }
      chunks.push(value);
    }
  }

  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch (_error) {
    return "invalid";
  }
}

export async function handleRequest(
  req: Request,
  deps: HandleRequestDeps = {},
): Promise<Response> {
  const verify = deps.verify ?? verifyFirebaseToken;
  const getAdapter = deps.getAdapter ?? getLlmAdapter;
  const checkUsage = deps.checkUsage ?? checkDailyUsage;

  try {
    // 1. Auth. A bad token never reaches the adapter, the limiter or the body.
    const uid = await verify(req);
    if (!uid) return new Response("Unauthorized", { status: 401 });

    // 2. Provider configured? (F23's 501; the body stays unread.)
    const adapter = getAdapter();
    if (!adapter) return jsonResponse({ error: "AI provider not configured yet" }, 501);

    // 3. Body.
    const text = await readBody(req);
    if (text === "tooLarge") return badRequest(BAD_REQUEST.tooLarge);
    if (text === "invalid") return badRequest(BAD_REQUEST.body);
    let json: unknown;
    try {
      json = JSON.parse(text);
    } catch (_error) {
      return badRequest(BAD_REQUEST.body);
    }

    // 4. Request contract.
    const parsed = parseStylistRequest(json);
    if (!parsed.ok) return badRequest(parsed.error);
    const request = parsed.request;

    // 5. Daily cap. A limiter that throws counts as "allowed" (fail open).
    let decision: UsageDecision;
    try {
      decision = await checkUsage(uid);
    } catch (_error) {
      console.error("ai-stylist: usage check unavailable; allowing request (unexpected)");
      decision = "allowed";
    }
    if (decision === "limited") {
      return jsonResponse({ error: "Daily AI styling limit reached" }, 429);
    }

    // 6. Ask the model.
    let raw: unknown;
    try {
      raw = await adapter.generateOutfitSuggestion(buildPrompt(request));
    } catch (error) {
      console.error(`ai-stylist: provider call failed (${providerErrorCode(error)})`);
      return jsonResponse(PROVIDER_FAILED, 502);
    }

    // 7. Validate what came back.
    const outfits = typeof raw === "string" ? validateOutfits(raw, request) : [];
    if (outfits.length === 0) {
      console.error("ai-stylist: provider output had no valid outfits");
      return jsonResponse(PROVIDER_FAILED, 502);
    }

    // 8. Success.
    return jsonResponse({ outfits }, 200);
  } catch (error) {
    console.error(`ai-stylist: unexpected error (${errorName(error)})`);
    return jsonResponse(PROVIDER_FAILED, 502);
  }
}

// Guarded so importing this module from a test (index.test.ts) does not
// also start a real listener (F23-A16).
if (import.meta.main) {
  Deno.serve((req) => handleRequest(req));
}
