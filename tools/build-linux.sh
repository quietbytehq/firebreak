#!/bin/sh
# Exports the Linux build to build/linux/ and also assembles build/Firebreak/
# (play.sh, icon, docs) for local play.
set -eu
cd "$(dirname "$0")/.."
# --headless --editor --import writes editor_settings; keep that out of ~/.config/godot.
qa_dir=$(mktemp -d "${TMPDIR:-/tmp}/firebreak-build.XXXXXX")
mkdir -p "$qa_dir/config" "$qa_dir/data" "$qa_dir/cache" "$qa_dir/state" "$qa_dir/tmp"
trap 'rm -rf "$qa_dir"' EXIT HUP INT TERM
export XDG_CONFIG_HOME="$qa_dir/config"
export XDG_CACHE_HOME="$qa_dir/cache"
export XDG_STATE_HOME="$qa_dir/state"
export TMPDIR="$qa_dir/tmp"
# XDG_DATA_HOME is left alone so export templates in ~/.local/share/godot still resolve.
mkdir -p build/linux build/Firebreak/audio
touch build/.gdignore
"${GODOT:-godot}" --headless --editor --path . --import --quit
"${GODOT:-godot}" --headless --path . --export-release Linux build/linux/Firebreak.x86_64
cp build/linux/Firebreak.x86_64 build/Firebreak/Firebreak.x86_64
cp tools/play.sh build/Firebreak/play.sh
cp tools/README-player.md build/Firebreak/README.md
cp AUDIO_BRIEF.md ART_PROMPTS.md QA_REPORT.md NOTICE LICENSE build/Firebreak/
[ -f CHANGELOG.md ] && cp CHANGELOG.md build/Firebreak/
cp -R LICENSES build/Firebreak/
cp assets/logo/firebreak-512.png build/Firebreak/icon.png
if [ -f docs/gameplay.jpg ]; then cp docs/gameplay.jpg build/Firebreak/preview.jpg; fi
printf '%s\n' '# Replacement audio files (optional)' '' 'All sounds are built into the game. To try a replacement, drop a file here (.ogg, .wav' 'or .mp3) using a base name from ../AUDIO_BRIEF.md and restart. Built-in sounds take priority.' > build/Firebreak/audio/README.md
chmod +x build/Firebreak/play.sh build/Firebreak/Firebreak.x86_64 build/linux/Firebreak.x86_64
echo "Built build/linux/Firebreak.x86_64 and build/Firebreak/Firebreak.x86_64"
