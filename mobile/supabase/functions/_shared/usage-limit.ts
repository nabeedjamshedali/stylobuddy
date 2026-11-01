// Per-user daily AI styling cap (F26, docs/features/F26-real-ai-stylist.md
// sections 6.2 and 8). The verified uid is reduced to a SHA-256 hex hash and
// sent only to the ai_usage_try_increment RPC (PostgREST, service-role key).
// Fails open: an unreachable or odd limiter never blocks a user, and it never
// throws into the handler. The uid, its hash and the service-role key are
// never logged.
//
// This is the only module in the ai-stylist import graph that reads
// SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY or AI_DAILY_LIMIT.

export type UsageDecision = "allowed" | "limited";

export const USAGE_DEFAULT_LIMIT = 30;
export const USAGE_RPC_TIMEOUT_MS = 3000;

// PostgreSQL `integer` upper bound; larger configured limits are clamped so
// the RPC argument can never overflow (and fail open by accident).
const MAX_SQL_INTEGER = 2147483647;

/** SHA-256 of the UTF-8 uid as 64 lowercase hex characters. */
export async function hashUid(uid: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(uid));
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export function readDailyLimit(): number {
  const raw = Deno.env.get("AI_DAILY_LIMIT");
  if (raw === undefined) return USAGE_DEFAULT_LIMIT;
  const trimmed = raw.trim();
  if (trimmed.length === 0) {
    console.warn(`AI_DAILY_LIMIT is set but empty; using ${USAGE_DEFAULT_LIMIT}`);
    return USAGE_DEFAULT_LIMIT;
  }
  if (!/^\d+$/.test(trimmed)) {
    console.warn(`AI_DAILY_LIMIT is invalid; using ${USAGE_DEFAULT_LIMIT}`);
    return USAGE_DEFAULT_LIMIT;
  }
  return Math.min(Number(trimmed), MAX_SQL_INTEGER);
}

export interface UsageLimiterDeps {
  fetch?: typeof fetch;
  supabaseUrl?: string;
  serviceRoleKey?: string;
  limit?: number;
  now?: () => Date;
  timeoutMs?: number;
}

function failOpen(reason: string): UsageDecision {
  console.error(`ai-stylist: usage check unavailable; allowing request (${reason})`);
  return "allowed";
}

export async function checkDailyUsage(
  uid: string,
  deps: UsageLimiterDeps = {},
): Promise<UsageDecision> {
  try {
    const limit = deps.limit ?? readDailyLimit();
    if (limit === 0) return "limited"; // global AI off, no database call

    const baseUrl = deps.supabaseUrl ?? Deno.env.get("SUPABASE_URL");
    const key = deps.serviceRoleKey ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!baseUrl?.trim() || !key?.trim()) {
      console.warn("ai-stylist: usage limiter not configured; allowing request");
      return "allowed";
    }

    const doFetch = deps.fetch ?? globalThis.fetch;
    const now = deps.now ?? (() => new Date());
    const body = JSON.stringify({
      p_uid_hash: await hashUid(uid),
      p_day: now().toISOString().slice(0, 10), // UTC calendar day
      p_limit: limit,
    });

    const controller = new AbortController();
    let timer: ReturnType<typeof setTimeout> | undefined;
    const timeout = new Promise<"timeout">((resolve) => {
      timer = setTimeout(() => {
        controller.abort();
        resolve("timeout");
      }, deps.timeoutMs ?? USAGE_RPC_TIMEOUT_MS);
    });

    const attempt = (async (): Promise<UsageDecision | string> => {
      let response: Response;
      try {
        response = await doFetch(`${baseUrl.replace(/\/+$/, "")}/rest/v1/rpc/ai_usage_try_increment`, {
          method: "POST",
          headers: {
            apikey: key,
            Authorization: `Bearer ${key}`,
            "Content-Type": "application/json",
          },
          body,
          signal: controller.signal,
        });
      } catch (_error) {
        return controller.signal.aborted ? "timeout" : "network";
      }
      if (response.status < 200 || response.status > 299) {
        await response.body?.cancel().catch(() => {});
        return `http_${response.status}`;
      }
      let parsed: unknown;
      try {
        parsed = JSON.parse(await response.text());
      } catch (_error) {
        return controller.signal.aborted ? "timeout" : "bad_response";
      }
      if (parsed === true) return "allowed";
      if (parsed === false) return "limited";
      return "bad_response";
    })();

    let outcome: string;
    try {
      outcome = await Promise.race([attempt, timeout]);
    } finally {
      clearTimeout(timer);
    }

    if (outcome === "allowed" || outcome === "limited") return outcome;
    return failOpen(outcome);
  } catch (_error) {
    return failOpen("network");
  }
}
