// Stub Edge Function (F23, Task 10 — see
// docs/features/F23-ai-stylist-stub.md). Verifies the caller's Firebase ID
// token and then honestly answers 501: no LLM provider is registered, and
// none is chosen (deferred by explicit user instruction, 2026-10-19).
// Mirrors storage-upload-url/index.ts's handleRequest(req, deps) shape
// exactly, including the injectable-dependency pattern and the
// import.meta.main guard, so importing this module from a test never
// starts a real listener.
import { verifyFirebaseToken } from "../_shared/firebase-auth.ts";
import { getLlmAdapter } from "../_shared/llm-adapter.ts";

export interface HandleRequestDeps {
  verify?: typeof verifyFirebaseToken;
  getAdapter?: typeof getLlmAdapter;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export async function handleRequest(
  req: Request,
  deps: HandleRequestDeps = {},
): Promise<Response> {
  const verify = deps.verify ?? verifyFirebaseToken;
  const getAdapter = deps.getAdapter ?? getLlmAdapter;

  const uid = await verify(req);
  if (!uid) {
    // Mirrors storage-upload-url's "never calls sign() for a bad token":
    // getAdapter is never reached for a missing/invalid/expired token.
    return new Response("Unauthorized", { status: 401 });
  }

  // The verified uid is only ever used as the auth gate above (the
  // truthiness check is its one use); it is never echoed, logged or
  // stored (F23-A07).
  const adapter = getAdapter();
  if (!adapter) {
    // Today's permanent production state: zero providers registered.
    return jsonResponse({ error: "AI provider not configured yet" }, 501);
  }

  // Reachable only via test injection today (§13 Q3 of the feature doc): a
  // defined stub response, never a fall-through to an unhandled 500. No
  // request contract exists yet, so generateOutfitSuggestion is never
  // called (F23-A09).
  return jsonResponse({ error: "AI stylist not implemented yet" }, 501);
}

// Guarded so importing this module from a test (index.test.ts) does not
// also start a real listener (F23-A16).
if (import.meta.main) {
  Deno.serve((req) => handleRequest(req));
}
