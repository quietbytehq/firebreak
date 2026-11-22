Firebreak 0.3.7 is an early development build: stage 1 of a planned twelve (River Village). Linux x86-64, OpenGL 3.3-compatible graphics. This release is marked as a pre-release.

- One START button. The skippable Ember Ring briefing plays the first time; rewatch it with F1 on the title or from the pause menu.
- Near enemies stand above the health and weapon bars and in front of the first-person gun.
- An announcer calls "FIREBREAK! Cut the Ember Ring." over the title music once per launch.
- The title shows this computer's local high scores. GLOBAL SCORES opens https://firebreak.quietbytehq.uk in the system browser.
- The briefing panel fades into the map.

The app icon is a flaming F in the title's action-comic style.

Download `Firebreak-0.3.7-linux-x86_64.tar.gz`, extract it and run `Firebreak/play.sh`. A `.deb` and an AppImage are also attached. Confirm the files against `SHA256SUMS-0.3.7`. Godot is not required. A Windows zip may be attached for testing; it has not been run on Windows and is not supported.

The Snap Store package is `firebreak-game`. A tag push uploads it to the `edge` channel; promoting a revision to `stable` is done by hand.

Only stage 1 is playable. Testing was on Linux x86-64 with Intel Mesa graphics; no physical gamepad was connected. The optional global top 100 cannot be verified — the game is open source, so fake scores remain possible. The ElevenLabs plan behind the bundled audio is not yet confirmed; see NOTICE.

Source and original artwork: Apache-2.0. Bundled fonts, music, speech and effects retain the terms in NOTICE.

QuietByte · hello@quietbytehq.uk
