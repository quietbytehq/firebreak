Firebreak 0.5.0 is an early development build: stages 1 to 3 of a planned twelve (River Village, Dune Sea and Coral Coast). Linux x86-64, OpenGL 3.3-compatible graphics. This release is marked as a pre-release.

- Stage 3, Coral Coast, is playable: a Caribbean bay at golden hour, with gang riflemen, pier gunners, weaving speedboats, a beach jeep and townspeople on the sand. The gunboat is a stop-the-scroll arena boss — the camera holds on the harbour, and the stage ends when the gunboat is destroyed.
- It is harder than Dune Sea (quota 128, with a further 15% fire-rate and density bump). The harbour gunboat is larger, closer and tougher, with a second deck gunner. Stage music is "Caribbean Steel Drums 2" by Tozan (CC0). Other new bay and vehicle recordings are also CC0; see NOTICE.
- Figures in the water stand waist-deep and shoot from there; civilians stay on land. Near figures only stand on a parapet where land or sand is directly behind them — over the Coral Coast harbour they wade at the shore instead of standing on the sandbags with open sea behind their feet. Killing 3 civilians fails the stage, with an on-screen warning after the first and second. Each run has 3 continue diamonds: a failed stage can be retried until they run out, then the run score is saved. The result screen does not leave the stage title or “TOO MANY CIVILIANS” banner over the result title. There is no paid continue.
- After you press Start, the game still asks for your name once, before the mission. High scores are saved automatically under that name, including a Coral Coast tab on the title board. The result screen does not ask for a name.
- Stage 1, River Village, and stage 2, Dune Sea, remain playable as in 0.4.0 / 0.4.1.

Download `Firebreak-0.5.0-linux-x86_64.tar.gz`, extract it and run `Firebreak/play.sh`. A `.deb` and an AppImage are also attached. Confirm the files against `SHA256SUMS-0.5.0`. Godot is not required. A Windows zip may be attached for testing; it has not been run on Windows and is not supported.

The Snap Store package is `firebreak-game`. A tag push uploads it to the `edge` channel; promoting a revision to `stable` is done by hand.

Only stages 1 to 3 are playable. Testing was on Linux x86-64 with Intel Mesa graphics; no physical gamepad was connected. The optional global top 100 cannot be verified — the game is open source, so fake scores remain possible.

Source and original artwork: Apache-2.0. Bundled fonts, music, speech and effects retain the terms in NOTICE.

QuietByte · hello@quietbytehq.uk
