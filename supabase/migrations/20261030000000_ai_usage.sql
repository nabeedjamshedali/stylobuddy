-- F26: per-user daily AI styling cap. Stores only SHA-256(uid) hex, the UTC day and a count.
create table if not exists public.ai_usage (
  uid_hash text    not null check (uid_hash ~ '^[0-9a-f]{64}$'),
  day      date    not null,
  count    integer not null default 0 check (count >= 0),
  primary key (uid_hash, day)
);
alter table public.ai_usage enable row level security;   -- no policies: only service_role (bypasses RLS)
revoke all on table public.ai_usage from public, anon, authenticated;
-- Explicit, so the cap does not depend on Supabase's implicit default privileges (a missing grant would make the limiter fail open).
grant select, insert, update on table public.ai_usage to service_role;

create or replace function public.ai_usage_try_increment(p_uid_hash text, p_day date, p_limit integer)
returns boolean
language plpgsql
set search_path = public
as $$
declare
  new_count integer;
begin
  if p_limit is null or p_limit < 1 then
    return false;
  end if;
  insert into public.ai_usage as u (uid_hash, day, count)
  values (p_uid_hash, p_day, 1)
  on conflict (uid_hash, day) do update
    set count = u.count + 1
    where u.count < p_limit
  returning u.count into new_count;
  return new_count is not null;
end;
$$;
revoke all on function public.ai_usage_try_increment(text, date, integer) from public, anon, authenticated;
grant execute on function public.ai_usage_try_increment(text, date, integer) to service_role;
