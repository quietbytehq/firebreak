# Changelog

All notable changes to Firebreak are listed here. Version numbers follow the
game's public releases.

## 0.5.0 — 24 November 2026

- Stage 3, Coral Coast, is playable. A Caribbean bay at golden hour: an open
  beach, a pastel town with a long wooden pier, and a harbour. After Dune Sea
  the travel map offers Coral Coast next; clearing it previews Iron Harbour as
  coming soon.
- New enemies: gang riflemen, pier gunners, weaving speedboats and a beach jeep
  with a bed gunner. Townspeople walk the sand and must not be shot.
- The gunboat is a stop-the-scroll arena boss. The camera holds on the harbour
  from 2:20, and the stage ends only when the gunboat is destroyed (or you fall).
  Meeting the kill quota or running past three minutes does not clear the stage
  while the gunboat is still afloat. The gunboat is larger and closer, out in
  the deep harbour basin, with more health and a second deck gunner.
- Stage 3 is harder than Dune Sea: quota 128, and fire rate and spawn density
  are raised a further 15% on top of the campaign curve. Ammo drops stay rare,
  and there are more civilians in the crossfire.
- Anyone standing in the water is waist-deep: the sprite is clipped at the
  waterline with a ripple, and they shoot from there. Boat crews stay in their
  boats. River Village and Dune Sea are audited the same way.
- Civilians walk only on land, always facing the way they are going. Killing
  3 civilians fails the stage on every map, with an on-screen "CIVILIAN DOWN"
  warning after the first and second. The result screen names the reason.
- Each run has 3 continue diamonds on the HUD. Failing a stage (by dying or by
  the civilian rule) offers Continue, which spends one diamond and restarts
  that stage. With none left it is game over, and the run high score is saved
  as it stands. There is no store or real-money tie-in.
- Stage music is "Caribbean Steel Drums 2" by Tozan (CC0). Bay ambience and
  vehicle loops are also CC0; credits are in NOTICE. No ElevenLabs audio.
- The 0.4.1 name-at-start and automatic high-score save still apply, including a
  per-stage tab for Coral Coast.

## 0.4.1 — 24 November 2026

- After you press Start, the game asks for your name once, before the mission.
  The box is filled with the last name you used, so you can usually just press
  Enter. A Change name option on the title menu lets you edit it later.
- The result screen no longer asks for a name. Qualifying stage scores are saved
  automatically under the name you chose. The overall run table is written only
  when a run ends (you fail, finish the last stage, or leave for the title).
  The optional global top 100 uses the same name and still never blocks.
- The title screen shows a tabbed local board (the run top ten, plus a top ten
  for each playable stage) and a Change name control above it.

## 0.4.0 — 22 November 2026

- Stage 2, Dune Sea, is playable. High noon over dunes, an oasis and a mud-brick
  village. After River Village, the travel map offers Dune Sea next; clearing
  Dune Sea previews Coral Coast as coming soon.
- New enemies: militia in shemaghs, rooftop snipers, camel scouts (at most two
  at once) and a pickup technical with a bed gunner. A convoy truck is the
  mid-boss. There is no helicopter on this stage.
- Robed adult civilians still cost a health and score penalty. Dates, bread and
  a waterskin drop as health pickups, alongside ammo.
- A cheap heat-shimmer on the panorama, and a short dust-storm beat near the
  village. Near, mid and far bands, sticker outlines, head shots and catchphrases
  work as they did on stage 1. Near enemies still stand above the bottom HUD.
- Campaign scoring is unchanged: totals add across a run, and the optional
  global board still ranks one campaign score with a 40,000-point cap per stage.
- Stage 2 music and desert effects are third-party CC0 recordings (see NOTICE):
  Darbuka Delight by Adiutorium, with Desert Loop by iamoneabe as a backup, plus
  truck, wind, gust, camel and falling-brick sounds. No new ElevenLabs audio.
- The Godot app icon (`assets/ui/icon.png`) now uses the same palette-quantised
  512 px artwork as the store icon, so it stays under the Snap Store's 256 kB
  listing limit.

## 0.3.7 — 22 November 2026

- One START button. The skippable Ember Ring briefing plays the first time you
  start; rewatch it with F1 on the title or from the pause menu.
- Near enemies stand above the health and weapon bars and draw in front of the
  first-person gun, so they stay fully visible.
- A spoken announcer call, "FIREBREAK! Cut the Ember Ring.", plays once per
  launch over the title music.
- The title shows this computer's local high scores and a GLOBAL SCORES control
  that opens the public board in the system browser.
- The briefing's dark text panel fades into the map.
- App icon: a flaming F in the title's action-comic style, shipped as 512×512 and
  256×256 PNG plus an SVG, and used as the window, desktop, snap and listing icon.
- Linux packaging: tar.gz, `.deb` and (in CI) an AppImage, plus a Snap Store
  package named `firebreak-game` (network plug for the scoreboard). A tag push
  builds the packages, attaches them to a GitHub pre-release, and uploads the
  snap to the `edge` channel. A Windows zip is also produced; it is untested
  and not supported.

## 0.3.6 — 22 November 2026

- Cinematic title theme (intro plus loop).
- Opening briefing and a 12-stage travel map for the Ember Ring campaign.
- Compact military HUD plates, icons and the Barlow Condensed typeface.
- Title subtitle: "CUT THE EMBER RING".

## 0.3.5 — 22 November 2026

- Rayan is blended into the mission-failed and stage-clear screens.
- Bullet tracers removed; larger muzzle flash, sparks and barrel smoke.

## 0.3.4 — 22 November 2026

- Civilians face the way they walk; white sticker outlines on characters.
- First-person rear firing views, with a side reload pose on magazine guns.
- Head shots with a CLEAN SHOT bonus; popping score and streak callouts.
- Pricier guns never hit softer than cheaper ones of the same type.
- Eleven Rayan catchphrases that unlock as stages are cleared.

## 0.3.3 — 22 November 2026

- Optional global top 100 for campaign scores (minimum 2,000), with a
  Cloudflare Worker and a name-entry opt-out.

## 0.3.1 — 16 November 2026

- First-person view of the selected weapon in Rayan's arms.
- Pausing freezes game audio and plays a pause-menu track.

## 0.3.0 — 16 November 2026

- 19 original weapons in a 3-slot loadout, cash economy and Store.
- Ink outlines on characters, the helicopter and pickups.
