Firebreak 0.4.1 is an early development build: stages 1 and 2 of a planned twelve (River Village and Dune Sea). Linux x86-64, OpenGL 3.3-compatible graphics. This release is marked as a pre-release.

- After you press Start, the game asks for your name once, before the mission. The box is filled with the last name you used; press Enter to confirm. A Change name option is on the title menu.
- High scores are saved automatically under that name. There is a top ten for the whole run and a top ten for each stage, shown as tabs on the title screen. The overall run score is written when a run ends, not after a mid-campaign stage clear. The result screen no longer asks for a name.
- The optional global top 100 still uses the same name, score, mode and version, and never blocks the game.
- Stage 2, Dune Sea, remains playable as in 0.4.0 (high noon desert, shemagh militia, snipers, camel scouts, a technical and a convoy mid-boss).

Download `Firebreak-0.4.1-linux-x86_64.tar.gz`, extract it and run `Firebreak/play.sh`. A `.deb` and an AppImage are also attached. Confirm the files against `SHA256SUMS-0.4.1`. Godot is not required. A Windows zip may be attached for testing; it has not been run on Windows and is not supported.

The Snap Store package is `firebreak-game`. A tag push uploads it to the `edge` channel; promoting a revision to `stable` is done by hand. Version 0.4.0 remains on `stable` as revision 3 until this build replaces it.

Only stages 1 and 2 are playable. Testing was on Linux x86-64 with Intel Mesa graphics; no physical gamepad was connected. The optional global top 100 cannot be verified — the game is open source, so fake scores remain possible.

Source and original artwork: Apache-2.0. Bundled fonts, music, speech and effects retain the terms in NOTICE.

QuietByte · hello@quietbytehq.uk
