#!/bin/sh
# Runs every isolated headless test suite with a throwaway user:// folder.
set -eu
cd "$(dirname "$0")/.."
# Keep Godot editor settings and temp files out of the real home.
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/firebreak-test.XXXXXX")
mkdir -p "$test_dir/config" "$test_dir/data" "$test_dir/cache" "$test_dir/state" "$test_dir/tmp"
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
export XDG_CONFIG_HOME="$test_dir/config"
export XDG_DATA_HOME="$test_dir/data"
export XDG_CACHE_HOME="$test_dir/cache"
export XDG_STATE_HOME="$test_dir/state"
export TMPDIR="$test_dir/tmp"
"${GODOT:-godot}" --headless --editor --path . --import --quit >/dev/null 2>&1
status=0
for test_file in tests/test_*.gd; do
  test_name=$(basename "$test_file" .gd)
  if XDG_DATA_HOME="$test_dir/$test_name" timeout 150s "${GODOT:-godot}" --headless --path . --script "$test_file" >"$test_dir/$test_name.log" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  grep -E "checks, |SCRIPT ERROR|Parse Error|^ERROR" "$test_dir/$test_name.log" || true
  if [ "$rc" -ne 0 ]; then
    echo "FAILED: $test_name (exit $rc)"; grep -A1 "ERROR" "$test_dir/$test_name.log" | head -40; status=1
  fi
done
if [ "$status" -eq 0 ]; then echo "All suites passed."; else echo "Some suites FAILED."; fi
exit "$status"
