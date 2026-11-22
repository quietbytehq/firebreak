#!/bin/sh
# Export the Linux build and pack the public release archives into dist/.
# Artifacts are gitignored. Does not push, tag or upload anything.
set -eu
cd "$(dirname "$0")/.."
ver=$(awk -F= '/^config\/version=/ {gsub(/"/, "", $2); print $2}' project.godot)
if [ -z "$ver" ]; then
    echo "Could not read application/config/version from project.godot" >&2
    exit 1
fi
./tools/build-linux.sh
./packaging/build_linux.sh "$ver"
(
    cd dist
    sha256sum $(ls -1 | grep -v '^SHA256SUMS') > "SHA256SUMS-${ver}"
)
echo "Packed dist/ for ${ver}"
cat "dist/SHA256SUMS-${ver}"
