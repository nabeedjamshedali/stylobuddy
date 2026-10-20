// Interface-only LLM adapter seam (F23, Task 10 of
// docs/superpowers/plans/2026-10-19-backend-wiring.md). No provider is
// registered yet — the LLM provider choice is a standing deferred decision
// (user instruction 2026-10-19, saved memory note "LLM provider pending").
// getLlmAdapter() therefore returns null for every value of LLM_PROVIDER,
// including unset, until a future, out-of-scope task registers a real
// provider. No imports, no fetch, no provider SDK, no implementation of
// LlmAdapter belongs in this file (F23-A14).

export interface LlmAdapter {
  generateOutfitSuggestion(prompt: string): Promise<string>;
}

/**
 * Reads LLM_PROVIDER and always returns null today (zero registered
 * providers). Emits exactly one console.warn per call, with wording that
 * lets an operator tell "unset" / "empty" / "unregistered name" apart in
 * the function logs, even though the client sees the same 501 in every
 * case (F23-A06, A12; docs/features/F23-ai-stylist-stub.md §13 Q4).
 */
export function getLlmAdapter(): LlmAdapter | null {
  const value = Deno.env.get("LLM_PROVIDER");

  if (value === undefined) {
    console.warn("LLM_PROVIDER is not set");
    return null;
  }

  if (value.trim().length === 0) {
    console.warn("LLM_PROVIDER is set but empty");
    return null;
  }

  console.warn(`LLM_PROVIDER "${value}" is not a registered provider`);
  return null;
}
