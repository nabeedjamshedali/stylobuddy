// LLM adapter seam (F23 Task 10; F26 registers the first provider).
// getLlmAdapter() maps LLM_PROVIDER to an adapter. Exactly one provider is
// registered today: the trimmed, case-sensitive value "gemini", which
// delegates to _shared/gemini-adapter.ts. That module is this file's only
// dependency (amended F23-A14); no network call, no provider SDK and no
// implementation of the interface belong here.

import { geminiAdapterFromEnv } from "./gemini-adapter.ts";

export interface LlmAdapter {
  generateOutfitSuggestion(prompt: string): Promise<string>;
}

/**
 * Reads LLM_PROVIDER and returns the registered adapter, or null. Emits at
 * least one console.warn per null result, with wording that lets an operator
 * tell "unset" / "empty" / "unregistered name" / a provider's own
 * misconfiguration apart in the function logs, even though the client sees
 * the same 501 in every case (F23-A06, A12; F26-A33).
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

  if (value.trim() === "gemini") {
    return geminiAdapterFromEnv();
  }

  console.warn(`LLM_PROVIDER "${value}" is not a registered provider`);
  return null;
}
