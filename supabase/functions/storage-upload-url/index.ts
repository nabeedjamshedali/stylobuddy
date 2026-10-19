// Real, functional, deployed Edge Function (F15 — storage doc §1). Issues a
// Supabase Storage signed upload URL scoped to the caller's own Firebase
// uid, never a client-supplied one. The service-role key never leaves this
// function (never shipped to the Flutter client).
import { createClient } from "npm:@supabase/supabase-js@2";
import { verifyFirebaseToken } from "../_shared/firebase-auth.ts";

const BUCKET = "user-photos";

// Defense-in-depth on this auth boundary: `itemId` becomes a path segment
// in Supabase Storage (`{uid}/{itemId}.jpg`), so beyond "non-empty string"
// it is worth a cheap allowlist against path-traversal/control-character
// payloads, even though the uid segment itself is never caller-supplied.
const ITEM_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;

function supabaseUrl(): string {
  const value = Deno.env.get("SUPABASE_URL");
  if (!value) throw new Error("SUPABASE_URL is not configured");
  return value;
}

function serviceRoleKey(): string {
  const value = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!value) throw new Error("SUPABASE_SERVICE_ROLE_KEY is not configured");
  return value;
}

export interface SignedUploadResult {
  uploadUrl: string;
  path: string;
}

/**
 * Uses the official `@supabase/supabase-js` Storage client (service-role,
 * never exposed to the Flutter app) to mint a signed upload URL.
 *
 * Deviation from this project's own storage spec, discovered while
 * integrating against the live project (documented here rather than
 * silently reverted): the spec names a 60-second expiry, but neither the
 * `createSignedUploadUrl` client API nor the underlying Storage REST
 * endpoint (`/storage/v1/object/upload/sign/...`) accepts a caller-supplied
 * expiry for upload URLs — only `createSignedUrl` (downloads) does. Upload
 * URLs use the service's own fixed server-side expiry window instead; this
 * is a real constraint of the Supabase Storage API as it exists today, not
 * an oversight in this implementation. The function still never issues a
 * URL that isn't scoped to the caller's own verified uid, which is the
 * security property this spec requirement was actually protecting.
 */
export async function createSignedUploadUrl(
  path: string,
  deps: { baseUrl?: string; serviceRoleKey?: string } = {},
): Promise<SignedUploadResult | null> {
  const base = deps.baseUrl ?? supabaseUrl();
  const key = deps.serviceRoleKey ?? serviceRoleKey();
  const client = createClient(base, key);

  const { data, error } = await client.storage
    .from(BUCKET)
    .createSignedUploadUrl(path);
  if (error || !data) {
    console.error("createSignedUploadUrl failed", error);
    return null;
  }
  return { uploadUrl: data.signedUrl, path: data.path };
}

export interface HandleRequestDeps {
  verify?: typeof verifyFirebaseToken;
  sign?: typeof createSignedUploadUrl;
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
  const sign = deps.sign ?? createSignedUploadUrl;

  const uid = await verify(req);
  if (!uid) {
    // No signed URL is ever generated for a missing/invalid/expired token.
    return new Response("Unauthorized", { status: 401 });
  }

  let itemId: unknown;
  try {
    const body = await req.json();
    itemId = (body as Record<string, unknown> | null)?.itemId;
  } catch {
    itemId = undefined;
  }
  if (typeof itemId !== "string" || !ITEM_ID_PATTERN.test(itemId)) {
    return jsonResponse({ error: "itemId is required" }, 400);
  }

  // The uid segment is always the token's own uid (never caller-supplied);
  // only itemId comes from the request body.
  const path = `${uid}/${itemId}.jpg`;
  const result = await sign(path);
  if (!result) {
    return jsonResponse({ error: "could not create signed upload URL" }, 500);
  }
  return jsonResponse(result, 200);
}

// Guarded so importing this module from a test (`index.test.ts`) does not
// also start a real listener.
if (import.meta.main) {
  Deno.serve((req) => handleRequest(req));
}
