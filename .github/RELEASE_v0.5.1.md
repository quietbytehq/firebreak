Firebreak 0.5.1 is an early development build: stages 1 to 3 of a planned twelve (River Village, Dune Sea and Coral Coast). Linux x86-64, OpenGL 3.3-compatible graphics. This release is marked as a pre-release.

- The GLOBAL SCORES link on the title screen opens the public board in your default web browser, including from the Snap Store build (via the desktop portal).
- The air strike (E, middle-click, or the AIR STRIKE panel) is fixed. Leftover menu focus can no longer swallow the key. A short on-screen hint appears the first time a strike is ready.
- All stages have more radio chatter and Rayan lines (text only; no new voice).
- Coral Coast adds two enemy types: a machete rusher who wades out of the shallows and charges, and a pier grenadier who lobs grenades you can shoot in the air.
- Stage 1 and Coral Coast enemies share the same white sticker outline.
- Stage 3 remains the harder harbour fight from 0.5.0: quota 128, arena gunboat, waist-deep wading, the three-civilian fail rule, and 3 continue diamonds.

Download `Firebreak-0.5.1-linux-x86_64.tar.gz`, extract it and run `Firebreak/play.sh`. A `.deb` and an AppImage are also attached. Confirm the files against `SHA256SUMS-0.5.1`. Godot is not required. A Windows zip may be attached for testing; it has not been run on Windows and is not supported.

The Snap Store package is `firebreak-game`. A tag push uploads it to the `edge` channel; promoting a revision to `stable` is done by hand. Do not move the published `v0.5.0` tag.

Only stages 1 to 3 are playable. Testing was on Linux x86-64 with Intel Mesa graphics; no physical gamepad was connected. The optional global top 100 cannot be verified — the game is open source, so fake scores remain possible.

Source and original artwork: Apache-2.0. Bundled fonts, music, speech and effects retain the terms in NOTICE.

QuietByte · hello@quietbytehq.uk
