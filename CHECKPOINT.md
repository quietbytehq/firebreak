# CHECKPOINT — Firebreak 0.5.1

Updated: 2026-11-25 (PKT, UTC+5)

## v0.5.1 — global scores, air strike, dialogue, Coral Coast rusher and grenadier
- Version is 0.5.1. The published tag `v0.5.0` (commit `1df0ffc`, tag object `62edcf0`) must not be moved; it is already on origin and on snap `latest/edge` as revision 4. This round is a new local annotated tag `v0.5.1` only. Do not move `v0.3.7`, `v0.4.0`, `v0.4.1` or `v0.5.0`. Do not push until the owner asks.
- GLOBAL SCORES uses `Online.open_site()`: `xdg-open` inside a snap (desktop portal), otherwise `OS.shell_open`. Snapcraft lists `desktop` and `desktop-legacy` plugs. The dev build was checked on the laptop; the installed snap was not refreshed (no sudo). What could not be verified is noted in the handoff.
- Air strike root cause: leftover GUI focus after the name prompt ate E / middle-click in `_unhandled_input`. Bindings and the 1-per-stage charge were already correct. Fix: poll the action in `_process`, `gui_release_focus()` on stage start and name confirm, clickable HUD panel, first-time hint, empty-charge line, README how-to, and a test that calls the strike and checks it hits enemies (and that E still works with a focused LineEdit).
- Text-only dialogue on all stages (radio, Rayan event lines, short story beats). No new voice, no ElevenLabs. Radio plate at y=118, never on the y=280 banners, never blocks play.
- New Coral Coast enemies: machete rusher (wades, charges, melee if not shot) and pier grenadier (lobs shootable grenades with a shadow marker). Water / pier / facing tests cover both. White sticker outlines baked on Coral riflemen, the pier gunner (magenta cleaned), and the new art. Stage 1 masters already had the outline; confirmed in a gameplay shot.
- Tests: 30 suites, 1,961 checks, 0 failures (`./tools/test.sh`). New suites `tests/test_airstrike.gd` (16) and `tests/test_dialogue.gd` (9). Headless `tools/smoke_v050b.gd`: SMOKE OK, quota 128, continue retry leaves 2 diamonds, gunboat cleared with reason `boss` (camera 1920, gun_y 791, HP 33).
- Shots: `/workspace/firebreak_shots/v050d/` — `stage1_outlines`, `airstrike`, `dialogue`, `rusher`, `grenadier` (PNG + JPG + `_preview.jpg`). Captured on the laptop at 1797×1011 (the window could not be forced to 1920×1080; nvidia-drm did not attach, Intel Mesa). Visual check: Stage 1 riflemen and the MG nest show a clear white sticker outline; the air strike shows jets, ground blasts and “AIR STRIKE INBOUND!”; the radio plate at y=118 shows a Rayan line under the top HUD and clear of the y=280 banners; Coral Coast has a waist-deep machete rusher in the shallows and a grenadier on the pier planks.
- GLOBAL SCORES: `Online.open_command` is tested (xdg-open when SNAP is set, `OS.shell_open` otherwise). The installed snap is still 0.5.0 rev 4 on `latest/edge` (stable is 0.4.0 rev 3). `desktop` and `desktop-legacy` are already connected. This session could not enter `snap run --shell` (snap-confine capabilities). The 0.5.1 snap was not installed (no sudo), so the new SNAP `xdg-open` path was not live-clicked in the installed snap.
- Replaced files: `_to_delete/replaced_v050d/`. Local annotated tag `v0.5.1` only. Do not push until the owner asks.

---
# CHECKPOINT — Firebreak 0.5.0

Updated: 2026-11-25 (PKT, UTC+5)

