// F26 -- Deno tests for _shared/usage-limit.ts (A35-A39). No network: every
// fetch is a double.
import { assertEquals } from "jsr:@std/assert@1";
import {
  checkDailyUsage,
  hashUid,
  readDailyLimit,
  USAGE_RPC_TIMEOUT_MS,
} from "./usage-limit.ts";
import { captureConsole, hangingFetch, recordingFetch, withEnvVars } from "./test-support.ts";

const UID = "uid-marker-7f3a";
const BASE = {
  supabaseUrl: "https://db.test",
  serviceRoleKey: "srk-marker",
  limit: 30,
  now: () => new Date("2026-10-30T23:59:59Z"),
};

Deno.test("F26_A35 hashUid is lowercase SHA-256 hex", async () => {
  assertEquals(
    await hashUid("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  );
  assertEquals(/^[0-9a-f]{64}$/.test(await hashUid("any uid / ünïcode 👗")), true);
  assertEquals((await hashUid("uid-1")) !== (await hashUid("uid-2")), true);
});

Deno.test("F26_A36 checkDailyUsage posts the RPC with the hash, UTC day and limit", async () => {
  const { fetch, calls } = recordingFetch();
  const decision = await checkDailyUsage(UID, { ...BASE, fetch });
  assertEquals(decision, "allowed");
  assertEquals(calls.length, 1);
  const call = calls[0];
  assertEquals(call.url, "https://db.test/rest/v1/rpc/ai_usage_try_increment");
  assertEquals(call.init.method, "POST");
  assertEquals(call.headers.get("apikey"), "srk-marker");
  assertEquals(call.headers.get("authorization"), "Bearer srk-marker");
  assertEquals(call.headers.get("content-type"), "application/json");
  assertEquals(call.body, {
    p_uid_hash: await hashUid(UID),
    p_day: "2026-10-30",
    p_limit: 30,
  });
  assertEquals(call.url.includes(UID), false);
  assertEquals(String(call.init.body).includes(UID), false);

  // The day is the UTC day: 23:30 at UTC-5 is already 2026-10-31 in UTC.
  const next = recordingFetch();
  await checkDailyUsage(UID, {
    ...BASE,
    fetch: next.fetch,
    now: () => new Date("2026-10-30T23:30:00-05:00"),
  });
  assertEquals((next.calls[0].body as { p_day: string }).p_day, "2026-10-31");
});

Deno.test("F26_A37 decision mapping, and every other outcome fails open with one logged reason", async () => {
  const answer = (body: string, status = 200) => recordingFetch(() => new Response(body, { status }));
  assertEquals(await checkDailyUsage(UID, { ...BASE, fetch: answer("true").fetch }), "allowed");
  assertEquals(await checkDailyUsage(UID, { ...BASE, fetch: answer("false").fetch }), "limited");

  const expectFailOpen = async (deps: Parameters<typeof checkDailyUsage>[1], reason: string) => {
    const { result, lines } = await captureConsole(() => checkDailyUsage(UID, deps));
    assertEquals(result, "allowed", reason);
    assertEquals(lines.length, 1, reason);
    assertEquals(lines[0].method, "error");
    assertEquals(
      lines[0].text,
      `ai-stylist: usage check unavailable; allowing request (${reason})`,
    );
    const hash = await hashUid(UID);
    for (const secret of [UID, hash, "srk-marker"]) assertEquals(lines[0].text.includes(secret), false);
  };

  await expectFailOpen(
    { ...BASE, fetch: (() => Promise.reject(new TypeError("down"))) as typeof fetch },
    "network",
  );
  await expectFailOpen({ ...BASE, fetch: hangingFetch().fetch, timeoutMs: 50 }, "timeout");
  for (const status of [401, 404, 500]) {
    await expectFailOpen({ ...BASE, fetch: answer("{}", status).fetch }, `http_${status}`);
  }
  for (const body of ["null", '"true"', "{}", "1", "not json"]) {
    await expectFailOpen({ ...BASE, fetch: answer(body).fetch }, "bad_response");
  }
  assertEquals(USAGE_RPC_TIMEOUT_MS, 3000);
});

Deno.test("F26_A38 readDailyLimit parsing; limit 0 means AI off with no fetch", async () => {
  const read = async (value: string | undefined) => {
    const { result, lines } = await captureConsole(() =>
      withEnvVars({ AI_DAILY_LIMIT: value }, () => readDailyLimit())
    );
    return { value: result, warns: lines.filter((l) => l.method === "warn").map((l) => l.text) };
  };
  assertEquals(await read(undefined), { value: 30, warns: [] });
  for (const empty of ["", "  "]) {
    assertEquals(await read(empty), {
      value: 30,
      warns: ["AI_DAILY_LIMIT is set but empty; using 30"],
    });
  }
  for (const bad of ["abc", "-1", "2.5", "1e3"]) {
    assertEquals(await read(bad), { value: 30, warns: ["AI_DAILY_LIMIT is invalid; using 30"] }, bad);
  }
  assertEquals((await read("5")).value, 5);
  assertEquals((await read(" 7 ")).value, 7);
  assertEquals((await read("0")).value, 0);
  // Larger than a SQL integer is clamped rather than overflowing the RPC.
  assertEquals((await read("99999999999999")).value, 2147483647);

  const { fetch, calls } = recordingFetch();
  assertEquals(await checkDailyUsage(UID, { ...BASE, limit: 0, fetch }), "limited");
  assertEquals(calls.length, 0);
  // The env path: AI_DAILY_LIMIT=0 with no deps limit.
  const viaEnv = await withEnvVars({ AI_DAILY_LIMIT: "0" }, () =>
    checkDailyUsage(UID, { ...BASE, limit: undefined, fetch })
  );
  assertEquals(viaEnv, "limited");
  assertEquals(calls.length, 0);
});

Deno.test("F26_A39 an unconfigured limiter allows the request, makes no call and warns once", async () => {
  const cases: Array<Record<string, string | undefined>> = [
    { SUPABASE_URL: undefined, SUPABASE_SERVICE_ROLE_KEY: "srk-marker", AI_DAILY_LIMIT: undefined },
    { SUPABASE_URL: "https://db.test", SUPABASE_SERVICE_ROLE_KEY: "", AI_DAILY_LIMIT: undefined },
  ];
  for (const env of cases) {
    const { fetch, calls } = recordingFetch();
    const { result, lines } = await captureConsole(() =>
      withEnvVars(env, () => checkDailyUsage(UID, { fetch }))
    );
    assertEquals(result, "allowed");
    assertEquals(calls.length, 0);
    assertEquals(lines.map((l) => [l.method, l.text]), [
      ["warn", "ai-stylist: usage limiter not configured; allowing request"],
    ]);
  }
});
