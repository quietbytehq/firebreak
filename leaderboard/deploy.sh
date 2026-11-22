#!/usr/bin/env bash
# Publishes the Firebreak global top 100 to firebreak.quietbytehq.uk.
# Run `npx wrangler login` once first. Safe to run again after changes.
set -euo pipefail
cd "$(dirname "$0")"
npm install --no-audit --no-fund >/dev/null

db_id() {
  npx wrangler d1 list --json | python3 -c "import sys, json; print(next((d['uuid'] for d in json.load(sys.stdin) if d['name'] == 'firebreak-scores'), ''))"
}

if grep -q REPLACE_WITH_DATABASE_ID wrangler.toml; then
  id="$(db_id)"
  if [ -z "$id" ]; then
    echo "Creating the database..."
    npx wrangler d1 create firebreak-scores >/dev/null
    id="$(db_id)"
  fi
  sed -i "s/REPLACE_WITH_DATABASE_ID/$id/" wrangler.toml
fi

echo "Preparing the tables..."
npx wrangler d1 execute firebreak-scores --remote --file=schema.sql --yes >/dev/null

echo "Publishing..."
npx wrangler deploy

keyfile="$HOME/.config/firebreak-scores-admin.txt"
if [ ! -f "$keyfile" ]; then
  key="$(openssl rand -hex 16)"
  salt="$(openssl rand -hex 16)"
  printf '{"ADMIN_KEY":"%s","IP_SALT":"%s"}' "$key" "$salt" | npx wrangler secret bulk >/dev/null
  mkdir -p "$(dirname "$keyfile")"
  printf 'https://firebreak.quietbytehq.uk/admin?key=%s\n' "$key" > "$keyfile"
  chmod 600 "$keyfile"
fi

echo
echo "Live at:    https://firebreak.quietbytehq.uk"
echo "Admin link: saved in $keyfile (keep it private)"
