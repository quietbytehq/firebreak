#!/bin/sh
# Builds the strict snap. Not run for 0.1.0: only run when the owner says go.
set -eu
cd "$(dirname "$0")/.."
./tools/build-linux.sh
mkdir -p build/snap-payload/bin build/snap-payload/game build/snap-payload/usr/share/doc/firebreak
cp -R build/Firebreak/. build/snap-payload/game/
cp tools/launch-snap.sh build/snap-payload/bin/launch-firebreak
chmod +x build/snap-payload/bin/launch-firebreak
cp LICENSE NOTICE build/snap-payload/usr/share/doc/firebreak/
cp -R LICENSES build/snap-payload/usr/share/doc/firebreak/
snapcraft pack --use-lxd --output build/
