#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -x "$project_dir/build/Firebreak/Firebreak.x86_64" ]; then
    echo "No build yet. Run ./tools/build-linux.sh first." >&2
    exit 1
fi
exec "$project_dir/build/Firebreak/play.sh" "$@"
