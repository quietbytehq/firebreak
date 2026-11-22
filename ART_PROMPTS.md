# FIREBREAK — art prompts

Status for 0.2.0: the stage 1 background is AI-generated concept art (3840×1080,
`assets/backgrounds/river_village.jpg`). Characters, pickups and muzzle effects are now
**painted sprites** cut from the approved enemy and villager/pickup sheets
(`assets/sprites/units/`, 49 files). The Huey-style helicopter (with door gunner, idle and
firing), damaged and crashing helicopters, two strike jets, bomb and big explosion are cut
from one generated sheet on a flat grey background (`assets/sprites/vehicles/`, made with
`tools/art/cut_heli_sheet.py`). The title art and Rayan portraits (`assets/ui/`) come from a
text-free action-comic title image; the FIREBREAK logo is live text drawn in the engine.
Only the truck is still drawn in code (`scripts/art.gd`).

0.2.1: enemies now aim and fire **out of the screen at the player**. Ten front/three-quarter
poses (standing aim/fire, three-quarter fire, kneeling aim/fire, MG nest front aim/fire,
hanging paratrooper aim/fire) were generated in the same style and cut with
`tools/art/cut_front_v021.py`; the paratrooper uses the existing open canopy over the new
body. The side-view frames remain only for hits and falls. The big explosion was cleaned of
its grey sheet fringe with `tools/art/defringe.py`.

Adults only: the approved villager sheet also contained a child; that art is kept outside the
project and is never loaded or spawned.

Integration notes (0.2.0):
- Feet-anchored figures use anchor (w/2, h-8); pickups, FX, open chutes and the mid-air
  death pose are centre-anchored. `tools/art/sprite_meta.py` regenerates the table.
- Each figure is scaled so its opaque height fills the gameplay hitbox (rifleman 360,
  kneeling 250, villager 340, MG nest 240, paratrooper body 350, times the band scale).
- Dusk light per depth band is a shader on each draw layer: `rgb *= tint; rgb = mix(rgb, haze, amount)`.
- Sprites are imported with mipmaps and drawn with linear-mipmap filtering.
- Medkit crosses are green (no red cross emblem). `food_crate` = fruit, `food_medkit` = ration,
  `power_weapon` = rapid / spread / power / air-strike drop (labelled in game).
- Still wanted: a painted truck (drive / fire / wreck), separate rotor-blur frames for the
  helicopter, and a door-gunner-down frame (the game currently darkens the doorway).

## Shared style block (append to every prompt)

> Painterly semi-realistic 2D game sprite, late-1960s Southeast Asian jungle setting, warm
> golden-hour dusk light from the upper left with an orange rim light, soft natural shading,
> clean readable silhouette, full figure, transparent background (PNG with alpha), no text,
> no logos, no flags, no insignia, no national markings, no rank badges, no gore, no blood.
> Generic clothing and equipment only. Consistent scale and lighting across the set.

Rules: no real military unit markings, no real people, no Taito or Operation Wolf characters
or art. Enemy uniforms stay generic olive drab. Villagers must be dignified ordinary
farmers and traders, not caricatures. Adults only.

## Export sizes and anchors

Draw every standing figure at 512 px tall with the feet at the bottom centre of the canvas
(the game anchors sprites at the feet). Flying pickups: 256×256 centred. Vehicles: 1024 px
wide. Provide each animation as a horizontal strip of equal frames (e.g. `rifleman_aim_6f.png`)
facing RIGHT; the game mirrors for left.

## Enemies

