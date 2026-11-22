#!/bin/sh
# Exports the Linux build to build/Firebreak/ with the official templates.
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/Firebreak/audio
touch build/.gdignore
"${GODOT:-godot}" --headless --editor --path . --import --quit
"${GODOT:-godot}" --headless --path . --export-release 'Linux Desktop' build/Firebreak/Firebreak.x86_64
cp tools/play.sh build/Firebreak/play.sh
cp tools/README-player.md build/Firebreak/README.md
cp AUDIO_BRIEF.md ART_PROMPTS.md QA_REPORT.md NOTICE LICENSE build/Firebreak/
cp -R LICENSES build/Firebreak/
cp assets/ui/icon.png build/Firebreak/icon.png
printf '%s\n' '# Replacement audio files (optional)' '' 'All sounds are built into the game. To try a replacement, drop a file here (.ogg, .wav' 'or .mp3) using a base name from ../AUDIO_BRIEF.md and restart. Built-in sounds take priority.' > build/Firebreak/audio/README.md
chmod +x build/Firebreak/play.sh build/Firebreak/Firebreak.x86_64
echo "Built build/Firebreak/Firebreak.x86_64"
