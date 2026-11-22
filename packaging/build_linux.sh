#!/bin/sh
# Packages the exported Linux build (build/linux/Firebreak.x86_64) as
# tar.gz, .deb and, when appimagetool is available, an AppImage.
# Usage: packaging/build_linux.sh <version>
set -e
VERSION="${1:?version required}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/build/linux/Firebreak.x86_64"
if [ ! -f "$BIN" ] && [ -f "$ROOT/build/Firebreak/Firebreak.x86_64" ]; then
  mkdir -p "$ROOT/build/linux"
  cp "$ROOT/build/Firebreak/Firebreak.x86_64" "$BIN"
  chmod 755 "$BIN"
fi
DIST="$ROOT/dist"
[ -f "$BIN" ] || { echo "missing $BIN - export the Linux preset first"; exit 1; }
mkdir -p "$DIST"

# tar.gz for any distribution (folder Firebreak/ with a play.sh launcher)
TMP="$(mktemp -d)"
mkdir -p "$TMP/Firebreak/audio"
cp "$BIN" "$TMP/Firebreak/Firebreak.x86_64"
chmod 755 "$TMP/Firebreak/Firebreak.x86_64"
if [ -f "$ROOT/tools/play.sh" ]; then
  cp "$ROOT/tools/play.sh" "$TMP/Firebreak/play.sh"
else
  printf '%s\n' '#!/bin/sh' 'exec "$(dirname "$(readlink -f "$0")")/Firebreak.x86_64" "$@"' > "$TMP/Firebreak/play.sh"
fi
chmod 755 "$TMP/Firebreak/play.sh"
if [ -f "$ROOT/tools/README-player.md" ]; then
  cp "$ROOT/tools/README-player.md" "$TMP/Firebreak/README.md"
fi
cp "$ROOT/LICENSE" "$ROOT/NOTICE" "$TMP/Firebreak/"
[ -f "$ROOT/CHANGELOG.md" ] && cp "$ROOT/CHANGELOG.md" "$TMP/Firebreak/"
[ -d "$ROOT/LICENSES" ] && cp -R "$ROOT/LICENSES" "$TMP/Firebreak/"
cp "$ROOT/assets/logo/firebreak-512.png" "$TMP/Firebreak/icon.png"
if [ -f "$ROOT/docs/gameplay.jpg" ]; then
  cp "$ROOT/docs/gameplay.jpg" "$TMP/Firebreak/preview.jpg"
fi
printf '%s\n' '# Replacement audio files (optional)' '' \
  'All sounds are built into the game. To try a replacement, drop a file here (.ogg, .wav' \
  'or .mp3) using a base name from the audio brief and restart. Built-in sounds take priority.' \
  > "$TMP/Firebreak/audio/README.md"
tar -C "$TMP" -czf "$DIST/Firebreak-$VERSION-linux-x86_64.tar.gz" Firebreak

# .deb
DEB="$TMP/deb"
mkdir -p "$DEB/DEBIAN" "$DEB/usr/lib/firebreak" "$DEB/usr/bin" "$DEB/usr/share/applications" \
  "$DEB/usr/share/icons/hicolor/512x512/apps" "$DEB/usr/share/icons/hicolor/256x256/apps" \
  "$DEB/usr/share/doc/firebreak"
cp "$BIN" "$DEB/usr/lib/firebreak/Firebreak.x86_64"
chmod 755 "$DEB/usr/lib/firebreak/Firebreak.x86_64"
cat > "$DEB/usr/bin/firebreak" <<'WRAP'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/../lib/firebreak/Firebreak.x86_64" "$@"
WRAP
chmod 755 "$DEB/usr/bin/firebreak"
cp "$ROOT/packaging/firebreak.desktop" "$DEB/usr/share/applications/firebreak.desktop"
cp "$ROOT/assets/logo/firebreak-512.png" "$DEB/usr/share/icons/hicolor/512x512/apps/firebreak.png"
cp "$ROOT/assets/logo/firebreak-256.png" "$DEB/usr/share/icons/hicolor/256x256/apps/firebreak.png"
cp "$ROOT/LICENSE" "$ROOT/NOTICE" "$DEB/usr/share/doc/firebreak/"
[ -f "$ROOT/CHANGELOG.md" ] && cp "$ROOT/CHANGELOG.md" "$DEB/usr/share/doc/firebreak/"
cat > "$DEB/DEBIAN/control" <<CTRL
Package: firebreak
Version: $VERSION
Section: games
Priority: optional
Architecture: amd64
Maintainer: QuietByte <quietbyte.2026@gmail.com>
Description: Firebreak - Operation Wolf-style gallery shooter
 An Operation Wolf-style gallery shooter by QuietByte. Hold the line as the
 battlefield pans across a jungle river village. Version $VERSION is an early
 development build (stage 1 of a planned twelve) with a global top 100.
CTRL
dpkg-deb --build --root-owner-group "$DEB" "$DIST/firebreak_${VERSION}_amd64.deb" >/dev/null

# AppImage
TOOL="${APPIMAGETOOL:-$(command -v appimagetool || true)}"
if [ -n "$TOOL" ]; then
  APP="$TMP/Firebreak.AppDir"
  mkdir -p "$APP/usr/bin"
  cp "$BIN" "$APP/usr/bin/firebreak"
  cp "$ROOT/packaging/firebreak.desktop" "$APP/firebreak.desktop"
  cp "$ROOT/assets/logo/firebreak-512.png" "$APP/firebreak.png"
  printf '#!/bin/sh\nexec "$(dirname "$(readlink -f "$0")")/usr/bin/firebreak" "$@"\n' > "$APP/AppRun"
  chmod 755 "$APP/AppRun" "$APP/usr/bin/firebreak"
  ARCH=x86_64 "$TOOL" --appimage-extract-and-run "$APP" "$DIST/Firebreak-$VERSION-x86_64.AppImage" >/dev/null
else
  echo "appimagetool not found - skipping the AppImage"
fi
rm -rf "$TMP"
ls -la "$DIST"
