// Shared Firebase ID token verification (F15 — storage-upload-url; reused
// unmodified by Task 10's ai-stylist stub later).
//
// Verifies a Firebase Auth ID token against Firebase's published JWKS
// (Google's public signing keys for the "securetoken" service account),
// rather than a per-request REST round trip to Identity Toolkit — faster,
// and `jose`'s `createRemoteJWKSet` caches the key set internally so repeat
// calls do not re-fetch on every request.
//
// A token signed with a key that is not present in the JWKS (forged/
// unrelated token), an expired token, a malformed token, or a missing
// Authorization header all resolve to `null` — this function never throws
// into its caller; the caller's job is just to decide 401 vs proceed.
import {
  createLocalJWKSet,
  createRemoteJWKSet,
  type JWTVerifyGetKey,
} from "npm:jose@5";
import { jwtVerify } from "npm:jose@5";

const DEFAULT_PROJECT_ID = "stylobuddy-b7e46";

function projectId(): string {
  return Deno.env.get("FIREBASE_PROJECT_ID") ?? DEFAULT_PROJECT_ID;
}

function jwksUrl(): string {
  // Note: the path segment is singular "jwk", not "jwks" — the plural form
  // 404s (verified live against the real endpoint while building this).
  return "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
}

let cachedRemoteJwks: JWTVerifyGetKey | null = null;

/** Lazily built, memoized remote JWKS fetcher for the real Google key set. */
function defaultJwks(): JWTVerifyGetKey {
  if (cachedRemoteJwks === null) {
    cachedRemoteJwks = createRemoteJWKSet(new URL(jwksUrl()));
  }
  return cachedRemoteJwks;
}

export interface VerifyFirebaseTokenOptions {
  /** Override for tests; defaults to the real Firebase project id. */
  projectId?: string;
  /**
   * Override for tests; defaults to the real, remote Google JWKS. A test
   * passes a `createLocalJWKSet(...)`-built key set signed by a
   * test-generated key pair instead, so no test ever depends on network
   * access or a real Firebase token.
   */
  jwks?: JWTVerifyGetKey;
}

/**
 * Returns the token's `sub` (the Firebase uid) when `req`'s `Authorization:
 * Bearer <token>` header carries a valid, non-expired Firebase ID token
 * issued for this project; otherwise `null`. Never accepts a
 * caller-supplied uid — the only uid this function ever returns is the one
 * cryptographically encoded in the token itself.
 */
export async function verifyFirebaseToken(
  req: Request,
  options: VerifyFirebaseTokenOptions = {},
): Promise<string | null> {
  const header = req.headers.get("Authorization") ?? req.headers.get("authorization");
  if (!header) return null;
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  if (!match) return null;
  const token = match[1].trim();
  if (!token) return null;

  const resolvedProjectId = options.projectId ?? projectId();
  const jwks = options.jwks ?? defaultJwks();

  try {
    const { payload } = await jwtVerify(token, jwks, {
      issuer: `https://securetoken.google.com/${resolvedProjectId}`,
      audience: resolvedProjectId,
    });
    const uid = typeof payload.sub === "string" ? payload.sub : null;
    return uid && uid.length > 0 ? uid : null;
  } catch {
    // Expired, malformed, wrong audience/issuer, or signed by a key absent
    // from the JWKS (forged token) — all treated identically as "invalid".
    return null;
  }
}

// Re-exported so a test can build its own local JWKS from a test key pair
// without importing `jose` directly (keeps the test's only dependency on
// this module's declared surface).
export { createLocalJWKSet };
