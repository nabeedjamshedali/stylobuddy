// F26-A45..A49 -- SQL [I] tests for supabase/migrations/20261030000000_ai_usage.sql.
//
// They need a real Postgres. Run through supabase/tests/run_ai_usage_sql_suite.sh,
// which starts a throwaway container and exports AI_USAGE_PG_URL. Without that
// variable every test here is reported as ignored (a skip is not a pass).
// Roles anon / authenticated / service_role are created here the way a
// Supabase project has them (default privileges included, so the migration's
// explicit revokes are what is actually being tested).
import { assertEquals } from "jsr:@std/assert@1";
import postgres from "npm:postgres@3";

const URL_ENV = Deno.env.get("AI_USAGE_PG_URL");
const enabled = URL_ENV !== undefined && URL_ENV !== "";
if (!enabled) {
  console.warn(
    "SKIPPED: AI_USAGE_PG_URL is not set; F26-A45..A49 did not run. " +
      "Use supabase/tests/run_ai_usage_sql_suite.sh.",
  );
}

const MIGRATION = new URL("../migrations/20261030000000_ai_usage.sql", import.meta.url);
const HASH_A = "a".repeat(64);
const HASH_B = "b".repeat(64);

// deno-lint-ignore no-explicit-any
type Sql = any;

async function setup(): Promise<Sql> {
  const sql = postgres(URL_ENV!, { max: 25, onnotice: () => {} });
  await sql.unsafe(`
    do $$ begin
      if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
      if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
      if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin bypassrls; end if;
    end $$;
    grant usage on schema public to anon, authenticated, service_role;
    alter default privileges in schema public grant all on tables to anon, authenticated;
    alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
    drop table if exists public.ai_usage cascade;
  `);
  await sql.unsafe(await Deno.readTextFile(MIGRATION));
  return sql;
}

// deno-lint-ignore no-explicit-any
async function asRole(sql: Sql, role: string, fn: (tx: Sql) => Promise<any>): Promise<any> {
  return await sql.begin(async (tx: Sql) => {
    await tx.unsafe(`set local role ${role}`);
    return await fn(tx);
  });
}

async function increment(
  sql: Sql,
  hash: string,
  day: string,
  limit: number | null,
): Promise<boolean> {
  const rows = await asRole(
    sql,
    "service_role",
    (tx) => tx`select public.ai_usage_try_increment(${hash}, ${day}::date, ${limit}::integer) as ok`,
  );
  return rows[0].ok as boolean;
}

async function countOf(sql: Sql, hash: string, day: string): Promise<number | null> {
  const rows = await sql`select count from public.ai_usage where uid_hash = ${hash} and day = ${day}::date`;
  return rows.length === 0 ? null : (rows[0].count as number);
}

async function sqlState(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    return (error as { code?: string }).code ?? "no-code";
  }
  return "no-error";
}

Deno.test({
  name: "F26_A45 migration is idempotent; table shape, RLS on with no policies, hash check constraint",
  ignore: !enabled,
  fn: async () => {
    const sql = await setup();
    try {
      await sql.unsafe(await Deno.readTextFile(MIGRATION)); // second application
      await sql.unsafe(await Deno.readTextFile(MIGRATION)); // and a third

      const columns = await sql`
        select column_name, data_type, is_nullable, column_default
        from information_schema.columns
        where table_schema = 'public' and table_name = 'ai_usage'
        order by ordinal_position`;
      assertEquals(
        columns.map((c: Record<string, string>) => [c.column_name, c.data_type, c.is_nullable]),
        [["uid_hash", "text", "NO"], ["day", "date", "NO"], ["count", "integer", "NO"]],
      );
      assertEquals(columns[2].column_default, "0");

      const pk = await sql`
        select pg_get_constraintdef(oid) as def from pg_constraint
        where conrelid = 'public.ai_usage'::regclass and contype = 'p'`;
      assertEquals(pk.length, 1);
      assertEquals(pk[0].def, "PRIMARY KEY (uid_hash, day)");

      const rls = await sql`select relrowsecurity from pg_class where oid = 'public.ai_usage'::regclass`;
      assertEquals(rls[0].relrowsecurity, true);
      const policies = await sql`select 1 from pg_policies where schemaname = 'public' and tablename = 'ai_usage'`;
      assertEquals(policies.length, 0);

      assertEquals(
        await sqlState(sql`insert into public.ai_usage (uid_hash, day) values ('XYZ', '2026-10-30')`),
        "23514", // check_violation
      );
      assertEquals(
        await sqlState(
          sql`insert into public.ai_usage (uid_hash, day, count) values (${HASH_A}, '2026-10-30', -1)`,
        ),
        "23514",
      );
    } finally {
      await sql.end({ timeout: 5 });
    }
  },
});

