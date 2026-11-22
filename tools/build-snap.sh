#!/bin/sh
# Builds the strict snap from dist/firebreak_<version>_amd64.deb.
# Requires the .deb (run packaging/build_linux.sh first). Does not upload.
set -eu
cd "$(dirname "$0")/.."
ver=$(awk -F= '/^config\/version=/ {gsub(/"/, "", $2); print $2}' project.godot)
deb="dist/firebreak_${ver}_amd64.deb"
if [ ! -f "$deb" ]; then
    echo "missing $deb - run packaging/build_linux.sh $ver first" >&2
    exit 1
fi
# Keep the version in snap/snapcraft.yaml in sync with project.godot.
if ! grep -q "version: \"${ver}\"" snap/snapcraft.yaml; then
    echo "snap/snapcraft.yaml version does not match project.godot ($ver)" >&2
    exit 1
fi
if ! grep -q "source: dist/firebreak_${ver}_amd64.deb" snap/snapcraft.yaml; then
    echo "snap/snapcraft.yaml parts.source does not match $deb" >&2
    exit 1
fi
snapcraft pack --use-lxd
mkdir -p dist
# snapcraft writes the .snap into the current directory
snap_file=$(ls -1 firebreak-game_"${ver}"_amd64.snap 2>/dev/null || ls -1 firebreak-game_*.snap)
mv -f "$snap_file" dist/
echo "Built dist/$(basename "$snap_file")"
