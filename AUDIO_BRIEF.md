# FIREBREAK — audio brief and catalogue

**Status (0.3.1): every sound below is generated and bundled in `assets/audio/`; 0.3.0 added 30 weapon, reload, dry-fire, cash and store sounds; 0.3.1 adds the pause-menu track `music_pause` (last section).** Music, effects and
Rayan's voice were made with ElevenLabs on 15 November 2026. Licence terms are in `NOTICE`; the
ElevenLabs plan has not been confirmed yet, so the attribution line there is conditional.

The game loads `res://assets/audio/<base>.ogg|.wav|.mp3`, or the same names from an `audio/` folder next to
`Firebreak.x86_64` (an override for exported builds). Any missing file is simply silent. Replacement takes
should keep the base names. Effects are peak-normalised to about -1.5 dBTP; voice lines to about -16 LUFS.

## Music

| Base name | Use | Notes |
|---|---|---|
| music_title_intro | Title screen, plays once (0.3.6 replacement) | 12.75 s opening: war drums and heroic brass. |
| music_title_intro_loop | Title screen and briefing after the intro (0.3.6) | 30.75 s martial loop, crossfaded, no fade-out. |
| title_call | Title screen, once per launch (0.3.7) | Announcer: “FIREBREAK! Cut the Ember Ring.” 3.28 s. |
| music_bg_01 | In-game track 1 (default) | Mid-tempo jungle combat: tribal drums, tense strings, gritty guitar. Loops. |
| music_bg_02 | In-game track 2 | Faster 80s action synth and rock. Loops. |
| music_bg_03 | In-game track 3 | Darker, suspenseful: drones, ticking percussion, slow build. Loops. |
| music_pause | Pause menu (0.3.1) | Calm 70 BPM pad, clean guitar and soft pulse, 58 s seamless loop. Plays only while paused. |

The pause menu turns music on or off, picks track 1, 2 or 3, and sets music and effects volume; the
choice is saved in `user://settings.cfg`. The 0.1.0 names `music_title` and `music_stage1` are no longer used.

## Sound effects

