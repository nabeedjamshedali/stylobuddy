import { assertEquals } from "jsr:@std/assert@1";
import {
  generateKeyPair,
  exportJWK,
  SignJWT,
  type KeyLike,
} from "npm:jose@5";
import { createLocalJWKSet, verifyFirebaseToken } from "./firebase-auth.ts";

const PROJECT_ID = "stylobuddy-b7e46";

async function buildKeyPair() {
  const { publicKey, privateKey } = await generateKeyPair("RS256");
  const jwk = await exportJWK(publicKey);
  jwk.kid = "test-key-1";
  jwk.alg = "RS256";
  jwk.use = "sig";
  const jwks = createLocalJWKSet({ keys: [jwk] });
  return { privateKey, jwks, jwk };
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
  const builder = new SignJWT({})
    .setProtectedHeader({ alg: "RS256", kid: "test-key-1" })
    .setSubject(overrides.sub ?? "uid-abc-123")
    .setIssuer(overrides.issuer ?? `https://securetoken.google.com/${PROJECT_ID}`)
    .setAudience(overrides.audience ?? PROJECT_ID)
    .setIssuedAt(now - (overrides.issuedAtSecondsAgo ?? 0))
    .setExpirationTime(now + (overrides.expiresInSeconds ?? 3600));
  return builder.sign(privateKey);
}

function requestWithAuth(header: string | null): Request {
  const headers = new Headers();
  if (header !== null) headers.set("Authorization", header);
  return new Request("https://example.com/storage-upload-url", {
    method: "POST",
    headers,
  });
}

Deno.test("F15_A17 a well-formed, valid Firebase ID token resolves to the uid encoded in its sub claim", async () => {
  const { privateKey, jwks } = await buildKeyPair();
  const token = await signToken(privateKey, { sub: "uid-real-1" });

  const uid = await verifyFirebaseToken(requestWithAuth(`Bearer ${token}`), {
    projectId: PROJECT_ID,
    jwks,
  });

  assertEquals(uid, "uid-real-1");
});

Deno.test("F15_A18 a missing Authorization header resolves to null", async () => {
  const { jwks } = await buildKeyPair();

  const uid = await verifyFirebaseToken(requestWithAuth(null), {
    projectId: PROJECT_ID,
    jwks,
  });

  assertEquals(uid, null);
});

Deno.test("F15_A19 a malformed token resolves to null", async () => {
  const { jwks } = await buildKeyPair();

  const uid = await verifyFirebaseToken(
    requestWithAuth("Bearer not-a-real-jwt"),
    { projectId: PROJECT_ID, jwks },
  );

  assertEquals(uid, null);
});

Deno.test("F15_A19_expired an expired token resolves to null", async () => {
  const { privateKey, jwks } = await buildKeyPair();
  const token = await signToken(privateKey, {
    sub: "uid-real-1",
    expiresInSeconds: -10,
    issuedAtSecondsAgo: 20,
  });

  const uid = await verifyFirebaseToken(requestWithAuth(`Bearer ${token}`), {
    projectId: PROJECT_ID,
    jwks,
  });

  assertEquals(uid, null);
});

Deno.test(
  "F15_A20 the returned uid always comes from the token's own sub claim, never a caller-suppliable value — two different valid tokens resolve to two different uids",
  async () => {
    const { privateKey, jwks } = await buildKeyPair();
    const tokenA = await signToken(privateKey, { sub: "uid-aaa" });
    const tokenB = await signToken(privateKey, { sub: "uid-bbb" });

    const uidA = await verifyFirebaseToken(requestWithAuth(`Bearer ${tokenA}`), {
      projectId: PROJECT_ID,
      jwks,
    });
    const uidB = await verifyFirebaseToken(requestWithAuth(`Bearer ${tokenB}`), {
      projectId: PROJECT_ID,
      jwks,
    });

    assertEquals(uidA, "uid-aaa");
    assertEquals(uidB, "uid-bbb");
  },
);

Deno.test(
  "F15_A21 a token signed with a key absent from the JWKS (forged/unrelated token) resolves to null even though every other field is well-formed",
  async () => {
    const { jwks } = await buildKeyPair(); // the JWKS the server trusts
    const forgedKeyPair = await generateKeyPair("RS256"); // a different, unrelated key
    const forgedToken = await new SignJWT({})
      .setProtectedHeader({ alg: "RS256", kid: "test-key-1" }) // claims the same kid
      .setSubject("uid-real-1")
      .setIssuer(`https://securetoken.google.com/${PROJECT_ID}`)
      .setAudience(PROJECT_ID)
      .setIssuedAt()
      .setExpirationTime("1h")
      .sign(forgedKeyPair.privateKey);

    const uid = await verifyFirebaseToken(
      requestWithAuth(`Bearer ${forgedToken}`),
      { projectId: PROJECT_ID, jwks },
    );

    assertEquals(uid, null);
  },
);

Deno.test(
  "F15_A19_wrong_audience a token with the wrong audience/project resolves to null",
  async () => {
    const { privateKey, jwks } = await buildKeyPair();
    const token = await signToken(privateKey, {
      sub: "uid-real-1",
      audience: "some-other-project",
    });

    const uid = await verifyFirebaseToken(requestWithAuth(`Bearer ${token}`), {
      projectId: PROJECT_ID,
      jwks,
    });

    assertEquals(uid, null);
  },
);
