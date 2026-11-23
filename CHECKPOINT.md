# CHECKPOINT — Firebreak 0.4.0 (ground, roads, callouts)

Laptop, 23 Nov 2026, afternoon Asia/Karachi. Version stays 0.4.0 (nothing pushed or tagged). Replaced files in `_to_delete/replaced_v040b/`.

- Callouts stay out of the top HUD and fully on screen (PACKAGE, TRUCK WRECKED). Hit flash capped so desert camo does not blow out to white.
- Ground maps per band, digitized from the panoramas. Near enemies stand on the sandbag line; mid/far skip the river and the oasis. Paratroopers only fly while descending.
- Vehicles (truck, technical, convoy) follow a road polyline; camels follow sand tracks. They face their direction of travel and do not cross water.
- Dune Sea robe civilians use a right-facing native (stage 1 villagers stay left-facing). Heat shimmer is a weak horizon-only warp, not a whole-screen wobble.
- `tools/test.sh` and `tools/build-linux.sh` jail XDG_CONFIG/CACHE/STATE and TMPDIR. `~/.config/godot/editor_settings-4.7.tres` mtime stayed 22 Nov 2026, 22:51:37 Asia/Karachi.
- Tests: 1,523 checks, 0 failures. 30 s autoplay (exported build, seed 7, 144 Hz, vsync off + 60 fps limiter): River Village 59.88 fps avg (wall), 1% low 43.6, worst 66.2 ms; Dune Sea 59.92 fps avg, 1% low 43.0, worst 39.3 ms. Shots in `qa/laptop/v040b/` (JPEG copies also at firebreak_shots/v040b/ on the box).

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
- Laptop tests (22 Nov 2026, about 22:52 PKT / Asia/Karachi): 21 suites, **1463 checks, 0 failures**. Jailed under `_to_delete/v040_transfer/qa_home/` (TMPDIR and XDG_*). The real `~/.config/godot/editor_settings-4.7.tres` was not written by this test or the later rebuilds; its mtime was already 22 Nov 2026, 22:51 (it had been 21 Nov 2026, 18:02 at the 0.3.7 checkpoint).
- Export rebuilt (`build/Firebreak/Firebreak.x86_64`, 132 MB) in the same jail.
- 30 s Stage 2 autoplay on the exported build with the noon panorama and heat shimmer visible (seed 7, 144 Hz, vsync off + 60 fps limiter, window 1920×952): 59.95 fps avg (wall clock), smoothed 1% low 55.4, 0.9% smoothed frames > 18 ms; raw 1% low 43.6, 3.5% raw frames > 18 ms, worst 34.4 ms; 22 kills, 0 villagers, score 2,990, quota 85. JSON: `qa/laptop/v040/s2fps2-performance.json`.
- A first panorama bug (the heat-shimmer sprite sat behind an opaque `_draw` fill) was found in early shots and fixed (`bg_sprite.z_index = 0`) before this fps run.
- Shots: `qa/laptop/v040/` and `/workspace/firebreak_shots/v040/` (busy oasis, technical, convoy wreck, travel map after stage 1 and after stage 2).
- Replaced 0.3.7 files are in `_to_delete/replaced_v037b/`; transfer parts in `_to_delete/v040_transfer/`. Not pushed. Tag `v0.3.7` is untouched at `5a1922b`. The owner tags and pushes `v0.4.0`.

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
