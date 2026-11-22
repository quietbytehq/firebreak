# QA report — Firebreak 0.3.7

Date: 22 November 2026. Deployed to and tested on the test laptop (Intel RPL-P graphics, Mesa, 144 Hz panel). Box results follow.

## Laptop results (0.3.7)
- Deploy: 22 November 2026, about 12:26 PKT (Asia/Karachi). 24 files replaced (moved to
  `_to_delete/replaced_v036/`, including the 0.3.6 export); `assets/audio/title_call.ogg` and
  its import were added. Transfer archive and the QA jail are in `_to_delete/v037_transfer/`.
  Archive md5 `612c9017ac340fa442f290a9dcdbe3b5`.
- `./tools/test.sh`: 20 suites, **1394 checks, 0 failures** (same counts as the development copy;
  0.3.6 was 1373).
- `./tools/build-linux.sh`: export rebuilt (`build/Firebreak/Firebreak.x86_64`, 113 MB). TMPDIR
  and XDG_* were set under `_to_delete/v037_transfer/qa_home/` (export templates symlinked in);
  the real `~/.config/godot/editor_settings-4.7.tres` was unchanged (mtime 21 Nov 2026, 18:02
  Asia/Karachi).
- Autoplay, exported build, 30 s (stage 1; capture frames excluded).
  Mesa Intel(R) Graphics (RPL-P), 144 Hz, vsync off + 60 fps limiter, window 1920×952:

| Measure | 0.3.7 wall clock (30 s) | 0.3.7 smoothed | 0.3.6 wall clock (30 s) |
|---|---|---|---|
| Frames | 1739 | 1740 | 1758 |
| Average fps | 59.98 | 59.98 | 60.04 |
| 1% low fps | 50.6 | 60.0 | 49.4 |
| Frames > 18 ms | 34 (2.0%) | 3 | 39 (2.2%) |
| Worst frame | 73.0 ms | 52.8 ms | 32.0 ms |

  23 kills, 0 villagers hit, score 3,360, health 87. Average fps and the share of frames over
  18 ms stay in the same band as 0.3.6; the 1% low is a little higher (50.6 vs 49.4). The worst
  raw frame (73.0 ms) is a one-off spike; p99 is 19.8 ms.
- Screenshots (real, laptop): `qa/laptop/v037/v037-laptop-title.jpg` (local high scores and
  GLOBAL SCORES), `v037-laptop-title-menu.jpg` (single START), `v037-laptop-briefing.jpg`
  (gradient fade), `v037-laptop-run-013s.jpg` and `v037-laptop-run-014s.jpg` (near rifleman
  fully visible above the HUD and in front of the gun). JPEG copies also at
  `firebreak_shots/v037/`.