| Base name | Length | Loop | When the game plays it | Prompt used |
|---|---:|:---:|---|---|
| fire | 0.480s | no | Player shot (normal weapon) | One close-miked player assault rifle shot: sharp dry crack, short mechanical bolt clack, tiny tail. No echo, no music, no voice. |
| reload | 0.930s | no | Reload starts | Rifle magazine change, close-miked and dry: release click, empty magazine sliding out, fresh magazine seated with a firm metallic clunk, charging handle pulled and released. No voice. |
| empty_click | 0.480s | no | Trigger with no ammo | Single dry-fire click of an empty rifle: small hollow metallic click only. No other sounds, no voice. |
| ricochet | 0.480s | no | Missed shot | Bullet striking dirt and grass: soft thud, puff of debris, faint whizzing ricochet. Not loud. No voice. |
| hit_metal | 0.452s | no | Bullet hits MG nest, truck or helicopter | Bullet hitting a steel sandbag frame or truck panel: bright metallic ping with a short ringing tail. No voice. |
| enemy_rifle | 0.480s | no | Enemy rifle, mid band (volume by depth) | A rifle firing from about 50 metres across open paddy fields: thinner crack, slight valley echo tail. No voice. |
| enemy_mg | 1.360s | no | MG nest / truck burst (once per burst, volume by depth) | A distant mounted machine gun firing one steady burst of about 10 rounds, heavy rhythmic chatter, short open-air echo at the end. No voice. |
| enemy_down | 0.600s | no | Soldier knocked down | A soldier knocked down, non-graphic: body and gear dropping onto soft earth, canteen and webbing rattle. No voice, no scream. |
| player_hit | 0.480s | no | Rayan is hit | First-person bullet impact thud: muffled low thump, a sharp whip of a near-miss, brief ringing. Tense. No voice. |
| villager_penalty | 0.800s | no | Civilian hit sting | Serious warning sting for hitting a civilian: low dissonant brass-and-string stab with a quick fade. Not comedic. No voice. |
| pickup_food | 0.545s | no | Food drop shot | Supply crate of food caught: woven basket rustle, soft wooden knock, warm gentle chime. Reassuring. No voice. |
| pickup_power | 0.680s | no | Power-up drop shot | Weapon upgrade collected: metal ammo box latch snapping shut, rifle bolt racked, short bright rising shimmer. No voice. |
| grenade_throw | 0.480s | no | Grenade thrown | Grenade pin pulled with a tiny metal ping, spoon flicking off, quick throw whoosh. No voice. |
| explosion | 1.600s | no | Grenade, MG nest, truck and helicopter blasts | Grenade explosion at mid distance: deep thump, debris and dirt raining down, rolling jungle echo. Powerful but not distorted. No voice. |
| parachute_open | 0.800s | no | Paratrooper appears | A parachute canopy snapping open high above: fabric whump and flutter, wind. No voice. |
| truck_engine | 3.480s | no | Truck drives in | An old military cargo truck approaching on a dirt road: rough diesel engine, gear crunch, rattling body panels, fades in. No voice, no horn. |
| stage_start | 2.000s | no | Stage starts | Mission start sting: low military snare roll into one bold brass chord over distant helicopter rotors. Original, no vocals, no famous melody. |
| stage_clear | 3.480s | no | Stage clear | Stage cleared fanfare: proud restrained brass and snares that resolve warmly, dusk atmosphere. Original, no vocals, no famous melody. |
| game_over | 3.480s | no | Mission failed | Mission failed sting: slow low strings and a muted horn falling to a quiet minor chord. Sombre, not melodramatic. No vocals. |
| ui_move | 0.480s | no | Menu focus | Tiny dry metallic switch click, like a radio dial tick. Single short click only. |
| ui_select | 0.480s | no | Menu confirm / PRESS START | Menu confirm: firm radio-set toggle clack with a short warm thump. No voice. |
| ambience_river | 30.00s | yes | Stage 1 ambience loop | Seamless looping jungle river village at dusk: insects and frogs, distant birds settling, gentle water lapping, faint wind in palm fronds, very distant rotor thrum now and then. No voices, no gunfire, no music melody. |
| fire_rapid | 0.468s | no | Player shot while RAPID is active | One close-miked light automatic rifle shot, very short dry crack and bolt clack, tiny tight tail, clean when fired in a rapid stream. No echo, no voice. |
| fire_spread | 0.600s | no | Player shot while SPREAD is active | One close-miked combat shotgun blast: heavy punchy boom with a brief pellet spray, short dry tail. No echo, no voice. |
| enemy_rifle_near | 0.480s | no | Enemy rifle, near band | A rifle firing close, about 10 metres: loud dry crack, short mechanical bolt, little echo. No voice. |
| enemy_rifle_far | 0.600s | no | Enemy rifle, far band (quieter) | A rifle firing far away across a valley, about 150 metres: thin delayed crack, long airy echo tail, quiet. No voice. |
| airstrike_jet | 2.979s | no | Air strike called: jets fly over | Military jet flyby roar: approaching turbine scream, close pass overhead, Doppler receding tail. No voice, no gunfire, no music. |
| airstrike_whistle | 1.480s | no | Bombs falling (0.45 s after the call) | A bomb falling: descending whistle that drops in pitch, air rushing, no explosion yet, no voice. |
| airstrike_explosion | 2.480s | no | Bombs land | Large mid-distance napalm-style air-strike explosion: deep booming thump, rolling fire roar, dirt and debris, jungle echo. Powerful, not distorted, no voice, no screams. |
| helicopter_rotor | 8.000s | yes | Loop while a helicopter is on screen | Seamless looping Huey-style military helicopter rotor wash: deep rhythmic blade chop, turbine whine, consistent loudness. No voices, no gunfire, no music. |
| helicopter_mg | 1.480s | no | Door gunner burst (once per burst) | A door-mounted machine gun firing a short burst from a flying helicopter: heavy rhythmic chatter with some rotor wash in the background. No voice. |
| helicopter_crash | 2.480s | no | Helicopter shot down | A military helicopter crashing in flames: metal tearing, rotor straining, heavy explosion, wreckage raining down. No voice, no screams. |
| heartbeat | 6.000s | yes | Loop while health is under 30% | Seamless looping first-person low-health heartbeat: close muffled thump-thump, tense and steady, no other sounds. |
| villager_gasp | 0.600s | no | Civilian hit (non-graphic gasp) | A short non-graphic human gasp of pain, startled and brief, not a scream, not a shout, no words. |
| ui_pause | 0.480s | no | Pause menu opens | Pause menu open: soft low whoosh and a muted mechanical clack, short and clean. No voice. |

## Rayan voice lines

Voice: ElevenLabs Voice Library "Flint - Commanding Presence" (eleven_v4). Original lines, no
impressions of real actors. Lines are rate-limited: at most one line every 2.5 s, each line has its own
cooldown, and only key moments (stage start, air strike, civilian hit, stage clear) skip the shared gap.

