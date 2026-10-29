#!/usr/bin/env bash
# Runs the F26 SQL [I] tests (F26-A45..A49, supabase/tests/ai_usage.test.ts)
# against a throwaway local Postgres container with the migration applied.
# Nothing here touches the live Supabase project.
#
# Like scripts/run_firestore_rules_suite.sh this is the ONE documented way to
# run the suite. When Docker is unavailable it prints a clear SKIPPED message
# and exits 0. A skip is NOT a pass: A45-A49 stay unverified until the suite
# has actually run (feature doc section 13 Q4).
#
#   bash supabase/tests/run_ai_usage_sql_suite.sh
#
# Environment: POSTGRES_IMAGE (default postgres:17) overrides the image.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

IMAGE="${POSTGRES_IMAGE:-postgres:17}"
NAME="stylobuddy-ai-usage-test-$$"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIPPED: Docker is not available; F26-A45..A49 (SQL tests) did NOT run." >&2
  echo "         Install/start Docker and re-run, or run them against a local Supabase stack." >&2
  exit 0
fi
if ! command -v deno >/dev/null 2>&1; then
  echo "SKIPPED: deno is not on PATH; F26-A45..A49 (SQL tests) did NOT run." >&2
  exit 0
fi

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "$NAME" -e POSTGRES_PASSWORD=test -p 127.0.0.1::5432 "$IMAGE" >/dev/null

# Wait until the real server (not the init-time temporary one) accepts TCP.
ready=0
for _ in $(seq 1 60); do
  if docker exec "$NAME" pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1; then
    ready=$((ready + 1))
    [ "$ready" -ge 2 ] && break
  else
    ready=0
  fi
  sleep 1
done
if [ "$ready" -lt 2 ]; then
  echo "FAILED: Postgres container did not become ready in 60 s." >&2
  exit 1
fi

PORT="$(docker port "$NAME" 5432/tcp | head -n1 | sed 's/.*://')"
export AI_USAGE_PG_URL="postgres://postgres:test@127.0.0.1:${PORT}/postgres"

deno test --allow-net --allow-env --allow-read supabase/tests/ai_usage.test.ts