## v0.5.0c — near parapet water and continue-banner overlap
- Near-band figures may only stand on the parapet where land or sand is directly behind them. On Coral Coast the near land map ends at the sandy beach (x=1888); from x=1890 the harbour parapet is a near water body with a shore waterline just behind the bags. A near rifleman there wades waist-deep at that line, with a ripple, instead of standing on the sandbag lip with only sea behind the feet. Mid harbour water now runs continuously from the mid bay to the east open sea.
- `Ground.water_under_or_behind` is the shared test: water under the feet, or a per-band shore map at that x. A farther water body alone does not count (Dune Sea near figures stay dry on the sand bank in front of the oasis).
- The result screen calls `view.clear_announcements()`, which drops the stage title card and callout banners, so "TOO MANY CIVILIANS" cannot overlap the result title.
- Tests: 28 suites, 1,893 checks, 0 failures (`./tools/test.sh`). New asserts in `tests/test_water.gd`: no near or mid rifleman has water under or behind its feet unless it is wading, plus an explicit Coral harbour audit (near waders contact the shore waterline at y>=790, not mid-bay depth). `tests/test_continues.gd` checks that the result screen has cleared the title and civilian banners. Headless `tools/smoke_v050b.gd`: 3-civilian fail, continue (2 diamonds left), then the gunboat cleared with reason `boss` (camera 1920, gun_y 791, HP 33, quota 128).
- Shots: `/workspace/firebreak_shots/v050c/` — `boss`, `wading`, `continue`, `civilians_beach`, `civilian_warning` (PNG + JPG + `_preview.jpg`). Captured on the laptop at 1797×1011 (the window could not be forced to 1920×1080; nvidia-drm did not attach, Intel Mesa). Median frame time was 60 fps on beach, wading and boss. The boss capture reported `boss_removed_dry_on_water=0` and 3 harbour near waders. Visual check: near harbour figures are waist-deep at the shore with a ripple, not standing on the sandbag lip with only sea behind their feet; the continue screen no longer has “TOO MANY CIVILIANS” or the stage title over “MISSION FAILED”.
- Replaced files: `_to_delete/replaced_v050c/`. The unpublished local tag `v0.5.0` was deleted and recreated on this commit. Do not move `v0.3.7`, `v0.4.0` or `v0.4.1`. Do not push until the owner asks.

---
# CHECKPOINT — Firebreak 0.5.0

Updated: 2026-11-25 (PKT, UTC+5)

## v0.5.0 fix round — water, civilians, continues, harder Coral Coast
- Version stays 0.5.0. The unpublished local tag `v0.5.0` was deleted and recreated on this commit. Do not move `v0.3.7` (`5a1922b`), `v0.4.0` (`5b4b534`) or `v0.4.1` (`4659341`).
- Water: infantry in a stage water body stand waist-deep (sprite clipped at the waterline, ripple, shooting-from-water pose). Boat crews stay in their boats; pier gunners stay on the planks. Coral Coast mid-bay riflemen can spawn in the water (`water_combat`). River Village and Dune Sea only wade if a figure is actually placed in those gaps.
- The harbour gunboat no longer hops to the far water line when mid sand is off-screen. It holds on the mid water path in the deep basin (about y=791), scale 0.95, 33 HP, with a second deck gunner.
- Civilians walk only on land, facing their velocity, and turn at the water or path edge. Tests cover spawn points, paths and facing on all three stages.
- Killing 3 civilians fails any stage (`end_reason` `civilians`). On-screen warning: `CIVILIAN DOWN 1/3` and `2/3`, then `TOO MANY CIVILIANS`. The result screen says “Too many civilians were hit.”
- Each run has 3 continue diamonds on the HUD. A failed stage (death or the civilian rule) offers Continue, which spends one diamond and restarts that stage. With none left it is game over and the run score is saved. No store or real-money tie-in.
- Coral Coast difficulty on top of the previous 0.5.0 tuning: quota 128 (116 × 1.10), fire rate and density ×1.15, more riflemen in the waves.
- The crate and stray arm were cut off the speedboat sprite. Painted sand on the coconut and mango cutouts was left (a cleanup pass ate the fruit; originals were restored). A thin sand strip remains under the speedboat hull.
- Tests: 28 suites, 1,849 checks, 0 failures (`./tools/test.sh`). Headless `tools/smoke_v050b.gd`: 3-civilian fail, continue (2 diamonds left), then the gunboat cleared with reason `boss` (camera 1920, gun_y 791, HP 33, quota 128).
- Shots: `/workspace/firebreak_shots/v050b/` — `civilians_beach`, `civilian_warning`, `continue`, `wading`, `boss` (PNG + JPG + `_preview.jpg`). Captured on the laptop at 1797×1011 (the window could not be forced to 1920×1080; nvidia-drm did not attach, Intel Mesa). Median frame time was 60 fps on beach, wading and boss.
- Replaced laptop files went to `_to_delete/replaced_v050b/`. Commit as QuietByte; the owner pushes.
- Snap `stable` is still 0.4.0 (revision 3) until the owner promotes a later revision.

---
# CHECKPOINT — Firebreak 0.5.0

Updated: 2026-11-24 (PKT, UTC+5)