| Base name | Length | When the game plays it | Direction / line |
|---|---:|---|---|
| rayan_lock_and_load | 1.377s | Stage start | [gruff, commanding, close-miked] Lock and load. |
| rayan_airstrike_now | 1.447s | Air strike called (always plays) | [urgent, over a military radio, gruff] Air strike, now! |
| rayan_fire_in_the_hole | 1.386s | Grenade thrown (6 s cooldown) | [shouting, urgent, gruff] Fire in the hole! |
| rayan_care_package | 1.691s | Food / power-up collected (25 s cooldown) | [satisfied, gruff, close-miked] Got a care package. |
| rayan_that_all_you_got | 1.509s | Door gunner or helicopter down (20 s cooldown) | [taunting, ruthless, gruff] That all you got? |
| rayan_watch_the_civilians | 1.569s | Civilian hit (10 s cooldown) | [urgent warning, firm, gruff] Watch the civilians! |
| rayan_mission_complete | 1.646s | Stage clear | [relieved, firm, gruff] Mission complete. |
| rayan_hit_grunt_01 | 0.589s | Hit taken (random grunt, 45% chance, 3 s cooldown) | [short pained grunt, no words, close-miked] Ngh. |
| rayan_hit_grunt_02 | 0.785s | Hit taken (random grunt) | [heavier pained grunt, no words, close-miked] Ugh. |
| rayan_hit_grunt_03 | 0.625s | Hit taken (random grunt) | [sharp sudden pained grunt, no words, close-miked] Ah. |

## Gunshots by depth

Enemy gunshots are quieter the farther away the shooter is: near band 0 dB, mid about -6 dB,
far about -12 dB (before the per-sound offset), and the near/far rifle variants are used for those bands.

## 0.3.0 weapon, store and economy sounds

Generated with ElevenLabs Sound Effects (eleven_text_to_sound_v2) on 16 November 2026 in one creative
flow, 2 takes per sound (4 for six fire sounds whose first takes were nearly silent). The take with a
usable level and the hardest attack was kept (processing script kept outside the project). Processing: trim leading silence, 4 ms fade-in, 60 ms fade-out, peak
normalise to -1.5 dBTP, then raise quiet takes by up to 9 dB (fire) / 6 dB (others) towards a loudest-50 ms
RMS of -9 dBFS (fire) / -14 dBFS (others) behind a -1.5 dB limiter; OGG Vorbis q6, 48 kHz.
Frag Grenades keep the existing `grenade_throw`; the Air Strike keeps the jet, whistle and explosion sounds.

Credits: 162.3 ElevenLabs credits for 60 generations (sum of the per-generation prices
reported by the API; the account usage endpoint is not available to this connection).

