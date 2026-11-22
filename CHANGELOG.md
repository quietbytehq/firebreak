# Changelog

All notable changes to Firebreak are listed here. Version numbers follow the
game's public releases.

## Unreleased

- App icon revised: the flaming gold F stays the hero, with a quieter bust of
  Rayan (blond hair, black sunglasses) and a generic Kalash-style rifle behind
  it. Shipped as 512×512 and 256×256 PNG. The SVG was dropped because a vector
  no longer matches the painted composition.

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
