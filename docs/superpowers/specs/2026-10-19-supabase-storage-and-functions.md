# Supabase Storage & Edge Functions — Milestone 2

Project `stylobuddy` (`dbaeaqyoyilxcuwplvuw`, us-east-1, already created).
Buckets already exist: `user-photos` (private) and `clothing-catalog`
(public, unused this phase — see architecture doc D7).

## 1. Why Supabase needs its own auth, not just Firebase's

Supabase Storage RLS policies evaluate `auth.uid()` **from a Supabase Auth
session**, not an arbitrary string the client claims. Firebase Auth and
Supabase Auth are two separate identity systems; a Firebase ID token does
not make Supabase's `auth.uid()` resolve to anything.

**Decision: sign in to Supabase Auth anonymously, keyed 1:1 to the Firebase
uid, immediately after Firebase sign-in succeeds.** Concretely:
`supabase.auth.signInAnonymously()` on first use per device, then
`supabase.auth.updateUser()` is **not** used for identity — instead the
Storage path itself is prefixed with the **Firebase** uid
(`{firebaseUid}/{itemId}.jpg`), and the Storage RLS policy checks a custom
claim injected via a Supabase Edge Function "token exchange" is **more
machinery than this needs**.

Simpler, chosen approach: **the upload path is signed server-side.** The
Flutter app never uses the Supabase anon key to upload directly. Instead:
1. Flutter calls a tiny Edge Function `storage-upload-url` (service-role
   inside the function, never exposed to the client) with the Firebase ID
   token in the `Authorization` header.
2. The function verifies the Firebase ID token (Firebase Admin REST —
   `https://identitytoolkit.googleapis.com/v1/accounts:lookup` with the
   token, or a cached Google public-key JWT verify; the latter is faster
   and avoids a network round trip per upload — implement JWT verification
   using Firebase's published JWKS, not a REST round trip, per Supabase
   Edge Function best practice for latency).
3. On success, it returns a **signed upload URL** (Supabase Storage
   `createSignedUploadUrl`, service-role only) scoped to exactly
   `{firebaseUid}/{itemId}.jpg`, expiring in 60 seconds.
4. Flutter `PUT`s the file bytes directly to that signed URL (no further
   auth needed — the signature **is** the auth for that one upload).
5. Flutter then calls `WardrobeRepository.updateItem` to write the
   resulting public URL onto the Firestore document.

This keeps the service-role key server-side only (never shipped in the
app), keeps Supabase Storage policies simple (service-role bypasses RLS by
design, so the bucket's RLS can stay fully locked — deny-all for
anon/authenticated roles, since nothing ever uploads except through the
signed-URL function), and needs no second identity system in the client.

**Bucket RLS**: `user-photos` gets one policy — deny all direct
anon/authenticated access (read AND write); reads go through Firestore's
stored `imageUrl` (already a public or long-lived signed URL returned at
upload time — decide **public** bucket-level read with unguessable paths
(`{uid}/{itemId}.jpg`, both already opaque) is acceptable here: no policy
needed for reads, only writes are locked to the signed-upload function).

## 2. Flutter-side flow (`lib/features/wardrobe/repository/`)

- New package: `image_picker` (camera + gallery).
- New file `storage_repository.dart` (shared, since only wardrobe needs
  this today, but it's not wardrobe-specific logic): `uploadWardrobePhoto(
  {required String itemId, required XFile file}) → Future<String>` (returns
  the final URL). Internally: call the Edge Function for a signed URL, `PUT`
  the bytes with `package:http`, return the public URL.
- `ImportCubit` gains a real path: picking "camera"/"gallery" opens
  `image_picker`, the picked file becomes part of a draft; on save, each
  draft with a real picked file calls `uploadWardrobePhoto` before the
  `ClothingItem` (now carrying `imageUrl`) is handed to
  `WardrobeRepository.addItem`. Drafts with no picked file (user backed out
  of the picker, or this is the existing simulated/demo path kept as a
  fallback for the emulator/no-camera case) keep today's `sourceId`-based
  bundled art — **no regression for the simulated path**, it becomes the
  fallback rather than being deleted.
- Upload failure (network, expired signed URL, Edge Function down): the
  draft is still saved as a `ClothingItem` with `imageUrl: null` (falls back
  to bundled art/placeholder) and a toast reports the photo didn't upload —
  never blocks the save, matching existing "never crash" failure philosophy
  (`02-architecture.md` §5).

## 3. Edge Functions — scaffold only (LLM deferred)

**Per explicit user instruction (2026-10-19): no LLM is wired in this
phase.** This section defines the two functions needed now and the shape
future AI work drops into — not the AI logic itself.

### `supabase/functions/storage-upload-url/index.ts`
Described in §1. Real, functional, deployed this phase.

### `supabase/functions/ai-stylist/index.ts`
**Stub only.** Structure:
```ts
import { verifyFirebaseToken } from "../_shared/firebase-auth.ts";
import { getLlmAdapter } from "../_shared/llm-adapter.ts";

Deno.serve(async (req) => {
  const uid = await verifyFirebaseToken(req); // 401 if invalid/missing
  if (!uid) return new Response("Unauthorized", { status: 401 });

  const adapter = getLlmAdapter(); // reads LLM_PROVIDER env var
  if (!adapter) {
    return new Response(
      JSON.stringify({ error: "AI provider not configured yet" }),
      { status: 501, headers: { "content-type": "application/json" } },
    );
  }
  // Real call happens here once a provider is chosen — out of scope now.
});
```
`llm-adapter.ts` defines an interface (`generateOutfitSuggestion(prompt):
Promise<string>`) with zero implementations registered yet — `getLlmAdapter()`
returns `null` until one is. This is the "swappable provider" seam the
architecture doc's D8 and the saved memory note both call for: wiring in
Claude/OpenAI/whatever-is-chosen later is one new file plus one `if` branch
in `getLlmAdapter()`, never a rewrite of this function or any Flutter code.

**No Flutter feature calls `ai-stylist` yet.** `StylistCubit`'s algorithmic
generation (`createMatches`, templates) is untouched this phase — it stays
exactly as the prototype port built it. Wiring the stylist UI to this
function is deferred alongside the LLM provider choice itself.

### `supabase/functions/_shared/firebase-auth.ts`
Shared JWT-verification helper (Firebase's public JWKS, cached), used by
both functions above. Written once in Task 10, reused.

## 4. Deploy

`supabase functions deploy storage-upload-url ai-stylist --project-ref
dbaeaqyoyilxcuwplvuw`, using the access token already supplied (stored at
`~/.secrets/stylobuddy/supabase-access-token.txt`, never in the repo).
Service-role key and any future `LLM_PROVIDER`/provider API key are set via
`supabase secrets set`, never committed, never logged — same secrets
discipline as the Firebase service account key.
