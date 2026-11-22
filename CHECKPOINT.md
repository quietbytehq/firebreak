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
  `/workspace/firebreak_shots/v034/` (rear fire, Hornet reload pose, CLEAN SHOT, stickered civilians).
- Laptop (22 Nov 2026, about 10:31 PKT / Asia/Karachi): 176 replaced files and the 0.3.3 build are in `_to_delete/replaced_v033/`; 54 files were new; transfer parts live in `_to_delete/v034_transfer/`. 19 suites, **1277 checks, 0 failures**. Export rebuilt (`build/Firebreak/Firebreak.x86_64`, 109 MB) with TMPDIR and XDG_* inside `_to_delete/v034_transfer/qa_home/`; the real `~/.config/godot/editor_settings-4.7.tres` was not written. 60 s autoplay (exported build, seed 7, Hornet 9, `--qa-aim-head`, 144 Hz, vsync off + 60 fps limiter, window 1920×952): 60.05 fps avg (wall clock), 1% low 49.6, 2.2% frames > 18 ms, worst 42.1 ms; 46 kills, 0 villagers, score 9,200. Screenshots in `qa/laptop/v034/` and `qa/laptop/v034-reload/` (reload pose); JPEG copies also at `/workspace/firebreak_shots/v034/v034-laptop-*.jpg`.

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