Deno.test({
  name: "F26_A46 service_role increments up to the limit, denied calls do not increment, days and hashes are independent",
  ignore: !enabled,
  fn: async () => {
    const sql = await setup();
    try {
      const results: boolean[] = [];
      for (let i = 0; i < 5; i++) results.push(await increment(sql, HASH_A, "2026-10-30", 3));
      assertEquals(results, [true, true, true, false, false]);
      assertEquals(await countOf(sql, HASH_A, "2026-10-30"), 3);

      assertEquals(await increment(sql, HASH_A, "2026-10-31", 3), true);
      assertEquals(await countOf(sql, HASH_A, "2026-10-31"), 1);
      assertEquals(await increment(sql, HASH_B, "2026-10-30", 3), true);
      assertEquals(await countOf(sql, HASH_B, "2026-10-30"), 1);
      assertEquals(await countOf(sql, HASH_A, "2026-10-30"), 3);
    } finally {
      await sql.end({ timeout: 5 });
    }
  },
});

Deno.test({
  name: "F26_A47 20 concurrent calls on separate connections with p_limit 5 give exactly 5 true, 15 false, count 5",
  ignore: !enabled,
  fn: async () => {
    const sql = await setup();
    try {
      const outcomes = await Promise.all(
        Array.from({ length: 20 }, () => increment(sql, HASH_A, "2026-10-30", 5)),
      );
      assertEquals(outcomes.filter((ok) => ok).length, 5);
      assertEquals(outcomes.filter((ok) => !ok).length, 15);
      assertEquals(await countOf(sql, HASH_A, "2026-10-30"), 5);
    } finally {
      await sql.end({ timeout: 5 });
    }
  },
});

Deno.test({
  name: "F26_A48 p_limit 0, -1 and null return false and write nothing; p_limit 1 allows exactly one",
  ignore: !enabled,
  fn: async () => {
    const sql = await setup();
    try {
      for (const limit of [0, -1, null]) {
        assertEquals(await increment(sql, HASH_A, "2026-10-30", limit), false);
      }
      const rows = await sql`select count(*)::int as n from public.ai_usage`;
      assertEquals(rows[0].n, 0);

      assertEquals(await increment(sql, HASH_A, "2026-10-30", 1), true);
      assertEquals(await increment(sql, HASH_A, "2026-10-30", 1), false);
      assertEquals(await countOf(sql, HASH_A, "2026-10-30"), 1);

      // A refused call with limit 0 also leaves an existing row untouched.
      assertEquals(await increment(sql, HASH_A, "2026-10-30", 0), false);
      assertEquals(await countOf(sql, HASH_A, "2026-10-30"), 1);
    } finally {
      await sql.end({ timeout: 5 });
    }
  },
});

Deno.test({
  name: "F26_A49 anon and authenticated cannot select, insert or execute (42501); service_role can",
  ignore: !enabled,
  fn: async () => {
    const sql = await setup();
    try {
      assertEquals(await increment(sql, HASH_A, "2026-10-30", 5), true);

      for (const role of ["anon", "authenticated"]) {
        assertEquals(
          await sqlState(asRole(sql, role, (tx) => tx`select * from public.ai_usage`)),
          "42501",
          `${role} select`,
        );
        assertEquals(
          await sqlState(
            asRole(
              sql,
              role,
              (tx) =>
                tx`insert into public.ai_usage (uid_hash, day, count) values (${HASH_B}, '2026-10-30', 1)`,
            ),
          ),
          "42501",
          `${role} insert`,
        );
        assertEquals(
          await sqlState(
            asRole(
              sql,
              role,
              (tx) => tx`select public.ai_usage_try_increment(${HASH_A}, '2026-10-30'::date, 5::integer)`,
            ),
          ),
          "42501",
          `${role} execute`,
        );
      }
      // Unchanged by every denied attempt.
      assertEquals(await countOf(sql, HASH_A, "2026-10-30"), 1);
      assertEquals(await countOf(sql, HASH_B, "2026-10-30"), null);

      // service_role: select, insert and execute all work.
      const selected = await asRole(sql, "service_role", (tx) => tx`select * from public.ai_usage`);
      assertEquals(selected.length, 1);
      await asRole(
        sql,
        "service_role",
        (tx) => tx`insert into public.ai_usage (uid_hash, day, count) values (${HASH_B}, '2026-10-30', 1)`,
      );
      assertEquals(await increment(sql, HASH_A, "2026-10-30", 5), true);
      assertEquals(await countOf(sql, HASH_A, "2026-10-30"), 2);
    } finally {
      await sql.end({ timeout: 5 });
    }
  },
});