| Base name | Length | Used by | Take | Credits | Prompt of the kept take |
|---|---:|---|---:|---:|---|
| wpn_viper_9_fire | 0.68s | Viper 9 | 4/4 | 8.7 | Loud gunshot: a 9mm pistol fired once right next to the microphone. Hard punchy bang with a deep thump and a quick metallic slide clack, short dry tail. Very loud, full volume. No voice, no music. |
| wpn_talon_50_fire | 0.88s | Talon .50 | 1/2 | 6.0 | One close-miked huge .50 calibre hand-cannon pistol shot: enormous booming blast, heavy low-end punch, metallic slide slam, short rolling tail. No voice, no music. |
| wpn_warden_1911_fire | 0.68s | Warden 1911 | 3/4 | 9.3 | Loud gunshot: a heavy .45 calibre steel pistol fired once next to the microphone. Deep round boom, heavy slide clack, warm short tail. Full volume. No voice, no music. |
| wpn_kestrel_p9_fire | 0.60s | Kestrel P9 | 1/2 | 4.0 | One close-miked 9mm service pistol shot: bright crisp crack, light slide snap, short clean tail. No voice, no music. |
| wpn_rook_revolver_fire | 0.88s | Rook Revolver | 2/2 | 6.0 | One close-miked .357 magnum revolver shot: loud sharp bark with a ringing steel cylinder, no slide, short echo tail. No voice, no music. |
| wpn_hornet_9_fire | 0.48s | Hornet 9 | 3/4 | 6.7 | Loud gunshot: one single shot from a 9mm submachine gun fired next to the microphone. Tight punchy pop with a crisp mechanical clack, very short dry tail. Full volume. No voice, no music. |
| wpn_buzzsaw_fire | 0.47s | Buzzsaw | 2/2 | 3.3 | One single shot from a boxy open-bolt 9mm submachine gun, close-miked: rattly hollow crack with a heavy bolt slap, short dry tail. No voice. |
| wpn_stinger_v_fire | 0.48s | Stinger V | 4/4 | 6.7 | Loud gunshot: one single shot from a compact .45 submachine gun fired next to the microphone. Snappy thud with a quick hiss of the recoil buffer, extremely short tail. Full volume. No voice, no music. |
| wpn_mamba_90_fire | 0.48s | Mamba 90 | 1/2 | 3.3 | One single shot from a futuristic bullpup personal defence weapon with small high-velocity rounds, close-miked: sharp zippy crack, light plastic body rattle, very short tail. No voice. |
| wpn_ratchet_mac_fire | 0.48s | Ratchet Mac | 1/2 | 3.3 | One single shot from a tiny boxy machine pistol, close-miked: harsh buzzy bark with a metallic stamped-steel rattle, very short tail. No voice. |
| wpn_kalash_47_fire | 0.68s | Kalash 47 | 2/2 | 4.7 | One close-miked 7.62 calibre assault rifle shot: heavy chunky crack with a loose rattly bolt clack and a short gritty tail. Raw and powerful. No voice. |
| wpn_sentinel_m4_fire | 0.60s | Sentinel M4 | 4/4 | 8.0 | Loud gunshot: one 5.56 carbine shot fired next to the microphone. Very sharp bright crack with a tight spring ping, short clean tail. Full volume. No voice, no music. |
| wpn_granite_g3_fire | 0.80s | Granite G3 | 2/2 | 5.3 | One close-miked heavy 7.62 battle rifle shot: very loud deep boom with a hard roller-bolt clank and a short echo. Heavy hitting. No voice. |
| wpn_longshot_700_fire | 1.28s | Longshot 700 | 1/2 | 8.7 | One bolt-action marksman sniper rifle shot fired close: massive sharp crack with a long rolling echo across a valley, then the bolt worked open and closed. No voice. |
| wpn_thunder_m60_fire | 0.68s | Thunder M60 | 2/2 | 4.7 | One single shot from a belt-fed general purpose machine gun, close-miked: heavy thudding bang with ammunition belt links clinking, short tail. Clean when repeated. No voice. |
| wpn_hammer_rpg_fire | 1.48s | Hammer RPG | 1/2 | 10.0 | A shoulder-fired rocket launcher firing close: sharp launch pop, then a loud roaring rocket whoosh flying away. No explosion, no voice. |
| wpn_tankbuster_fire | 1.76s | Tankbuster | 1/2 | 12.0 | A heavy recoilless anti-tank launcher firing close: huge deep concussive bang with a blast of back-pressure, then a heavy rocket roar flying away. No explosion, no voice. |
| wpn_thumper_gl_fire | 0.80s | Thumper GL | 3/4 | 10.7 | Loud 40mm grenade launcher shot fired next to the microphone: big hollow deep thoomp like a huge cork popping from a steel tube, short whistle as the round leaves. Full volume. No explosion, no voice. |
| reload_pistol | 1.08s | Reload: Viper 9, Talon .50, Warden 1911, Kestrel P9, Rook Revolver | 1/1 | 3.7 | Pistol magazine change, close-miked and dry: magazine release click, empty magazine dropping out, fresh magazine slapped in, slide released forward with a snap. No voice. |
| reload_smg | 1.21s | Reload: Hornet 9, Buzzsaw, Stinger V, Mamba 90, Ratchet Mac | 1/1 | 4.3 | Submachine gun reload, close-miked and dry: curved magazine pulled out, new magazine clicked in, cocking handle slapped down. No voice. |
| reload_rifle | 1.25s | Reload: Kalash 47, Sentinel M4, Granite G3, Longshot 700 | 1/1 | 5.0 | Assault rifle magazine change, close-miked and dry: release click, heavy magazine sliding out, fresh magazine rocked in with a firm clunk, charging handle racked. No voice. |
| reload_mg | 2.00s | Reload: Thunder M60 | 1/1 | 7.3 | Belt-fed machine gun reload, close-miked: feed cover snapping open, ammunition belt links rattling into the tray, heavy cover slammed shut, charging handle pulled. No voice. |
| reload_launcher | 1.76s | Reload: Hammer RPG, Tankbuster, Thumper GL | 1/1 | 6.0 | Rocket launcher reload, close-miked: heavy metal tube shouldered, a rocket slid into the tube with a scrape and a locking clunk, latch click. No voice. |
| dry_pistol | 0.48s | Dry fire: Viper 9, Talon .50, Warden 1911, Kestrel P9, Rook Revolver | 1/1 | 1.7 | Single dry-fire click of an empty pistol: small sharp metallic click only. No other sounds, no voice. |
| dry_rifle | 0.48s | Dry fire: Hornet 9, Buzzsaw, Stinger V, Mamba 90, Ratchet Mac, Kalash 47, Sentinel M4, Granite G3, Longshot 700, Thunder M60 | 1/1 | 1.7 | Single dry-fire click of an empty assault rifle: hollow metallic trigger click with a slight spring rattle. No other sounds, no voice. |
| dry_launcher | 0.48s | Dry fire: Frag Grenades, Hammer RPG, Tankbuster, Thumper GL | 1/1 | 1.7 | An empty grenade or rocket launcher trigger pulled: heavy dull mechanical clunk, nothing fires. No voice. |
| cash_pickup | 0.80s | Money drops and kill bounties | 1/1 | 2.7 | Cash bundle collected in an action game: crisp banknotes riffled, a couple of coins clinking, short bright rising sparkle. Satisfying. No voice, no music. |
| store_purchase | 1.00s | Store: purchase | 1/1 | 3.3 | Weapon bought in a military gun store: old mechanical cash register cha-ching followed by a weapon being racked with a confident clack. No voice, no music. |
| store_denied | 0.60s | Store: not enough cash / full | 1/1 | 2.0 | Purchase refused in a game menu: low short muted double buzz, like an old military radio rejecting input. No voice, no music. |
| weapon_switch | 0.48s | Changing weapon slot | 1/1 | 1.7 | Quick weapon swap: leather holster rustle, a gun drawn and gripped, short metallic handling click. No voice. |

