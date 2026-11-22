#!/usr/bin/env bash
# Local wrangler dev tests. Does not log in or contact firebreak.quietbytehq.uk.
set -euo pipefail
cd "$(dirname "$0")"
export FIREBREAK_ROOT="$(cd .. && pwd)"
export GODOT="${GODOT:-/workspace/godot/godot}"
export PORT="${PORT:-8787}"
export FIREBREAK_SCORES_URL="http://127.0.0.1:${PORT}"
export ADMIN_KEY="$(openssl rand -hex 16)"
IP_SALT="$(openssl rand -hex 16)"

npm install --no-audit --no-fund >/dev/null
printf 'ADMIN_KEY=%s\nIP_SALT=%s\n' "$ADMIN_KEY" "$IP_SALT" > .dev.vars
WRANGLER_PID=""
cleanup() {
  rm -f .dev.vars
  if [ -n "$WRANGLER_PID" ]; then kill "$WRANGLER_PID" 2>/dev/null || true; wait "$WRANGLER_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT

npx wrangler d1 execute firebreak-scores --local --file=schema.sql --yes >/dev/null
npx wrangler d1 execute firebreak-scores --local --command "DELETE FROM scores;" --yes >/dev/null || true

npx wrangler dev --local --ip 127.0.0.1 --port "$PORT" >wrangler-dev.log 2>&1 &
WRANGLER_PID=$!

python3 - <<'PY'
import os, sys, time, urllib.request
base = os.environ["FIREBREAK_SCORES_URL"]
for _ in range(60):
    try:
        urllib.request.urlopen(base + "/api/top", timeout=1)
        sys.exit(0)
    except Exception:
        time.sleep(0.25)
print("wrangler dev did not become ready", file=sys.stderr)
sys.exit(1)
PY

python3 ./test_local.py