## v0.5.0 round — Stage 3 Coral Coast (golden hour, arena gunboat)
- Stage 3 is playable. Golden-hour Caribbean bay panorama (v2, continuous, 3840×1080), no heat shimmer. Quota 111 in 180 s, about 31% harder than Dune Sea. The sandbag parapet is kept.
- New enemies: coral riflemen (soldier_prefix), pier gunners (3 HP, planted on pier planks), weaving speedboats (max 2, water path), a beach jeep with a bed gunner (max 1, coast track). Townsman / townswoman civilians, same penalty. Pickups: mango, coconut, water, bread; one scripted ammo crate late.
- The gunboat is a full stop-the-scroll arena boss from t=140 at camera x=1920. Quota and the 180 s clock do not clear the stage while it lives; time may run past 180. Destroying the hull starts a short wreck, then the stage clears with reason `boss`. Fail if the player dies.
- Per-frame `Ground.feet_off` uses sand, water, the coast road and pier contact lines. Facing is set per sprite type (rifle barrels painted left; town walk cycles painted facing right). Callouts stay on screen. Deaths keep the living scale.
- Audio is CC0 only (no ElevenLabs). Credits in NOTICE: Caribbean Steel Drums 2 (Tozan), waves and seagulls (kkenny101), speedboat loop (morganpurkis), jeep idle (craigsmith), ferry engine (suonidigenova), pier creak (morosopher). Music is loudnormed to about −16 LUFS / −1.5 dBTP and loop-crossfaded.
- After stage 2 the travel map offers Coral Coast (no “coming soon”). After stage 3 it previews Iron Harbour as coming soon.
- Version 0.5.0 in `project.godot`, `snap/snapcraft.yaml` (`.deb` name updated), CHANGELOG, README, `tools/README-player.md`, `data/campaign.json` and `.github/RELEASE_v0.5.0.md`.
- Tests: 25 suites, 1,758 checks, 0 failures (`./tools/test.sh`). Headless smoke of stage 3 including the gunboat cleared with reason `boss` (camera held at 1920).
- Shots: `/workspace/firebreak_shots/v050_stage3/` — start, mid, pier, boss, result (PNG + JPG + `_preview.jpg`). Captured on the laptop at 1692×952 (the window could not be forced to 1920×1080 under this session's Wayland/Intel Mesa fallback; nvidia-drm did not attach). Median frame time was 60 fps on start, mid, pier and boss.
- Git: do not move tags `v0.3.7` (`5a1922b`), `v0.4.0` (`5b4b534`) or `v0.4.1` (name-at-start). Commit and tag `v0.5.0` locally; the owner pushes.
- Snap `stable` is 0.4.0 (revision 3) until the owner promotes a later revision. 0.4.1 may still be unpushed when this ships; 0.5.0 includes that name-at-start work.

---
# CHECKPOINT — Firebreak 0.4.1

Updated: 2026-11-24 (PKT, UTC+5)

## v0.4.1 round — name at start, per-stage high scores
- After Start, the game asks for the player name once, before the briefing or stage. The box is prefilled with the last used name from `user://settings.cfg` (`player_name`). Enter or a gamepad button confirms. "Change name" is on the title menu and as a clickable control above the scoreboard.
- The result screen no longer asks for a name. Qualifying per-stage scores are saved automatically under that name. The overall run table is written only when a run ends (fail, last stage, or quit to the title). The optional global post uses the same name and still never blocks.
- `user://scores.json` is now `{runs, stages}`; a bare array from 0.4.0 still loads as the run table. `Scores.player_name()` / `save_player_name()` hold the saved name, defaulting to PLAYER.
- The title shows tabbed local tables (RUN and each playable stage's top ten). The Top Scores menu lists both tables in full.
- Version 0.4.1 in `project.godot`, `snap/snapcraft.yaml` (`.deb` name updated), CHANGELOG, README, `tools/README-player.md` and `.github/RELEASE_v0.4.1.md`. Campaign JSON stays at 0.4.0 (still two playable stages).
- Tests: 24 suites, 1,677 checks, 0 failures on the development copy.
- Git: do not move tags `v0.3.7` (`5a1922b`) or `v0.4.0` (`5b4b534`). Commit and tag `v0.4.1` locally; the owner pushes.
- Shots: `/workspace/firebreak_shots/v050/` (`v050-title.png`, `v050-title-menu.png`, `v050-name.png`, all 1920×1080, md5-checked from the laptop). Laptop copies (gitignored) are in `qa/laptop/v050/`. Replaced files also went to `_to_delete/replaced_v050_name/` and `_to_delete/replaced_v041/`.
- `docs/Firebreak-How-to-Play.pdf` is in the tree (merged from GitHub into `86786da`).
- Snap `stable` is still 0.4.0 (revision 3) until the owner promotes 0.4.1.
- A separate worker may be making Stage 3 Coral Coast concept art in `/workspace/firebreak_concepts/stage3/`; do not touch that folder.

---
# CHECKPOINT — Firebreak 0.4.0

Updated: 2026-11-22 (PKT, UTC+5)

## v0.4.0 round — Stage 2 Dune Sea (noon)
- Stage 2 is playable. High-noon panorama (seam and ghost palm painted out), heat-shimmer shader on the background only, short dust-storm beat (105–118 s). Quota 85 in 180 s.
- New enemies: shemagh militia (stage soldier_prefix), rooftop snipers (2 HP), camel scouts (1 HP, max 2), a technical with a bed gunner (no Huey), convoy truck mid-boss (~18 HP after difficulty).
- Robed adult civilians, same penalty. Pickups: dates, bread, waterskin, ration, ammo.
- After stage 1 the travel map offers Dune Sea (no “coming soon”). After stage 2 it previews Coral Coast as coming soon. Store button is “Continue to Dune Sea” and calls `continue_run_to(2)` without `begin_run()`.
- Campaign scoring and the 40,000-point-per-stage leaderboard check are unchanged.
- Audio is CC0 only (no ElevenLabs this round). Credits in NOTICE: Darbuka Delight (Adiutorium), Desert Loop (iamoneabe, backup), desert atmosphere (Vrymaa), truck idle (qubodup), gusty wind (craigsmith), camel (annakstedt), falling bricks (iwanPlays). Loudnorm −16 LUFS, OGG.
- Version 0.4.0 in `project.godot`, `snap/snapcraft.yaml` (grade still `stable`, `.deb` name updated), CHANGELOG, README and `.github/RELEASE_v0.4.0.md`.
- Icon v2 already shipped in 0.3.7 at `assets/logo/firebreak-512.png` (70,652 bytes, palette). `assets/ui/icon.png` now uses that same file so the Godot icon is also under 256 kB.
- Git: do not move tag `v0.3.7` (`5a1922b`). Local commit of 0.4.0 is not pushed. The owner tags `v0.4.0`.
- Shots: `/workspace/firebreak_shots/v040/`. Replaced laptop files go to `_to_delete/replaced_v037b/` (never deleted).
- QA results (tests, fps, commit hash) are filled in after the laptop run in this same round.

---
# CHECKPOINT — Firebreak 0.3.7

Updated: 2026-11-22 (PKT, UTC+5)

## v0.3.7 round — one START, visible near enemies, title call, local scores
- Single START button on the title. The skippable briefing still plays the first time (`seen_briefing`). Rewatch with F1 on the title or “Story briefing” in the pause menu (returns to pause). The separate Story button is gone.
- Near-band feet sit at y 920, above the HUD band (y 940). Incoming fire lands at 900–932. Near soldiers, pickups and incoming tracers are drawn on canvas layer 2, above the first-person gun (layer 1) and below the HUD (layer 3). HUD plates are a little more translucent.
- Title announcer call: “FIREBREAK! Cut the Ember Ring.” ElevenLabs eleven_v4, Voice Library “Andrew - Fifties Announcer” (`p0Gik0TBCfzjohLCb7Mr`), one take, **83 credits**. 3.28 s, two-pass loudnorm −16 LUFS / −1.5 dBTP (measured −16.78 LUFS, TP −1.45 dB), OGG Vorbis q6, 48 kHz mono. Plays once per launch, 0.45 s after the title intro, with a 7 dB music duck. File: `assets/audio/title_call.ogg`.
- Title shows this computer’s LOCAL HIGH SCORES and a GLOBAL SCORES control that opens `https://firebreak.quietbytehq.uk` with `OS.shell_open` only (the host was not looked up). The existing name-entry post client is unchanged.
- The briefing’s dark text panel fades into the map (gradient, no hard vertical seam).
- Box and laptop tests: 20 suites, **1394 checks, 0 failures**.
- Public release files (Linux tar.gz, .deb, AppImage when the tool is present, and SHA256SUMS) are packed into gitignored `dist/` by `packaging/build_linux.sh` / `tools/package-release.sh`. Snap name: `firebreak-game`, built from the .deb, with the `network` plug. CI (`.github/workflows/ci.yml`) attaches packages to a GitHub pre-release on the version tag and uploads the snap to `edge`. Tag `v0.3.7` is created locally only; the owner registers the snap name, sets the store secret, and pushes.
- App icon: original flaming F (512×512, 256×256, SVG) at `assets/logo/`, also `assets/ui/icon.png`. Compared at 16/32/48 px against a Rayan-face candidate; the F stays readable at 16 px. Old scenic icon moved to `_to_delete/replaced_v037_icon/`.
- Box shots in `firebreak_shots/v037/` (title with local scores and GLOBAL SCORES, title menu with a single START, briefing fade, busy near-enemy gameplay).
- Laptop (22 Nov 2026, about 12:26 PKT / Asia/Karachi): 24 replaced files plus the 0.3.6 build are in `_to_delete/replaced_v036/`; `title_call.ogg` and its import were new. Transfer archive (md5 `612c9017ac340fa442f290a9dcdbe3b5`, one 200 KB part) lives in `_to_delete/v037_transfer/`. Export rebuilt (`build/Firebreak/Firebreak.x86_64`, 113 MB) with TMPDIR and XDG_* inside `_to_delete/v037_transfer/qa_home/`; the real `~/.config/godot/editor_settings-4.7.tres` was not written (mtime still 21 Nov 2026, 18:02). 30 s autoplay (exported build, 144 Hz, vsync off + 60 fps limiter, window 1920×952): 59.98 fps avg (wall clock), 1% low 50.6, 2.0% frames > 18 ms, worst 73.0 ms; 23 kills, 0 villagers, score 3,360. Screenshots in `qa/laptop/v037/`.

---
# CHECKPOINT — Firebreak 0.3.6

Updated: 2026-11-22 (PKT, UTC+5)

## v0.3.6 round — title music, Ember Ring briefing and travel map, HUD plates and font
- New cinematic title theme (ElevenLabs Music `eleven_music_v2_5`, one 48 s instrumental take, **720 credits**). Opening 12.75 s plays once; a 30.75 s loop (fade-out trimmed, 0.6 s crossfade) follows. Two-pass loudnorm −16 LUFS / −1.5 dBTP, OGG Vorbis q6, 48 kHz stereo. Plays from launch on the title, the briefing and the travel map.
- Opening briefing (STORY.md text, plain mission to cut the Ember Ring): typewriter over a painted dossier, skippable, `rayan_lock_and_load` at the last line (no new speech credits). Shown on the first Start mission; later starts skip it (`seen_briefing` in settings). A title **Story** button replays the briefing and then the travel map, then returns to the title.
- Travel map after a stage-1 clear: 12-stage ember route, current pin, “Next: Dune Sea — coming soon”, one-line brief. Title subtitle is “CUT THE EMBER RING”.
- Top HUD: military/ammo-crate plates, score/cash/clock/enemies icons, tighter layout, segmented enemy bar. Barlow Condensed (OFL, bundled with licence, credited in NOTICE) on the HUD, menus and story screens. The stacked FIREBREAK logo still uses the engine default font.
- QA: `--qa-briefing` and `--qa-map` capture those screens and auto-advance; `--qa-run` still skips them so autopilot is not blocked. `_qa_finish` is safe when no stage has started.
- Box and laptop tests: 20 suites, **1373 checks, 0 failures**.
- Box shots in `firebreak_shots/v036/` (HUD before/after, title, briefing, travel map).
- Laptop (22 Nov 2026, about 11:54 PKT / Asia/Karachi): 23 replaced files are in `_to_delete/replaced_v035/`; new files include fonts, briefing/map art, HUD plates and the story scripts. Transfer parts live in `_to_delete/v036_transfer/`. Export rebuilt (`build/Firebreak/Firebreak.x86_64`, 113 MB) with TMPDIR and XDG_* inside `_to_delete/v036_transfer/qa_home/`; the real `~/.config/godot/editor_settings-4.7.tres` was not written. 30 s autoplay (exported build, 144 Hz, vsync off + 60 fps limiter, window 1920×952): 60.04 fps avg (wall clock), 1% low 49.4, 2.2% frames > 18 ms, worst 32.0 ms; 24 kills, 0 villagers, score 3,680. Screenshots in `qa/laptop/v036/`.

---
# CHECKPOINT — Firebreak 0.3.5

Updated: 2026-11-22 (PKT, UTC+5)

## v0.3.5 round — fail-screen blend, no bullet tracers, bigger muzzle burst
- Mission-failed and stage-clear screens: Rayan is a feathered cut-out with colour grading, a left vignette and a contact shadow, sitting in the battlefield instead of a hard rectangular illustration. The title screen is already a full composed painting and the HUD portrait sits in a framed panel; both were left alone.
- Bullet tracers and the smoke line from the gun to the target are gone. Rocket and grenade projectile trails are a little softer.
- Every gun shot throws a bigger, brighter, varied muzzle flash, more sparks, and a puff of smoke that drifts up from the first-person muzzle and lingers briefly (particle cap, fewer puffs on SMGs).
- Box and laptop tests: 19 suites, **1280 checks, 0 failures**.
- Box shots in `firebreak_shots/v035/` (fail before and after, muzzle on Viper 9, Hornet 9, Kalash 47 and Thunder M60).
- Laptop (22 Nov 2026, about 11:18 PKT / Asia/Karachi): 11 replaced files and the 0.3.4 build are in `_to_delete/replaced_v034/`; 6 files were new; transfer parts live in `_to_delete/v035_transfer/`. Export rebuilt (`build/Firebreak/Firebreak.x86_64`, 109 MB) with TMPDIR and XDG_* inside `_to_delete/v035_transfer/qa_home/`; the real `~/.config/godot/editor_settings-4.7.tres` was not written. 30 s autoplay (exported build, seed 7, Hornet 9, 144 Hz, vsync off + 60 fps limiter, window 1920×952): 60.00 fps avg (wall clock), 1% low 46.5, 2.2% frames > 18 ms, worst 41.7 ms; 23 kills, 0 villagers, score 4,460. Screenshots in `qa/laptop/v035/`.

---
# CHECKPOINT — Firebreak 0.3.4

Updated: 2026-11-22 (PKT, UTC+5)

## v0.3.4 round — polish merged onto the 0.3.3 scoreboard
- Civilians face the way they walk (`VILLAGER_NATIVE`).
- Sticker outlines (white outer, thin dark inner) rebaked on 56 sprites from un-outlined masters.
- First-person: 8 new rear firing views (Hornet 9, Stinger V, Kalash 47, Sentinel M4, Granite G3,
  Longshot 700, Hammer RPG, Tankbuster). Side reload pose only on magazine/bullet guns (5 pistols,
  5 SMGs, Kalash, Sentinel, Granite, Longshot). Thunder M60, Hammer RPG, Tankbuster and Thumper GL
  keep the rear view and only dip. Old side-on pictures of Hornet, Stinger, Kalash, Sentinel,
  Granite and Longshot are reused as their reload poses.
- Tracers and smoke from the first-person muzzle; smoke trails on rockets and grenades.
- Popping score numbers, streak callouts (STREAK 3 / ON A ROLL / UNSTOPPABLE), stage title card,
  banners including CLEAN SHOT, NEST SILENCED, TRUCK WRECKED, PACKAGE.
- Head shots: +50 (after the band multiplier, still a multiple of 10) and a CLEAN SHOT banner.
  No bonus for civilians or vehicles. Clear bonus still uses the 0.3.3 per-term rounding.
- Weapon rebalance: within a category a dearer gun is never weaker per shot. Longshot 700 (5.0)
  is the marksman exception versus Thunder M60 (now 2.3). Also raised: Kestrel 1.6, Buzzsaw 1.2,
  Ratchet 1.2, Mamba 1.3, Stinger 1.3, Sentinel 1.6.
- Eleven new Rayan catchphrases (Flint, eleven_v4, 183 characters / 183 credits, loudnorm −16 LUFS,
  48 kHz OGG), unlocked by `profile.stages_cleared` as in `story/CATCHPHRASES.md`. The award line
  is in the bank but not triggered until the ceremony is built.
- Ember Ring story draft in `story/STORY.md` (not implemented). Scoreboard, `run_score` and
  `online.gd` from 0.3.3 kept intact.
- Box tests: 19 suites, 1277 checks, 0 failures. Box autoplay shots in
  `firebreak_shots/v034/` (rear fire, Hornet reload pose, CLEAN SHOT, stickered civilians).
- Laptop (22 Nov 2026, about 10:31 PKT / Asia/Karachi): 176 replaced files and the 0.3.3 build are in `_to_delete/replaced_v033/`; 54 files were new; transfer parts live in `_to_delete/v034_transfer/`. 19 suites, **1277 checks, 0 failures**. Export rebuilt (`build/Firebreak/Firebreak.x86_64`, 109 MB) with TMPDIR and XDG_* inside `_to_delete/v034_transfer/qa_home/`; the real `~/.config/godot/editor_settings-4.7.tres` was not written. 60 s autoplay (exported build, seed 7, Hornet 9, `--qa-aim-head`, 144 Hz, vsync off + 60 fps limiter, window 1920×952): 60.05 fps avg (wall clock), 1% low 49.6, 2.2% frames > 18 ms, worst 42.1 ms; 46 kills, 0 villagers, score 9,200. Screenshots in `qa/laptop/v034/` and `qa/laptop/v034-reload/` (reload pose); JPEG copies also at `firebreak_shots/v034/v034-laptop-*.jpg`.

---
# CHECKPOINT — Firebreak 0.3.3

Updated: 2026-11-22 (PKT, UTC+5)

## v0.3.3 round — global top 100, built on the development copy
- Cloudflare Worker + D1 in `leaderboard/`, modelled on Nudge: GET / and /api/top, POST /api/submit,
  admin page with a secret key, rate limit, name filter, parameterised SQL, textContent on the public page.
- Worker vars: MIN_SCORE 2000, MAX_SCORE 5,000,000. Only mode `campaign`. Scores must be a multiple of 10
  (integer-valued floats such as 6230.0 are accepted). A `stages` field (1–12) is required; a score over
  40,000 × stages is refused.
- Game: campaign run total (starts from “Start mission”; later stages add to it; only stage 1 is playable
  today), accuracy and time clear-bonus terms rounded to a multiple of 10, `scripts/online.gd` posts
  name, score, mode, version and stages without blocking, name-entry opt-out (Tab) saved in settings,
  snap `network` plug. v0.3.2 visual/weapon/story work was not included.
- Box tests: 19 suites, 1207 checks, 0 failures (new: Online and campaign scores, 33). Local `wrangler dev`
  tests all passed (valid score, min/max, not a multiple of 10, non-integer, blocked names including
  leetspeak, unknown mode, stages cap, rate limit, admin with/without key and delete, markup escaped,
  game-side headless post to the local worker). Live site and Cloudflare deploy were not tried.
- Laptop (22 Nov 2026, about 09:58 PKT): 29 files deployed (1 part, archive md5
  754877e62cf266952e08ebb1dbb8d151); 13 replaced files and the 0.3.1 build in `_to_delete/replaced_v031/`;
  transfer files in `_to_delete/v033_transfer/`. 19 suites, 1207 checks, 0 failures; export rebuilt
  (`build/Firebreak/Firebreak.x86_64`, README 0.3.3). Git repo initialised on `main` with a repo-local
  QuietByte identity; first commit is the 0.3.3 tree.

- The game is open source: a made-up score can still be posted. The checks keep out junk; the admin
  link removes the rest.

---
# CHECKPOINT — Firebreak 0.3.1

Updated: 2026-11-16 (PKT, UTC+5)

## v0.3.1 round — done, deployed to the laptop (16 Nov 2026, about 18:30 PKT)
- Laptop: 66 files deployed (41 parts checksum-verified, archive md5 matches, all 496 tracked files
  match the box after extraction); 15 replaced files + the 0.3.0 build in `_to_delete/replaced_v030/`;
  transfer parts, lists, logs and temp/QA home folders in `_to_delete/v031_transfer/`; JPEG copies in
  `_to_delete/v031_jpg_transfer/`. 18 suites, 1174 checks, 0 failures; export rebuilt (README 0.3.1).
- Laptop autoplay (exported build, seed 7, 60 s, plugged in, 144 Hz, vsync off + 60 fps limiter):
  60.09 fps avg (wall clock), 1% low 44.5, 1.9% frames > 18 ms, worst 37.7 ms
  (0.3.0: 60.03 / 46.4 / 3.4% / 76.6 ms). Captures in `qa/laptop/v031/`.

### Box notes for this round
- Pause: every gameplay sound (SFX, rotor/heartbeat loops, ambience, voice, enemy fire) and the stage
  music freeze; a calm pause-menu track (`assets/audio/music_pause.ogg`, ElevenLabs Music, -16 LUFS,
  58 s loop) plays; resume continues everything. Music toggle and track button work while paused.
- First-person weapon view: 20 generated pictures (19 weapons + Air Strike radio) in Rayan's arms,
  sway, aim follow, recoil, muzzle flash and sparks (guns), launch fire, smoke and back-blast
  (launchers), lower/raise on switch, reload dip; under the HUD layer.
- 18 suites, 1174 checks, 0 failures (new: First-person view 92, Pause audio 29).
- Box llvmpipe A/B, 30 s seed 7: 47.4 fps with the view vs 48.9 without (about 3%).
- ElevenLabs: 3,600 credits (one music run = 4 takes × 900). Images: 22 generations (2 rejected).
- Stages 2 (Dune Sea) and 3 (Coral Coast) not started, as instructed.
Next (owner): play-test 0.3.1; then Stage 2 "Dune Sea" and Stage 3 "Coral Coast" concepts.

---
# CHECKPOINT — Firebreak 0.3.0

Updated: 2026-11-16 (PKT, UTC+5)

## v0.3.0 round — done, deployed to the laptop (16 Nov 2026, after owner review)
- Baked ink outlines on all soldiers, paratroopers, MG nests, villagers, the helicopter and
  pickups (sizes unchanged).
- 19 original weapons (5 pistols, 5 SMGs, 5 rifles/MG, 4 specials) + Air Strike, data-driven in
  `data/weapons.json`; 3-slot loadout (pistol / primary / special) with per-weapon magazines;
  weapon bar with icons and ammo; 1/2/3, Q/wheel, LB/Y; bar clicks select without firing.
- Cash: kill bounties, shootable $150/$400 money drops, -$300 per villager hit; saved in
  user://profile.json. Store with Pistols / SMGs / Rifles / Specials tabs (buy, equip, ammo).
- 20 generated weapon icons + money-drop sprite; 30 ElevenLabs sounds (18 fire, reload and dry
  groups, switch, cash, store), 162.3 credits.
- 16 suites, 1053 checks, 0 failures (box). New suites: weapon data, loadout, ammo, economy,
  store, HUD click.
- Box: replaced art in `_to_delete/replaced_v030_art/`; pre-0.3.0 snapshot in `_to_delete/v021_snapshot/`.
- Laptop: 207 files deployed (checksums match the box), 86 replaced files + old build in
  `_to_delete/replaced_v021/`; 16 suites, 1053 checks, 0 failures; export rebuilt. Autoplay on
  battery, 144 Hz: 59 s run 60.0 fps avg (wall clock), 1% low 46.4, 3.4% frames > 18 ms; captures
  in `qa/laptop/v030/`. See QA_REPORT.md.
Next (owner): play-test weapons, prices and Store; Stage 2 "Dune Sea" art approval.

---
# CHECKPOINT — Firebreak 0.2.1

Updated: 2026-11-16 (PKT, UTC+5)

## v0.2.1 round — done, deployed to the laptop
- Enemies face and fire at the player (front poses, mirrored inward, incoming rounds, hit
  markers); explosion fringe cleaned; bigger near soldiers; denser waves. Version 0.2.1.
- 10 suites, 430 checks, 0 failures (development copy). New: tests/test_facing.gd.
- Laptop: deployed (15 replaced files in `_to_delete/replaced_v020/`, old build in
  `_to_delete/replaced_v020/build/`), 430 checks 0 failures, export built. Autoplay on battery,
  144 Hz: 110 s run 59.97 fps avg, 1% low 50.3, 2.1% frames > 18 ms; stage cleared at 1:38.
  Captures in `qa/laptop/v021/`. See QA_REPORT.md.
Next (owner): play-test the new density; Stage 2 "Dune Sea" art approval.

---
# CHECKPOINT — Firebreak 0.2.0

Updated: 2026-11-15 (PKT, UTC+5)

## v0.2.0 round — done
Deployed to the laptop and verified there (9 suites, 409 checks, 0 failures; export built).
- Painted sprites (adults only; child villager art not copied into the game), heli/jet/bomb/
  explosion cut-outs, sprite metadata, mipmaps.
- Title screen (Rayan art, zoom/parallax, embers, live logo, PRESS START, credit, intro→loop
  music). Pause menu: music on/off, track 1-3, music/effects sliders (saved).
- Muzzle flashes + depth-attenuated gunshots, hit shake, blood-edge vignette, heartbeat.
- Rayan HUD portrait + result bust. Grenades (5, r≈445 px), air strike (spares civilians),
  Huey with door gunner, truck fix, 35 SFX + 10 voice lines wired.
- 60 fps cap; vsync auto-off on non-multiple-of-60 displays. Laptop (144 Hz, battery):
  60.0 fps avg, 1% low 50.9, 1.8% frames > 18 ms over 110 s. See QA_REPORT.md.
Next (owner): confirm ElevenLabs plan; gamepad and Windows testing; git/snap only on go-ahead.

---
# CHECKPOINT — Firebreak 0.1.0

Updated: 2026-11-15 (PKT, UTC+5)

## Done
- Project created (Godot 4.7.2, GL Compatibility, 1920x1080, canvas_items stretch).
- Stage 1 "River Village" playable: data-driven stage (data/stages/stage_01.json), 12-stage
  campaign with difficulty curve (data/campaign.json), riflemen, MG nests, paratroopers,
  truck, villagers (penalty), food (heal), 5 power-ups, reload, grenades, HUD, title/pause/
  result/top-scores/controls-remap screens, F11, Esc, gamepad, audio-by-base-name (silent if missing).
- 6 headless suites, 246 assertions, all passing (on the development copy).
- A full real-time autopilot run ended with STAGE CLEAR at about 2:04.

## In progress / next
1. Run ./tools/test.sh on the laptop.
2. ./tools/build-linux.sh, then run the export with the QA autopilot for screenshots and FPS
   (see HANDOFF.md, "QA capture").
3. Copy the best screenshots to docs/ and fill in QA_REPORT.md with measured numbers.

## Open issues
- Character art is placeholder; no audio bundled.
- No physical gamepad tested; Windows not built.