| File | Frames | Prompt |
|---|---:|---|
| rifleman_rise | 4 | A generic jungle soldier in faded olive fatigues, plain steel helmet with cloth cover, webbing and canteen, rising up from behind cover while bringing a period bolt-action/assault rifle up, three-quarter view facing the viewer and slightly right. |
| rifleman_aim | 6 | Same soldier standing, rifle shouldered and aimed toward the viewer, subtle breathing sway; last two frames show recoil with a bright muzzle flash at the barrel tip. |
| rifleman_duck | 4 | Same soldier lowering the rifle and crouching back down behind cover. |
| rifleman_hit | 6 | Same soldier knocked backwards and falling to the ground, non-graphic, dust puff, no blood. |
| rifleman_b_* | as above | Variant soldier in a soft bush hat instead of a helmet, rolled sleeves, slightly different build. |
| mg_gunner_idle | 4 | A seated generic soldier behind a low sandbag wall operating a tripod-mounted medium machine gun, ammo belt feeding from a metal box, scanning; three-quarter view, gun pointing toward the viewer and slightly right. |
| mg_gunner_fire | 6 | Same gunner firing a sustained burst: recoil shake, alternating muzzle flashes, ejected brass. |
| mg_gunner_hit | 6 | Same gunner slumping behind the sandbags, gun tilting up, smoke wisp, non-graphic. |
| sandbag_nest_front | 1 | A curved low wall of weathered burlap sandbags, three rows, sun-faded tan, separate layer drawn in front of the gunner. |
| paratrooper_descend | 6 | A generic soldier hanging from an olive drab round military parachute, legs dangling, swaying, rifle held one-handed; the full canopy with suspension lines in frame; seen from below and in front. |
| paratrooper_fire | 4 | Same paratrooper firing downward toward the viewer while descending, muzzle flash. |
| paratrooper_land | 6 | Paratrooper touching down, canopy collapsing to one side, then standing up with rifle ready. |
| parachute_collapsed | 1 | A deflated olive parachute canopy lying crumpled on grass with tangled lines. |
| truck_drive | 4 | A generic 1960s olive-drab 2.5-ton cargo truck with canvas-covered bed, side view facing right, wheels turning, dust kicked up, no markings or numbers. |
| truck_fire | 4 | Same truck stopped, a soldier firing from the cab window, muzzle flash. |
| truck_wreck | 1 | Same truck destroyed: burnt, smoking, tyres flat, canvas burnt away. |

## Civilians (shooting them costs health and score)

| File | Frames | Prompt |
|---|---:|---|
| villager_pole_walk | 8 | A rice farmer in a woven conical straw hat, loose off-white shirt and dark trousers rolled to the calf, barefoot, carrying a bamboo shoulder pole with two woven baskets of vegetables, walking right in profile. |
| villager_bundle_walk | 8 | A village woman in a conical straw hat and faded indigo blouse with dark trousers, carrying a woven basket on her back, walking right in profile. |
| villager_trader_walk | 8 | An older villager with a cloth-wrapped bundle and a walking stick, light brown shirt, walking right. |
| villager_hit | 6 | A villager stumbling and falling, basket spilling vegetables, non-graphic. Used with the penalty warning. |

## Drops that fall from the sky (shoot them to collect)

All with a small white cargo parachute above and a soft glow ring (green = food, gold = upgrade).

| File | Prompt |
|---|---|
| food_rice | A small burlap sack of rice tied with green cord, 256×256. |
| food_fruit | A woven basket with bananas, mangoes and a papaya. |
| food_canteen | A metal water canteen in an olive cloth cover. |
| food_ration | A plain field-ration tin with a blank orange label, no text. |
| power_ammo | An olive steel ammunition box with yellow stencil stripes (no text). |
| power_grenade | A pair of olive fragmentation grenades strapped together. |
| power_rapid | A gleaming rifle bolt carrier with an orange lightning motif badge. |
| power_spread | Three brass rifle cartridges fanned out on a gold badge. |
| power_power | A gold star badge with an upgraded rifle silhouette. |

## Effects