A preview montage of the 18 fire sounds (store order, 0.45 s gaps) and the original MP3 takes are kept outside the project folder.

Since 0.3.0 the older `fire`, `fire_rapid`, `fire_spread`, `reload` and `empty_click` files are only fallbacks
(played if a weapon's own sound is missing). The game plays each weapon's fire sound at -4 dB (-6 dB for
weapons firing 9 or more rounds a second), its reload and dry-fire group sound, `weapon_switch` at -6 dB,
`cash_pickup` for money drops (and very quietly, pitched up, for kill bounties), and the store sounds.

## 0.3.1 pause-menu music

`assets/audio/music_pause.ogg` (58.0 s loop, OGG Vorbis q6, 48 kHz stereo, -15.9 LUFS integrated, -4.5 dBFS peak).
Generated with ElevenLabs Music (eleven_music_v2_5) on 16 November 2026 in a creative flow; one 60 s
music generation produced **4 takes at 900 credits each = 3,600 credits** (the node returns four takes per
run; the account usage endpoint is not available to this connection, so this is the sum of the prices the
API reported per take).

Prompt:

> Calm, low-key instrumental pause-menu music for a jungle war action game at dusk: soft warm synth pad, gentle fingerpicked clean electric guitar, distant muted tom heartbeat pulse, faint crickets-like shimmer, slow 70 BPM, minor key but relaxed and reflective, no big drums, no build-ups, no vocals. Even dynamics throughout so it can loop seamlessly; the ending flows back into the opening.

| Take | Integrated | Loudness range | Start / end level | Result |
|---|---:|---:|---|---|
| 1 | -17.6 LUFS | 6.8 LU | -14 / -22 dB | fades out at the end, would jump at the loop point |
| **2** | -13.0 LUFS | 0.4 LU | -13.1 / -13.4 dB | **kept**: even level from start to end, tonal (not noise), loops cleanly |
| 3 | -19.2 LUFS | 10.2 LU | -17 / -36 dB | swells and fades, too uneven for a loop |
| 4 | -15.8 LUFS | 5.3 LU | -46 / -27 dB | starts from silence |

Processing: the last 2 s are blended into the first 2 s with an equal-power crossfade (so the end flows into
the start and the loop has no click), two-pass loudnorm to -16 LUFS / -1.5 dBTP (linear), OGG Vorbis q6.
The game loops it while paused at the music volume setting; the pause-menu Music toggle starts and stops it.

**Pause behaviour (0.3.1).** Pausing freezes (does not stop) every one-shot effect, the helicopter rotor and
heartbeat loops, the ambience, Rayan's voice and the stage music; delayed sounds (for example the air-strike
whistle) wait. No gameplay sound can start while paused; menu sounds (`ui_*`, `store_*`) use their own small
pool and still play. Resume stops the pause track and continues everything from where it froze; a track
change or Music OFF/ON made in the pause menu applies on resume. Restart or Quit to title from the pause menu
drops the frozen sounds.


