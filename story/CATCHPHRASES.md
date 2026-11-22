# Firebreak — new Rayan catchphrases (0.3.2 draft)

For approval. Do not generate audio until the owner says so.
Voice: the same ElevenLabs "Flint - Commanding Presence" (eleven_v4)
already used for Rayan. Original lines, no impressions.

Existing lines (already in the game, always available):

| File | Line | When |
|---|---|---|
| rayan_lock_and_load | Lock and load. | Stage start |
| rayan_airstrike_now | Air strike, now! | Air strike |
| rayan_fire_in_the_hole | Fire in the hole! | Grenade |
| rayan_care_package | Got a care package. | Food / power-up |
| rayan_that_all_you_got | That all you got? | Gunner or chopper down |
| rayan_watch_the_civilians | Watch the civilians! | Civilian hit |
| rayan_mission_complete | Mission complete. | Stage clear |
| rayan_hit_grunt_01..03 | (wordless grunts) | Player is hit |

New lines, unlocked by stages cleared (`profile.stages_cleared`).
A line in a later tier also stays available in the tiers after it.

## Tier 1 — from the start (stages 1–3)

| Suggested file | Line | When | Chars |
|---|---|---:|---:|
| rayan_keep_your_head_down | Keep your head down. | Health falls below 30% | 20 |
| rayan_nests_down | Nest's down. | MG nest destroyed | 12 |
| rayan_chopper_inbound | Chopper inbound. | Helicopter appears | 16 |

## Tier 2 — after clearing stage 3 (used in stages 4–7 and later)

| Suggested file | Line | When | Chars |
|---|---|---:|---:|
| rayan_still_standing | Still standing. | Survives a heavy hit, health still above 30% | 15 |
| rayan_clean_shot | Clean shot. | Killing headshot (pairs with the CLEAN SHOT banner) | 11 |
| rayan_theyre_breaking | They're breaking. | A streak of 5 kills | 17 |
| rayan_not_today | Not today. | Narrowly survives (health was below 20% and a pickup or clear follows) | 10 |

## Tier 3 — after clearing stage 7 (used in stages 8–12)

| Suggested file | Line | When | Chars |
|---|---|---:|---:|
| rayan_this_is_the_firebreak | This is the firebreak. | Stage start, stages 8–12 | 22 |
| rayan_one_more_push | One more push. | Late in a late-campaign stage (last 30 seconds or quota almost reached) | 14 |
| rayan_almost_over | Almost over. | Stage 12 start, or the last wave of Ember Yard | 12 |

## Award line — after the Stage 10 ceremony

| Suggested file | Line | When | Chars |
|---|---|---:|---:|
| rayan_ill_wear_it | I'll wear it. Then we finish this. | End of the award interlude | 34 |

## Character count

Spoken text of the 11 new lines, including spaces and punctuation:
**183 characters.**

ElevenLabs bills by characters sent to the model. This is a small job
next to the existing music and gun sounds. Generate only after the
owner confirms the wording and the account credits.
