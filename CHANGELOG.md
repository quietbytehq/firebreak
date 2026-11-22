# Changelog

All notable changes to Firebreak are listed here. Version numbers follow the
game's public releases.

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