| File | Frames | Prompt |
|---|---:|---|
| fx_muzzle | 3 | Bright rifle muzzle flash, four-point star, white-yellow core, orange edges, additive. |
| fx_dust | 6 | Small puff of brown dust and grass bits from a bullet impact on earth. |
| fx_explosion | 12 | Grenade explosion at dusk: white flash, orange fireball, black smoke column, dirt clods flying. 512×512. |
| fx_smoke_loop | 8 | Drifting dark grey smoke plume loop for burning wrecks. |
| ui_crosshair | 1 | Clean circular gun sight, thin white ring with four ticks and a red centre dot, 128×128. |

## Background parallax split for River Village (final version)

Repaint the panorama as one continuous strip, 7680×2160 (4K) or 3840×1080 minimum, in these
separate transparent layers so they can scroll at different speeds:

1. **sky** (0.15× speed): golden-hour sky with sun near the centre-left, layered clouds.
2. **far_mountains** (0.3×): misty limestone karst peaks and jungle ridges.
3. **far_village** (0.6×): stilt huts, watchtower, far river bank, crashed helicopter, smoke columns.
4. **mid_ground** (1.0×, gameplay band): rice paddies, river and footbridge, dirt road, camp tents and crates. Enemies stand here.
5. **near_cover** (1.25×): bamboo fence, sandbag wall, tall grass; enemies pop up from behind it.
6. **foreground** (1.5×, optional): blurred leaves and grass framing the bottom corners.

Prompt: "Wide side-scrolling game background, 1968 Southeast Asian jungle river village at
golden-hour dusk: stilt huts with thatched roofs, wooden watchtower, flooded rice paddies,
calm river with a small jetty, sandbagged footbridge bunker, dirt road with an abandoned
generic cargo truck, a crashed generic helicopter with smoke, a camouflaged camp with
supply crates, limestone karst mountains in mist, palm trees, layered for parallax,
painterly realistic, warm orange light, no people, no flags, no insignia, no text."

## 0.2.0 additions (generated)

| Asset | Prompt summary |
|---|---|
| heli_jets_sheet | One sheet on flat light grey: Huey-style transport helicopter, olive drab, no markings, door gunner firing from the open side door; the same helicopter damaged and smoking; the same crashing nose-down in flames; two camouflaged ground-attack jets with afterburners; one bomb; one big fireball explosion. Painterly, golden-hour light, no text, no insignia. |
| title_bg_notext | Action-comic title art: Rayan, a huge blond commando in black sunglasses, tank top and ammo belts, holding a rifle, centre-right; burning jungle river village at dusk, watchtower and smoke on the left, a helicopter top-right. Left/upper-left kept clear for the logo. No text. |

## 0.2.1 additions (generated, front-facing enemies)