## New voice lines (0.3.4)

Generated 22 November 2026 with ElevenLabs text-to-speech, voice library
"Flint - Commanding Presence" (`qAZH0aMXY8tw1QufPN0D`), model eleven_v4.
Original lines, no impressions. Two-pass loudnorm to −16 LUFS / −1.5 dBTP
(linear), OGG Vorbis q6, 48 kHz mono. 183 characters billed (183 credits).

| File | Line | Unlock |
|---|---|---|
| rayan_keep_your_head_down | Keep your head down. | From the start, health below 30% |
| rayan_nests_down | Nest's down. | From the start, MG nest destroyed |
| rayan_chopper_inbound | Chopper inbound. | From the start, helicopter appears |
| rayan_still_standing | Still standing. | After stage 3, survives a heavy hit |
| rayan_clean_shot | Clean shot. | After stage 3, killing headshot |
| rayan_theyre_breaking | They're breaking. | After stage 3, streak of 5 |
| rayan_not_today | Not today. | After stage 3, recovers from critical health |
| rayan_this_is_the_firebreak | This is the firebreak. | After stage 7, stage start (stages 8–11) |
| rayan_one_more_push | One more push. | After stage 7, late in a late-campaign stage |
| rayan_almost_over | Almost over. | After stage 7, stage 12 start |
| rayan_ill_wear_it | I'll wear it. Then we finish this. | Award interlude after stage 10 (not yet in play) |

## 0.3.6 title theme

The title intro and loop were replaced with a new orchestral-military cue (ElevenLabs Music
`eleven_music_v2_5`, one 48 s instrumental take, 720 credits). The opening 12.75 s plays once;
the following 30.75 s (fade-out trimmed, 0.6 s equal-power crossfade) loops. Both files are
two-pass loudnorm to −16 LUFS / −1.5 dBTP, OGG Vorbis q6, 48 kHz stereo. The same music plays
on the opening briefing and the travel map.


## 0.3.7 title call

Generated 22 November 2026 with ElevenLabs text-to-speech, Voice Library
“Andrew - Fifties Announcer” (`p0Gik0TBCfzjohLCb7Mr`), model eleven_v4, one take.
Prompt: `[announcer, heroic, booming, no smile] FIREBREAK! [short pause] Cut the Ember Ring.`
Duration 3.28 s. Two-pass loudnorm to −16 LUFS / −1.5 dBTP (measured −16.78 LUFS,
TP −1.45 dB), OGG Vorbis q6, 48 kHz mono. 83 credits. The line plays once per
launch, about 0.45 s after the title intro starts, and the music ducks by 7 dB
while it plays. File: `assets/audio/title_call.ogg`.


## 0.4.0 Dune Sea (CC0)

No new ElevenLabs audio (the account is out of credit). Stage 2 uses third-party
CC0 recordings, two-pass loudnorm to −16 LUFS / −1.5 dBTP, Ogg Vorbis, 48 kHz
stereo. Full author, title, URL and licence lines are in NOTICE.

| File | Role | Source |
| --- | --- | --- |
| music_dune_sea.ogg | Stage 2 action bed (loops) | Darbuka Delight, Adiutorium, OpenGameArt, CC0 |
| music_dune_loop.ogg | Backup desert bed (shipped, unused unless selected later) | Desert Loop, iamoneabe, OpenGameArt, CC0 |
| ambience_dune.ogg | Stage 2 wind bed | Desert sand - Dune atmosphere, Vrymaa, Freesound, CC0 |
| truck_dune.ogg | Technical / convoy engine loop | Truck Engine Idle Loops, qubodup, Freesound, CC0 |
| wind_gust.ogg | Dust-storm gusts | S41-20 Gusty desert wind, craigsmith, Freesound, CC0 |
| camel.ogg | Camel scout spawn / call | Camel, annakstedt, Freesound, CC0 |
| bricks.ogg | Sniper (and masonry) hit debris | Bricks/Stones/Rocks/Gravel Falling, iwanPlays, Freesound, CC0 |

The Freesound items were taken from each listing's HQ preview.
