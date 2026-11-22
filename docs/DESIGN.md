# Firebreak — design notes

Operation Wolf-style first-person gallery shooter. You never move: the battlefield pans
slowly left to right while enemies appear at three depths. Twelve stages are planned; each
stage lasts at most three minutes and the difficulty rises stage by stage.

## Stage rules (data-driven)

Each stage is a JSON file in `data/stages/` listed in `data/campaign.json`:

- `duration` (≤ 180 s), `enemy_quota` (kills to clear), `background`, `music`, `ambience`.
- `scroll`: camera keyframes `[time, x]`; holds = combat beats. Eased between keys.
- `bands`: `far`, `mid`, `near` each with `scale`, `damage`, `hit_chance`, `score_mult` and
  `zones` `[x_start, x_end, ground_y]` in panorama pixels, so people stand on real ground
  (not on the river) at the right size for their depth.
- `waves`: scripted spawns `{t, type, band, count, interval, kind, world_x, world_y, scale}`.
- `ambient`: background spawners `{type, every[min,max], from, until, max_alive, bands|kinds}`.
- `light`: tint and atmospheric haze applied to figures so they sit in the scene's light.

Difficulty per stage comes from `campaign.json` → `difficulty`: accuracy, damage, density,
fire_rate, enemy_hp and quota grow per stage; the enemies' warning time shrinks.

## Stage end

- Kill quota reached → STAGE CLEAR (bonus for health, time left and accuracy; the time and accuracy terms are rounded to a multiple of 10 so every score is a multiple of 10).
- Timer reaches 0 while alive → STAGE CLEAR ("held the line").
- Health 0 → MISSION FAILED.

## Entities

| Type | Behaviour | HP | Score |
|---|---|---:|---:|
| Rifleman | Rises from cover, aims (red warning ring), fires 2–3 times, ducks away | 1 | 100 |
| MG nest | Fixed sandbag position; aims, fires sustained bursts, never leaves | 3 | 400 |
| Paratrooper | Drops with a canopy, fires while descending, keeps firing after landing | 1 | 200 (+100 mid-air) |
| Truck | Drives in, stops, fires bursts from the cab | 14 | 1500 |
| Villager | Walks through; shooting one costs 10 health and 500 score | – | –500 |
| Food | Falls from the sky; shooting it heals (rice 15, fruit 10, water 8, ration 25) | – | 50 |
| Power-up | ammo (+2 mags), grenades (+2), rapid fire (20 s), spread shot (20 s), power (+damage) | – | 50 |

Band multipliers: far ×1.5, mid ×1.2, near ×1.0 score. Near enemies hit hardest.

## Planned stages (environments to be chosen)

1. River Village (0.1.0, art/weapons/helicopter in 0.2.0, front-facing enemies in 0.2.1) · 2–12: to be decided with the owner.

## Campaign score and the global top 100

Score is added up across one campaign run (today that is just stage 1). A new run starts from the title or Store “Start mission” button. The optional global top 100 at firebreak.quietbytehq.uk accepts campaign scores of 2,000 or more. The player can keep a score on their computer only. Scores are not verified: the game is open source.