- Title call: 83 ElevenLabs credits, one take. The live scoreboard was not looked up.
- App icon: a flaming F was chosen after viewing 16, 32 and 48 px previews of two original
  candidates (flaming F vs Rayan's sunglassed face). At 16 px the F is still a letter; the
  face becomes an orange blob. 512×512 and 256×256 PNGs plus an SVG are in `assets/logo/`.
  `project.godot` `application/config/icon`, the Windows export icon, the desktop file, the
  snap / store listing and the README all use this icon.

## Development-copy results (0.3.7)
- `./tools/test.sh`: 20 suites, **1394 checks, 0 failures**.
- Box screenshots (xvfb, 1920×1080) in `firebreak_shots/v037/`:
  `v037-title.jpg`, `v037-title-menu.jpg`, `v037-briefing.jpg`, `v037-013s.jpg`,
  `v037-014s.jpg`. Software renderer fps on the box is not comparable to the laptop.

## Not tested
- A live post to firebreak.quietbytehq.uk (the site is not deployed yet; the host was not
  looked up). After the owner creates the empty GitHub repo, pushes, logs in to Wrangler and
  runs `leaderboard/deploy.sh`, the live tests can be done: post a test score, confirm it,
  delete it via the admin page (`~/.config/firebreak-scores-admin.txt`), confirm the board is
  empty, then post from the game. Fake scores remain possible because the code is public.
- Opening GLOBAL SCORES in a real browser session (the call is `OS.shell_open` of the known
  URL; that was not fired from here).
- A Snap Store upload or login (the owner does `snapcraft login`, the store secret and any
  promotion from `edge` to `stable`). The snap name `firebreak-game` still has to be
  registered. A local snap pack is attempted without sudo when the .deb is ready.
- A real Windows run. CI exports a Windows zip; that artifact is untested and not supported.

---
# QA report — Firebreak 0.3.6

Date: 22 November 2026. Deployed to and tested on the test laptop (Intel RPL-P graphics, Mesa, 144 Hz panel). Box results follow.

## Laptop results (0.3.6)
- Deploy: 22 November 2026, about 11:54 PKT (Asia/Karachi). 23 files replaced (moved to
  `_to_delete/replaced_v035/`); fonts, story art, HUD plates and new scripts were added. Transfer
  parts and the QA jail are in `_to_delete/v036_transfer/`.
- `./tools/test.sh`: 20 suites, **1373 checks, 0 failures** (same counts as the development copy;
  0.3.5 was 1280, the delta is the story/font/HUD suite and a few extra existing checks).
- `./tools/build-linux.sh`: export rebuilt (`build/Firebreak/Firebreak.x86_64`, 113 MB). TMPDIR
  and XDG_* were set under `_to_delete/v036_transfer/qa_home/` (export templates symlinked in);
  the real `~/.config/godot/editor_settings-4.7.tres` was unchanged.
- Autoplay, exported build, 30 s (title intro then stage 1; capture frames excluded).
  Mesa Intel(R) Graphics (RPL-P), 144 Hz, vsync off + 60 fps limiter, window 1920×952:

| Measure | 0.3.6 wall clock (30 s) | 0.3.6 smoothed | 0.3.5 wall clock (30 s) |
|---|---|---|---|
| Frames | 1758 | 1758 | 1746 |
| Average fps | 60.04 | 60.04 | 60.00 |
| 1% low fps | 49.4 | 60.0 | 46.5 |
| Frames > 18 ms | 39 (2.2%) | 2 | 39 (2.2%) |
| Worst frame | 32.0 ms | 21.7 ms | 41.7 ms |

  24 kills, 0 villagers hit, score 3,680, health 100. Average fps and the share of frames over
  18 ms match 0.3.5; the 1% low is a little higher (49.4 vs 46.5).
- Screenshots (real, laptop): `qa/laptop/v036/v036-laptop-title.jpg` (CUT THE EMBER RING),
  `v036-laptop-008s.jpg` (new HUD plates), `v036-laptop-briefing.jpg`, `v036-laptop-map.jpg`
  (Next: Dune Sea — coming soon). JPEG copies also at `firebreak_shots/v036/`.

## Box results (0.3.6)
- `./tools/test.sh`: 20 suites, **1373 checks, 0 failures**.
  Ammo 14, Art and audio 92, Combat 49, Economy 17, Facing 25, First-person view 119, Helicopter 24, HUD click 20, Input map 72, Loadout 34, Main scene 36, Online and campaign scores 33, Pause audio 29, Spawning 25, Stage data 86, Stage flow 35, Store 26, Story 87, Weapon data 517, Weapons 33.
- Screenshots (real, llvmpipe): `firebreak_shots/v036/hud-before.jpg`,
  `hud-after.jpg`, `v036-title.jpg`, `v036-briefing.jpg`, `v036-map.jpg`.
- Title music: one ElevenLabs Music take, 720 credits. No new speech credits (the briefing
  reuses `rayan_lock_and_load`).

---
# QA report — Firebreak 0.3.5

Date: 22 November 2026. Deployed to and tested on the test laptop (Intel RPL-P graphics, Mesa, 144 Hz panel). Box results follow.

## Laptop results (0.3.5)
- Deploy: 22 November 2026, about 11:18 PKT (Asia/Karachi). 11 files replaced (moved to
  `_to_delete/replaced_v034/` with the 0.3.4 build); 6 files were new. Transfer parts and the
  QA jail are in `_to_delete/v035_transfer/`.
- `./tools/test.sh`: 19 suites, **1280 checks, 0 failures** (same counts as the development copy;
  0.3.4 was 1277, the delta is muzzle-smoke tests).
- `./tools/build-linux.sh`: export rebuilt (`build/Firebreak/Firebreak.x86_64`, 109 MB). TMPDIR
  and XDG_* were set under `_to_delete/v035_transfer/qa_home/`; the real
  `~/.config/godot/editor_settings-4.7.tres` was unchanged.
- Autoplay, exported build, seed 7, 30 s, Hornet 9, `--qa-aim-head`, a forced shot at 8 s
  (capture frames excluded). Mesa Intel(R) Graphics (RPL-P), 144 Hz, vsync off + 60 fps limiter,
  window 1920×952:

| Measure | 0.3.5 wall clock (30 s) | 0.3.5 smoothed | 0.3.4 wall clock (60 s) |
|---|---|---|---|
| Frames | 1746 | 1747 | 3499 |
| Average fps | 60.00 | 60.02 | 60.05 |
| 1% low fps | 46.5 | 60.0 | 49.6 |
| Frames > 18 ms | 39 (2.2%) | 2 | 77 (2.2%) |
| Worst frame | 41.7 ms | 27.6 ms | 42.1 ms |

  23 kills, 0 villagers hit, score 4,460, health 100. Average fps and the share of frames over
  18 ms match 0.3.4; the 1% low is a little lower on this shorter run (46.5 vs 49.6).
- Screenshots (real, laptop): `qa/laptop/v035/v035-laptop-fail-result.jpg` blended mission-failed
  screen; `qa/laptop/v035/v035-laptop-fire-008s.jpg` Hornet muzzle burst, no bullet tracer.
  JPEG copies also at `firebreak_shots/v035/v035-laptop-*.jpg`.

## Box results (0.3.5)
- `./tools/test.sh`: 19 suites, **1280 checks, 0 failures**.
  Ammo 14, Art and audio 89, Combat 49, Economy 17, Facing 25, First-person view 119, Helicopter 24,
  HUD click 20, Input map 72, Loadout 34, Main scene 34, Online and campaign scores 33, Pause audio 29,
  Spawning 25, Stage data 85, Stage flow 35, Store 26, Weapon data 517, Weapons 33.
- Screenshots (real, llvmpipe): `firebreak_shots/v035/v035-fail-before.jpg` (hard
  rectangular bust), `v035-fail-after.jpg` (feathered cut-out in the scene),
  `v035-muzzle-pistol-fire-003s.jpg` (Viper 9), `v035-muzzle-smg-fire-003s.jpg` (Hornet 9),
  `v035-muzzle-rifle-fire-003s.jpg` (Kalash 47), `v035-muzzle-m60-fire-003s.jpg` (Thunder M60).

---
# QA report — Firebreak 0.3.4

Date: 22 November 2026. Deployed to and tested on the test laptop (Intel RPL-P graphics, Mesa, 144 Hz panel). Box results follow.

## Box results (0.3.4)
- `./tools/test.sh`: 19 suites, **1277 checks, 0 failures**.
  Ammo 14, Art and audio 89, Combat 49, Economy 17, Facing 25, First-person view 116, Helicopter 24,
  HUD click 20, Input map 72, Loadout 34, Main scene 34, Online and campaign scores 33, Pause audio 29,
  Spawning 25, Stage data 85, Stage flow 35, Store 26, Weapon data 517, Weapons 33.
  (v0.3.3 was 1207 checks; the delta is sticker/facing/headshot/reload-pose/catchphrase/rounding tests.)
- `./tools/build-linux.sh`: export built (`build/Firebreak/Firebreak.x86_64`, 109 MB).
- Box autoplay (llvmpipe, not a laptop figure), 22 s, Hornet 9 loadout, `--qa-aim-head`, reload at 8 s:
  18 kills, 0 villagers, score 3480 (multiple of 10). Screenshots (real):
  `firebreak_shots/v034/v034-003s.jpg` rear Hornet fire + CLEAN SHOT,
  `v034-008s.jpg` Hornet side reload pose (RELOADING), stickered farmer,
  `v034-012s.jpg` and `v034-016s.jpg` rear fire, tracers, CLEAN SHOT, stickered civilian walking
  the correct way.
## Laptop results (0.3.4)
- Deploy: 22 November 2026, about 10:31 PKT (Asia/Karachi). 176 files replaced (moved to
  `_to_delete/replaced_v033/` with the 0.3.3 build); 54 files were new. Transfer parts and the
  QA jail are in `_to_delete/v034_transfer/`.
- `./tools/test.sh`: 19 suites, **1277 checks, 0 failures** (same counts as the development copy).
- `./tools/build-linux.sh`: export rebuilt (`build/Firebreak/Firebreak.x86_64`, 109 MB). TMPDIR
  and XDG_DATA/CONFIG/CACHE_HOME were set under `_to_delete/v034_transfer/qa_home/`; Godot wrote
  its editor settings only in that jail. The real `~/.config/godot/editor_settings-4.7.tres` was
  unchanged.
- Autoplay, exported build, seed 7, 60 s, Hornet 9, `--qa-aim-head`, reload at 8 s, pause at 22 s
  (pause time and capture frames excluded). test laptop, Mesa Intel(R) Graphics (RPL-P), 144 Hz
  panel, vsync off + 60 fps limiter, window 1920×952:

| Measure | 0.3.4 wall clock | 0.3.4 smoothed | 0.3.1 wall clock |
|---|---|---|---|
| Frames | 3499 | 3500 | 3505 |
| Average fps | 60.05 | 60.01 | 60.09 |
| 1% low fps | 49.6 | 60.0 | 44.5 |
| Frames > 18 ms | 77 (2.2%) | 14 | 65 (1.9%) |
| Worst frame | 42.1 ms | 33.9 ms | 37.7 ms |

  p99 20.2 ms. 46 kills, 0 villagers hit, score 9,200, health 100. Average fps matches 0.3.1;
  the 1% low is better (49.6 vs 44.5) with a slightly higher share of frames over 18 ms (2.2% vs
  1.9%).
- Screenshots (real, laptop):
  `qa/laptop/v034/v034-laptop-fire-003s.jpg` rear Hornet fire, muzzle flash, tracer, CLEAN SHOT +200;
  `qa/laptop/v034/v034-laptop-003s|012s|016s|025s.jpg` gameplay with stickered soldiers/civilians;
  `qa/laptop/v034/v034-laptop-008s.jpg` stickered farmer walking the correct way, ON A ROLL, CLEAN SHOT;
  `qa/laptop/v034/v034-laptop-pause.jpg` pause menu;
  `qa/laptop/v034-reload/v034-laptop-reload-008s.jpg` Hornet side reload pose, HUD RELOADING 0/150,
  stickered civilian walking correctly.
  JPEG copies also at `firebreak_shots/v034/v034-laptop-*.jpg`.


---
# QA report — Firebreak 0.3.1

Date: 16 November 2026. Deployed to and tested on the test laptop (Intel RPL-P graphics,
Mesa, 144 Hz panel, plugged in at 88%). Box results follow; 0.3.0 laptop results further down.

## Laptop results (0.3.1)
- Deploy: 66 new or changed files; all 496 tracked files checksum-identical to the development copy.
- `./tools/test.sh`: 18 suites, **1174 checks, 0 failures**.
- `./tools/build-linux.sh`: export built; the player README in the build reads 0.3.1.
- Autoplay, exported build, seed 7, 60 s (slot switches at 26 s and 40 s, forced shots at 20 s and
  32 s for mid-fire captures, pause at 48 s; pause time and capture frames excluded):

| Measure | 0.3.1 wall clock | 0.3.1 smoothed | 0.3.0 wall clock |
|---|---|---|---|
| Frames | 3505 | 3506 | 3516 |
| Average fps | 60.09 | 60.08 | 60.03 |
| 1% low fps | 44.5 | 60.0 | 46.4 |
| Frames > 18 ms | 65 (1.9%) | 1 | 120 (3.4%) |
| Worst frame | 37.7 ms | 30.0 ms | 76.6 ms |

  p99 22.5 ms. 45 kills, 0 villagers hit. The first-person view holds 60 fps on the laptop; pacing is
  slightly better than 0.3.0 except a marginally lower 1% low. 0.3.0 was measured on battery, 0.3.1
  plugged in, so the comparison is indicative.
- Screenshots (real, laptop): `qa/laptop/v031/v031-laptop-014s|028s|042s|055s.png` (gameplay),
  `v031-laptop-fire-020s.png` (Hornet 9 mid-fire: muzzle flash and sparks),
  `v031-laptop-fire-032s.png` (Viper 9 mid-fire), `v031-laptop-pause.png` (pause menu).


## Automated tests: 18 suites, **1174 checks, 0 failures**
Ammo 14, Art and audio 78, Combat 36, Economy 17, Facing 21, First-person view 92, Helicopter 24,
HUD click 20, Input map 72, Loadout 34, Main scene 34, Pause audio 29, Spawning 25, Stage data 85,
Stage flow 32, Store 26, Weapon data 502, Weapons 33. New suites:
- `test_pause_audio` — the pause track ships; pausing freezes SFX, loops, ambience, voice and the
  stage music (frozen, not lost); gunfire, explosions, enemy fire, loops and voice cannot start while
  paused; sim events stay silent and delayed sounds wait; menu sounds still play; Music OFF/ON in
  the pause menu stops/starts the pause track; resume restores the same stage track and ambience;
  pausing with music off; a track change while paused starts on resume; Restart and Quit to title
  from the pause menu clear the paused state.
- `test_fp_view` — fp_weapons.json is 0.3.1; a 640×640 cut-out picture with a muzzle point for all
  19 weapons and the air strike, back-blast points for the rockets; drawn under the HUD layer and the
  screen effects; hidden on the title screen and after quitting; shows the selected weapon; a switch
  lowers then raises the new one (all three slots); recoil on a shot and settles; guns flash and
  spark from the muzzle; the launcher puffs and back-blasts with no sparks and kicks harder; reload
  dip (launcher and rifle); a grenade from the rifle slot briefly shows the grenade hand; the air
  strike shows the radio; the view is frozen while paused.

## Frame rate (box, llvmpipe — not representative of the laptop)
30 s autopilot, seed 7, Kalash 47, 1920×1080, wall clock: **47.4 fps** average, 1% low 40.3,
p99 24.8 ms with the first-person view; **48.9 fps**, 1% low 41.7, p99 24.0 ms with `--qa-no-fp`.
The view costs about 3% on the CPU renderer (0.3.0 box baseline: 47.0). The 60 fps check has to be
repeated on the laptop GPU after deploy.

## Captures (real renders on the box, kept outside the project folder)
- Pistol (Viper 9), rifle (Kalash 47) and launcher (Hammer RPG) views, idle and mid-fire (flash and
  sparks for the guns; launch fire, smoke and back-blast for the launcher).
- Pause menu over the frozen stage.
- Contact sheets of all 20 first-person pictures (dusk, checkerboard, and with muzzle markers).

## Known gaps (0.3.1)
- Not yet run on the laptop (tests, export, frame rate).
- Launchers still show the loaded round during the reload; the back-blast sits close to the HUD
  bar and is partly behind it.

---
# QA report — Firebreak 0.3.0

Date: 16 November 2026. Deployed to and tested on the test laptop (Ubuntu, Mesa 26.0.8,
Intel RPL-P graphics, 144 Hz panel, GL Compatibility renderer), **on battery** (81% → 77%).
Development-copy (box) results follow the laptop section; 0.2.1 results are further down.

## Laptop results (0.3.0)
- Deploy: 207 new or changed files, every one checksum-identical to the development copy.
- `./tools/test.sh`: 16 suites, **1053 checks, 0 failures**.
- `./tools/build-linux.sh`: export built; the player README in the build reads 0.3.0.
- Autoplay, seed 7, 60 s (title skipped; slot switches at 26 s and 40 s; 4 captures). Capture
  frames are excluded from all figures. "Wall clock" counts real frame-to-frame times; "smoothed"
  is Godot's delta:

| Measure | Wall clock | Smoothed |
|---|---|---|
| Frames | 3516 | 3517 |
| Average fps | 60.03 | 60.01 |
| 1% low fps | 46.4 | 60.0 |
| Frames > 18 ms | 120 (3.4%) | 1 |
| Worst frame | 76.6 ms | 68.7 ms |

  Most slow frames are 18–24 ms (one 60 ms spike). 46 kills, 0 villagers hit in 59 s. Compared
  with 0.2.1 (1% low 50.3, 2.1% > 18 ms) pacing is slightly rougher; average still 60 fps.
  Vsync off with the 60 fps limiter (144 Hz panel), window 1920×952 (the panel's work area).
- Screenshots (real, laptop): `qa/laptop/v030/v030-laptop-014s|028s|042s|055s.png` (gameplay with
  the weapon bar, cash and outlines) and `v030-laptop-store-0..4-*.png` (each Store tab; the
  rifle tab right after buying the Sentinel M4). QA runs do not touch the player's saved profile.
- A first Store capture attempt was started with the wrong flags and played 30 s of the stage
  instead (avg 60.0, wall-clock 1% low 46.8); its files are in `_to_delete/v030_transfer/misfired_store_run/`.
- Known warning in the exported build: an old UID reference for `scripts/main.gd` in
  `scenes/main.tscn`; Godot falls back to the path, no effect on play.

## Automated tests: 16 suites, **1053 checks, 0 failures**
Ammo 14, Art and audio 78, Combat 36, Economy 17, Facing 21, Helicopter 24, HUD click 20,
Input map 72, Loadout 34, Main scene 34, Spawning 25, Stage data 85, Stage flow 32 (5 seeded bot
runs all cleared on quota at 97–99 s, no villagers hit), Store 26, Weapon data 502, Weapons 33.
New suites:
- `test_weapon_data` — 19 weapons with unique ids and names, every field present, sane stats,
  right slot, an icon and sound files for each, 18 unique fire sounds, frag blast ~30% of the
  screen, and no real brand or model name anywhere in weapons.json.
- `test_loadout` — three slots, starter kit, slot selection and wrap-around cycling, key bindings,
  fire interval and reload from data, switching cancels a reload, specials fire from any slot.
- `test_ammo` — issue magazine and reserve at start, ammo and grenade drops refill the right
  weapon (capped), reloads, empty primary falls back to the pistol, exactly 5 frag grenades.
- `test_economy` — kill bounties with far-band bonus, MG nest and helicopter cash, money drops,
  villager penalty, cash never negative, air-strike kills pay, profile write-back and save/load.
- `test_store` — starter kit, buy (price deducted), equip, ammo packs, "Full" limits, every
  weapon buyable, repair of a damaged or tampered profile (negative cash, unknown guns, ammo and
  air strikes clamped), missing profile file.
- `test_hud_click` — slot hit areas, clicking a slot selects it and fires nothing (left click,
  right click, held button), clicks in the play area still fire, keys 1/2/3, ammo text.
Engine warnings "resources still in use at exit" appear in two suites; they do not affect results.

## Box run (development copy, llvmpipe software renderer — not representative of the laptop)
40 s autopilot, seed 7: 46.99 fps average, 1% low 40.0 fps, worst frame 34.9 ms, 30 kills,
0 villagers hit. Software rendering on the box is CPU bound; laptop figures are above.

## Captures (real renders on the box)
- Weapon icons contact sheet: dark and checkerboard backgrounds.
- HUD weapon bar with the pistol, primary and special selected.
- Store: each tab, including the rifle tab right after buying the Sentinel M4.
- Outlines: a gameplay frame with 1:1 crops of a near soldier, the helicopter and villagers.
Kept outside the project folder with the other review captures.

## Known gaps
- No physical gamepad tested for LB / Y cycling.
- Store is not available from the mid-stage pause menu. Launcher rounds reuse the grenade
  in-flight art; Rayan's portrait does not change with the selected weapon.

---
# QA report — Firebreak 0.2.1

Date: 15–16 November 2026. Deployed to and tested on the test laptop (Ubuntu 26.04.1,
Mesa 26.0.8, Intel RPL-P graphics, Wayland, 144 Hz panel, GL Compatibility renderer).
**All laptop runs were on battery** (80% → 79%). Development-copy results are further down.

## Laptop results (0.2.1)
- `./tools/test.sh`: 10 suites, **430 checks, 0 failures** (rerun 16 Nov after the deploy).
- `./tools/build-linux.sh`: export built (`build/Firebreak/Firebreak.x86_64`).
- Frame pacing with the 60 fps cap (vsync off on the 144 Hz panel, limiter on). "Raw" counts
  every frame, including the frames where a PNG capture was saved:

| Run | Length | Frames | Avg fps | 1% low fps | Frames > 18 ms | Worst frame |
|---|---|---|---|---|---|---|
| perf (no captures; stage cleared at 1:38, 80 kills, no villagers hit) | 99 s | 5951 | 59.97 | 50.3 | 123 (2.1%) | 76.4 ms |
| v021 (title, pause, 5 gameplay captures) | 26 s | 1540 | 60.2 | 45.9 | 55 (3.6%) | 38.9 ms |
| firing (12 captures of enemy fire) | 23 s | 1415 | 60.5 | 49.3 | 59 (4.2%) | 51.5 ms |

  With capture frames excluded, the 1% low was 60.0 / 60.0 / 59.6 fps.
  Most slow frames are 18–21 ms; one 60 ms spike in the perf run.
- Screenshots (real, laptop): `qa/laptop/v021/v021-*.png` and `firing-*.png`. The firing frames
  show front-facing soldiers and the door gunner's round reaching the lower screen edge, with the
  hit vignette and edge marker.

## What changed
- Enemies face and fire at the player: new front/three-quarter aim and fire poses for riflemen
  (standing and kneeling), the MG nest and descending paratroopers; figures left of centre are
  mirrored so every barrel turns in toward the player. Facing is updated every frame with an
  80 px dead zone at the centre (no flicker while the camera scrolls).
- Enemy fire is shown coming at the player: star muzzle flash at the barrel, a round that
  streaks from the barrel to the lower screen edge and widens as it nears the camera, a flash
  and sparks at the edge on a hit (dust on a miss), and a red edge marker on the side the shot
  came from. Shot targets use a separate cosmetic RNG, so spawns, hits and scores are unchanged.
- Grey fringe removed from the big explosion sprite (`tools/art/defringe.py`).
- Near soldiers 1.08× band scale (was 0.95); ambient riflemen every 1.25–2.1 s (was 1.7–2.7 s),
  up to 9 alive (was 7); two early waves slightly larger.

## Automated tests: 10 suites, **430 checks, 0 failures** (development copy and laptop)
New suite `test_facing` (21 checks): every rifleman/MG/paratrooper placed across all bands faces
the player's side and its barrel points in toward the player (MG: straight out at the camera);
soldiers on opposite sides are mirrored; every enemy shot ends low on the screen toward the
player and the hit-marker side matches the shooter; aiming/firing frames are never side poses;
all 10 front poses load; facing flips at most once as the camera scrolls past; helicopter
door-gunner rounds also come out at the player. Other suites unchanged and passing.

## Development-copy runs (llvmpipe, not representative of real GPUs)
Four autoplay captures: 44–49 fps average, as with 0.2.0 on the same renderer.

## Not tested in 0.2.1
- Running on AC power (laptop numbers are on battery).
- A human playthrough of the new density; gamepad; Windows.

---

# QA report — Firebreak 0.2.0

Date: 15 November 2026. Machine: test laptop, Ubuntu 26.04.1, Mesa 26.0.8,
Intel Graphics (RPL-P), 144 Hz built-in display, GNOME Wayland session, Godot 4.7.2 official.
**All laptop runs below were on battery** (AC unplugged, 78% → 73%, "balanced" power profile).

## Automated tests (`./tools/test.sh`, headless, isolated user folders)

All 9 suites passed on the laptop and on the development copy: **409 checks, 0 failures**.

| Suite | Checks | Covers (new in 0.2.0 in bold) |
|---|---:|---|
| test_art_audio | 78 | **every sprite/vehicle/UI file loads, no child sprites are loaded or spawned, mipmaps on, sprite metadata matches the files, all 50 audio files present, title intro→loop, music on/off/track, voice rate limit** |
| test_combat | 36 | hit detection by depth, scoring, villager penalty, food, power-ups, reload, grenades |
| test_helicopter | 24 | **Huey passes, hover/leave, door-gunner bursts, smoke at half health, crash, one kill, scaling with difficulty** |
| test_input_map | 62 | defaults incl. **grenade Space/RMB/G/pad B/LT, air strike E/MMB/pad RB**, remap/save/reset (the old v0.1 controls file being ignored is not covered by a test) |
| test_main_scene | 34 | title → stage → pause (**music options persisted**) → result; scores; settings; missing audio |
| test_spawning | 25 | depth scale, ground zones, paratroopers, full timeline (incl. heli) |
| test_stage_data | 85 | campaign, stage 1 validation, **truck never parks on the painted truck** |
| test_stage_flow | 32 | timer, idle loss, bot clears (5 seeds), determinism, pause |
| test_weapons | 33 | **5 starting grenades, radius 445 px (≈30% of the screen area), grenades hurt civilians, air strike: 1 per stage + drop, destroys every on-screen enemy/vehicle/heli, never civilians or pickups** |

## Exported Linux build

`./tools/build-linux.sh` exported `build/Firebreak/Firebreak.x86_64` (≈101 MB, pck embedded),
no export errors.

## Frame rate at the 60 fps cap (exported build, 1920×1080 window, autoplay)

Timing is wall-clock between frames (not Godot's smoothed delta); the first 30 frames and the
2 frames after each PNG capture are excluded.

**Final build** — on this 144 Hz panel the game turns vsync off and uses the 60 fps limiter
(see "Frame pacing" below):

| Run | Stage section | Frames | Avg fps | 1% low fps | Frames > 18 ms | Worst |
|---|---|---:|---:|---:|---:|---:|
| perf (no captures) | 0:00–1:50 (incl. Huey pass) | 6561 | 60.0 | 50.9 | 119 (1.8%) | 28.1 ms |
| v020 capture (grenade, air strike, hit, pause, 5 shots) | 1:10–1:37 | 1540 | 60.2 | 49.2 | 46 (3.0%) | 24.6 ms |

**Frame pacing.** With vsync on, a 60 fps cap on a 144 Hz display alternates 13.9 ms and 20.8 ms
frames. Measured before the change (same build otherwise): 110 s run 58.9 fps avg, 1% low 44.7,
1067 of 6433 frames (16.6%) over 18 ms, worst 57.7 ms; two 27 s action runs 58.3/58.4 fps with
about 20% of frames over 18 ms. A test with `--disable-vsync` brought that down to 3%, so the
game now switches vsync off only when the refresh rate is not a whole multiple of 60
(60/120/240 Hz displays keep vsync). Under GNOME Wayland the compositor prevents tearing; on an
X11 session without a compositor, tearing is possible on such displays (not tested).

One earlier capture run (vsync on) averaged 45.9 fps; it did not repeat in three later runs. The GPU
was idling at 300 MHz on battery just before; the cause is not confirmed.

## Screenshots (real, from the laptop runs; in `qa/laptop/v020/`)

title, gameplay with painted sprites and the Huey, grenade blast, air strike, pause menu with
music options, hit vignette (from `--qa-hurt-at`, which applies a real 12-point hit through the
game's own damage function so the effect can be captured on cue).
The autoplay clears soldiers quickly, so the laptop gameplay frames show few of them. A retake with
slower autoplay reactions could not be used: the laptop screen locked as it started, so the
game ran but nothing was presented (all five frames identical); that run was discarded and its
numbers are not reported. Soldier-plus-Huey frames from the development copy (software
renderer, same build) were captured instead and are labelled as such.

## Not tested

- A physical gamepad (bindings are tested only as input events).
- Windows (not built); X11 sessions; other GPUs or a 60 Hz display.
- Running on AC power (all laptop numbers are on battery).
- A full human playthrough; balance is a first pass. Audio was checked for presence, loading and
  sequencing by tests, not listened to on the laptop speakers.
- The snap (not built, by instruction).

## Known issues

- Frames over 18 ms: 1.8–3% remain, mostly brief spikes during explosions and heavy effects.
- ElevenLabs plan not confirmed; NOTICE carries conditional attribution.

---

# QA report — Firebreak 0.1.0

Date: 15 November 2026. Machine: test laptop, Ubuntu 26.04.1, Mesa 26.0.8,
Intel Graphics (RPL-P), 144 Hz built-in display, GNOME Wayland session. Godot 4.7.2 official.

## Automated tests (`./tools/test.sh`, headless, isolated user folders)

All 6 suites passed: **246 checks, 0 failures**.

| Suite | Checks | Covers |
|---|---:|---|
| test_combat | 36 | hit detection by depth, scoring, villager penalty, food healing and cap, all five power-ups, spread shot, MG toughness, reload, out-of-ammo drop, grenades, near vs far enemy damage, aim warning before enemy fire |
| test_input_map | 46 | every action has keyboard/mouse/gamepad defaults, F11, Esc, stick aiming, remap + save + reload + reset |
| test_main_scene | 22 | title → stage → pause/resume → result → controls; top-ten save/sort/cap; settings; missing audio |
| test_spawning | 25 | near/mid/far scale, spawns on real ground zones (not on the river), paratroopers fire while falling and after landing, full timeline spawns every type |
| test_stage_data | 85 | 12-stage campaign, stage 1 validates, ≤ 180 s, background size, difficulty rises on every stage |
| test_stage_flow | 32 | timer never exceeds 180 s, idle player loses, steady bot clears (5 seeds), early quota clear, determinism, pause freezes, slow left-to-right scroll |

## Exported Linux build

`./tools/build-linux.sh` exported `build/Firebreak/Firebreak.x86_64` (78 MB, pck embedded)
with the official 4.7.2 templates; no export errors.

## Real runs of the exported build on the Intel GPU

The exported build was run in a 1920×1080 window on the desktop with the built-in autoplay
(`--qa-run`), which aims at enemies, never at villagers, captures the viewport and writes
a frame-time report, then quits. vsync on. Frames during PNG saving are excluded.

| Run | Stage section | Frames | Avg fps | 1% low fps | Frames > 18 ms | Worst frame |
|---|---|---:|---:|---:|---:|---:|
| laptop-perf (no captures) | 0:00–1:00 | 4394 | 73.7 | 58.6 | 39 (0.9%) | 34.6 ms |
| laptop-b (4 captures) | 1:34–2:19 | 3373 | 77.0 | 48.0 | 96 (2.8%) | 29.1 ms |
| laptop-a (title, pause, 4 captures; capture frames not excluded) | 0:00–1:00 | 4387 | 73.4 | – | 142 (3.2%) | 140 ms (PNG save) |

The game stays above 60 fps on average. On the 144 Hz panel with vsync it settles around
72–77 fps, not 144. Occasional frames exceed 16.7 ms, mostly in the busier second half
(explosions, more figures on screen). Other hardware and drivers are untested.

Screenshots (real, from these runs): `docs/title-screen.png`, `docs/gameplay.png`,
`docs/river-bridge.png`, `docs/pause-screen.png`; all captures are in `qa/laptop/`.
Before the laptop runs, a full real-time autoplay of the whole stage (software renderer on another
machine) reached STAGE CLEAR at 2:04 with 80/80 enemies.

## Not tested

- A physical gamepad (gamepad bindings are tested only as input events).
- Windows (not built).
- A full human playthrough; difficulty balance is a first pass.
- The snap (not built, by instruction).
- Audio playback with real files (none exist yet; the missing-file path is tested).

## Known issues

- All characters, vehicles and pickups are code-drawn placeholders.
- The game's truck can stop next to the truck painted into the background, so two trucks show at once.
- One autoplay run on the laptop closed after 18 s without a report (exit code 0, no error
  logged). It may have been closed from the desktop. The retry ran normally.