All on a flat light grey (#d8d8d8) sheet, same painted style as the approved enemy sheet,
olive 1960s infantry, steel helmets, no flags, no insignia, no text, nothing overlapping.

| Asset | Prompt summary |
|---|---|
| front_riflemen | Six full-body soldiers facing the viewer, rifles aimed straight out of the image at the camera (barrel foreshortened): standing aim; standing firing with an orange muzzle flash at the barrel tip; kneeling aim; kneeling firing; three-quarter left aim; three-quarter right firing. |
| front_mg | A sandbag machine-gun nest seen from the front, gunner behind a tripod heavy MG pointing straight at the viewer; the same nest firing with a star-shaped flash at the muzzle. |
| front_para | A paratrooper hanging in harness (risers run off the top, no canopy) seen from the front, rifle aimed at the viewer; the same firing with a round muzzle flash; a hit pose falling backwards. |

## 0.3.0 — weapon icons, money drop and outlines

**Weapon icons** (`assets/ui/weapons/<id>.png`, 20 files, longest side 512 px): one image per weapon, generated
16:9 on a flat grey background and cut with `tools/art/cut_icons.py` (border flood-fill through an opened mask so thin
gaps in the ink line cannot leak, enclosed grey holes such as trigger guards removed only when ringed by dark ink,
2 px soft edge with the grey removed from edge pixels, cropped). `tools/art/contact_sheet.py` builds the review sheet.
All designs are original; names and art carry no maker's marks, logos, text or serial numbers.

The exact per-icon prompt strings were not saved at generation time; the style block and subject
descriptions below are a faithful summary of what each prompt asked for, not verbatim copies.

Shared icon style (the gist of the style part of every icon prompt):

> Painted action-comic style: bold dark ink outline around the whole weapon, painterly semi-realistic shading, warm golden-hour rim light from the upper left. Strict side view, muzzle pointing right, the single weapon centred with generous empty margin all round. Flat plain uniform medium-grey background (#808080), no cast shadow, no floor, no hands. No text, no letters, no logos, no brand markings, no serial numbers.

Subjects (one per prompt, summarised):

| Icon | Subject |
|---|---|
| viper_9 | a compact black polymer-framed 9mm semi-automatic service pistol, blocky slide with fine rear serrations, simple square trigger guard, short grip |
| talon_50 | a huge heavy gas-operated semi-automatic hand cannon pistol, very long thick slab-sided barrel with a triangular profile and a flat top rib, polished stainless steel, dark rubber wraparound grip, big squared trigger guard |
| warden_1911 | a classic mid-century heavy-calibre single-stack semi-automatic sidearm, blued steel slide with rear serrations, worn walnut grip panels with checkering, exposed spur hammer, grip safety |
| kestrel_p9 | a sleek modern full-size 9mm service pistol, brushed silver slide and dark olive-green polymer frame, accessory rail, slim contoured grip |
| rook_revolver | a heavy six-shot double-action revolver with a long ribbed barrel and full-length underlug, fluted cylinder, blued steel, wooden grip, hammer cocked |
| hornet_9 | a compact 9mm submachine gun with a forward-curved slim magazine, cylindrical receiver with a cocking tube, drum rear sight, slim handguard, fixed polymer stock |
| buzzsaw | a cheap rugged stamped-steel submachine gun, boxy receiver, perforated barrel shroud, straight stick magazine, extended wire-frame folding stock |
| stinger_v | a modern compact submachine gun with an angular sloping receiver, short barrel, vertical foregrip, straight magazine, folding skeleton stock, dark-grey and tan |
| mamba_90 | a futuristic bullpup personal defence weapon, rounded sand-coloured body, translucent magazine lying along the top, thumbhole grip |
| ratchet_mac | a tiny blocky machine pistol, square stamped-steel receiver, magazine in the grip, short threaded barrel, strap loop, no stock |
| kalash_47 | a rugged mid-century assault rifle with orange-brown wooden stock, handguard and grip, stamped receiver, long curved magazine, gas tube |
| sentinel_m4 | a modern black carbine with flat-top receiver, small red-dot optic, ribbed rail handguard, collapsible stock, flash hider |
| granite_g3 | a heavy cold-war battle rifle, long stamped receiver with cocking tube, ventilated handguard, straight box magazine, angular fixed stock, olive and black (a small raised mark on the magazine was painted out by hand) |
| longshot_700 | a long bolt-action marksman rifle, dark green synthetic stock, heavy barrel, large telescopic scope, folded bipod |
| thunder_m60 | a heavy belt-fed jungle-war machine gun, carry handle, bipod, olive box receiver, short brass belt, black buttstock |
| frag_grenades | three olive-green segmented fragmentation hand grenades with spoons and pull rings, side by side (no markings or stencils) |
| hammer_rpg | a shoulder-fired rocket launcher, slim olive tube with wooden heat guard, two pistol grips, loaded pointed warhead, flared exhaust (no markings) |
| tankbuster | a big heavy anti-tank rocket tube, olive-drab, flared rear, pistol grip, folding sight frame, finned rocket visible at the front (no markings) |
| thumper_gl | a revolver-style grenade launcher with a big six-shot rotary cylinder, short fat barrel, folding stock, pistol and front grips (no markings) |
| air_strike | an olive military field radio with whip antenna and coiled handset beside two small dark jet silhouettes streaking up-right (no insignia) |

**Money drop** (`assets/sprites/units/power_cash.png`, 256 px canvas), summarised prompt: a game pickup sprite of a
small money bag with a bundle of plain green banknotes and a few coins, same painted action-comic style and ink outline,
on flat grey; banknotes blank with no portraits, numbers, text, symbols or currency signs. Cut with the same tool and
centred on the pickup canvas.

**Outlines.** `tools/art/bake_outlines.py` bakes a dark ink outline (RGB 18,13,10) into every soldier, paratrooper,
MG nest, villager, helicopter and pickup sprite (57 files). Width in master pixels = 3.5 px divided by the sprite's
on-screen scale at the near band (clamped 2-8), so near figures read about 3-4 px and farther figures proportionally
thinner. Flash frames reuse the outline of their non-flash pose so muzzle flashes are not outlined. Canvases grow by
the pad on each side; anchors and opaque boxes in `scripts/sprite_meta.gd` move with them and the opaque box stays the
original figure, so in-game sizes are unchanged. Pads are recorded in `assets/sprites/outline_v030.json`, which
`tools/art/sprite_meta.py` now honours. The un-outlined masters were moved to `_to_delete/replaced_v030_art/`.

Rayan's portrait and bust are unchanged in 0.3.0 (the HUD shows the selected weapon in the bar instead of a new pose).

## 0.3.1 — first-person weapon views

**First-person views** (`assets/sprites/fp/<id>.png`, 20 files, 640×640 RGBA): one picture per weapon (19) plus the
Air Strike radio hand, generated with the image generator at 1024×1024 on flat grey, then cut with
`tools/art/cut_fp.py` (the same cut as the icons via `cut_icons.cut(..., crop=False)`, so the full square canvas
is kept and the arms stay anchored to the bottom edge; resized to 640 and the bottom 7% faded to transparent so
the forearms melt into the bottom of the screen). `tools/art/fp_contact_sheet.py ROOT OUT [--checker] [--marks]`
builds the review sheet. Muzzle points (where the flash, sparks or launch puff start) and the launcher back-blast
points are fractions of the picture in `data/fp_weapons.json`, read off the raw images.

Prompt template (verbatim apart from the bracketed part):

> First-person shooter view-model, Doom-style, seen from directly behind the player: two big muscular bare tan forearms with black tactical gloves rise from the bottom edge of the image and hold [weapon description], pointing straight ahead and slightly up into the distance, seen from behind and above in perspective, muzzle near the upper middle of the picture. Arms enter from the bottom edge only. Painted action-comic style: bold dark ink outlines, painterly semi-realistic shading, warm golden-hour rim light. Flat plain uniform medium-grey background (#808080), nothing else in the scene, no shadow on the background. No text, no letters, no logos, no markings, no tattoos.

Grip wording per group:
- Pistols, Ratchet Mac and Thumper GL: "held in a centred two-handed grip".
- Long guns: "the right hand on the pistol grip near the bottom right, the left hand on the handguard further forward".
- Hammer RPG and Tankbuster: "the flared, wide-open rear end faces the viewer at the lower right".
- Frag Grenades: the right hand holds ONE olive segmented grenade, the left hand hooks a finger through the pull ring.
- Air Strike: the left hand holds an olive field-radio handset with a coiled cord and whip antenna; the right hand points forward.

The weapon descriptions match the 0.3.0 icon subjects above, seen from behind. Kalash 47 and Longshot 700 were
regenerated once because the first takes showed two barrels; the retakes add "ONE … (a single barrel only)". The
rejected first takes are kept outside the project folder. The Kalash 47 and the Frag Grenades left arm end in a
soft feathered edge at the lower left; the bottom fade and the HUD bar cover most of it.

In game (`scripts/fp_view.gd`) the picture is drawn 600 px tall, bottom-centred, under the HUD layer, with sway,
aim follow, recoil, switch and reload animations; the flash, sparks, launch fire and smoke are drawn in code.
