extends SceneTree
## Shooting, villager penalty, food healing, power-ups, reload, grenades,
## enemy fire and scoring.
const StageSim := preload("res://scripts/stage_sim.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func center(sim, e: Dictionary) -> Vector2:
	return sim.hitbox(e).get_center() - Vector2(sim.camera_x, 0)
func fresh():
	var sim = StageSim.new(); sim.setup(1, 5); sim.stage.ambient = []; sim.stage.waves = []
	return sim
func settle(sim, e: Dictionary) -> void:
	e.rise = 1.0; e.state = "aim"; e.timer = 10.0
func run() -> void:
	var sim = fresh()
	var r: Dictionary = sim.spawn("rifleman", "mid"); settle(sim, r)
	check(sim.entity_at(center(sim, r)) == r, "crosshair finds the soldier")
	check(sim.fire(center(sim, r)), "fire uses a round")
	check(sim.ammo == sim.mag_size() - 1, "ammo decreases")
	check(r.state == "dying" and sim.kills == 1, "one shot downs a rifleman")
	check(sim.score == int(100 * 1.2), "mid-band rifleman scores 120")
	check(not sim.fire(center(sim, r)), "fire rate limits instant second shot")
	sim.fire_cooldown = 0.0
	var before: int = sim.kills
	sim.fire(Vector2(5, 5))
	check(sim.kills == before and sim.stats.hits == 1, "miss hits nothing")
	# Near targets are drawn on top: overlapping shots hit the nearest one.
	sim = fresh()
	var far: Dictionary = sim.spawn("rifleman", "far", {"world_x": 700, "world_y": 900}); settle(sim, far)
	var near: Dictionary = sim.spawn("rifleman", "near", {"world_x": 700, "world_y": 920}); settle(sim, near)
	check(sim.entity_at(Vector2(700, 880)) == near, "nearest band wins overlapping shots")
	# Far band scores more.
	sim = fresh()
	var f: Dictionary = sim.spawn("rifleman", "far"); settle(sim, f)
	sim.fire(center(sim, f))
	check(sim.score == 150, "far rifleman scores 150 (harder to hit)")
	# Villager penalty.
	sim = fresh(); sim.score = 1000
	var v: Dictionary = sim.spawn("villager", "mid")
	sim.fire(center(sim, v))
	check(sim.health == 100.0 - sim.VILLAGER_PENALTY_HEALTH, "shooting a villager costs health")
	check(sim.score == 1000 - sim.VILLAGER_PENALTY_SCORE, "shooting a villager costs score")
	check(sim.stats.villagers_hit == 1 and sim.kills == 0, "villager is not an enemy kill")
	# Food heals, capped at max.
	sim = fresh(); sim.health = 50.0
	var food: Dictionary = sim.spawn("food", "sky", {"kind": "rice", "world_x": 900}); food.y = 400.0
	sim.fire(center(sim, food))
	check(sim.health == 65.0, "rice heals 15")
	sim.fire_cooldown = 0.0; sim.health = 95.0
	var ration: Dictionary = sim.spawn("food", "sky", {"kind": "ration", "world_x": 900}); ration.y = 400.0
	sim.fire(center(sim, ration))
	check(sim.health == 100.0, "healing is capped at max health")
	# Pickups have priority over soldiers behind them.
	sim = fresh()
	var behind: Dictionary = sim.spawn("rifleman", "near", {"world_x": 900, "world_y": 920}); settle(sim, behind)
	var box: Dictionary = sim.spawn("powerup", "sky", {"kind": "ammo", "world_x": 900}); box.y = 900.0
	check(sim.entity_at(Vector2(900, 900)) == box, "falling drops are on top")
	# Power-ups.
	sim = fresh()
	for kind in ["ammo", "grenade", "rapid", "spread", "power"]:
		var mags: int = sim.mags; var gren: int = sim.grenades
		var pu: Dictionary = sim.spawn("powerup", "sky", {"kind": kind, "world_x": 900}); pu.y = 400.0
		sim.fire_cooldown = 0.0
		sim.fire(center(sim, pu))
		match kind:
			"ammo": check(sim.mags == mags + 2, "ammo drop adds two magazines")
			"grenade": check(sim.grenades == gren + 2, "grenade drop adds two grenades")
			"rapid": check(sim.rapid_timer > 0.0 and sim.fire_interval() < 1.0 / float(sim.weapon().fire_rate), "rapid fire raises fire rate")
			"spread": check(sim.spread_timer > 0.0, "spread shot active")
			"power": check(sim.weapon_level == 2 and sim.shot_damage() > 1.0, "power-up raises weapon damage")
	check(sim.stats.powerups == 5, "five power-ups collected")
	# Spread hits three points.
	sim = fresh(); sim.spread_timer = 10.0
	var a: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 800, "world_y": 748}); settle(sim, a)
	var b: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 846, "world_y": 748}); settle(sim, b)
	var c: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 754, "world_y": 748}); settle(sim, c)
	sim.fire(Vector2(800, 670))
	check(sim.kills == 3, "spread shot downs three adjacent targets with one round")
	# Weapon power lets mg nests fall faster.
	sim = fresh()
	var mg: Dictionary = sim.spawn("mg", "mid", {"world_x": 900, "world_y": 748, "scale": 0.46})
	var shots := 0
	while mg.state != "dying" and shots < 20:
		sim.fire_cooldown = 0.0; sim.fire(center(sim, mg)); shots += 1
	check(shots == int(mg.max_hp), "mg nest takes %d hits at power 1" % int(mg.max_hp))
	# Reload.
	sim = fresh(); sim.ammo = 0
	var mags0: int = sim.mags
	check(sim.reload(), "reload starts")
	check(not sim.fire(Vector2(100, 100)), "cannot fire while reloading")
	for i in 70: sim.step(1.0 / 60.0)
	check(sim.ammo == sim.mag_size() and sim.mags == mags0 - 1, "reload fills the magazine and uses one spare")
	sim.ammo = 0; sim.mags = 0
	check(not sim.reload(), "no reload without spare magazines")
	sim.step(1.0 / 60.0)
	var has_ammo := false
	for e in sim.entities: if e.type == "powerup" and e.kind == "ammo": has_ammo = true
	check(has_ammo, "an ammo drop arrives when completely out of ammo")
	# Empty magazine auto-reloads.
	sim = fresh(); sim.ammo = 1
	sim.fire(Vector2(10, 10))
	check(sim.reload_timer > 0.0, "empty magazine reloads automatically")
	# Grenades.
	sim = fresh()
	var g1: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 900, "world_y": 748}); settle(sim, g1)
	var g2: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 980, "world_y": 748}); settle(sim, g2)
	var g3: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 1600, "world_y": 748}); settle(sim, g3)
	var gn: int = sim.grenades
	check(sim.throw_grenade(Vector2(940, 690)), "grenade thrown")
	check(sim.grenades == gn - 1, "grenade count decreases")
	for i in 40: sim.step(1.0 / 60.0)
	check(g1.state == "dying" and g2.state == "dying" and g3.state != "dying", "grenade blast hits targets in its radius only")
	sim.grenades = 0
	check(not sim.throw_grenade(Vector2(900, 600)), "no grenade when none left")
	# Enemy fire damages the player; near hits harder than far.
	sim = fresh(); sim.diff.accuracy = 10.0
	var nr: Dictionary = sim.spawn("rifleman", "near"); settle(sim, nr)
	sim._enemy_fire(nr, 1.0)
	var near_dmg: float = 100.0 - sim.health
	sim.health = 100.0
	var fr: Dictionary = sim.spawn("rifleman", "far"); settle(sim, fr)
	sim._enemy_fire(fr, 1.0)
	var far_dmg: float = 100.0 - sim.health
	check(near_dmg > far_dmg and far_dmg > 0.0, "near enemies hit harder (%.1f vs %.1f)" % [near_dmg, far_dmg])
	check(nr.muzzle > 0.0, "enemy shots show a muzzle flash")
	# Telegraph: a rifleman aims before firing.
	sim = fresh()
	var tel: Dictionary = sim.spawn("rifleman", "mid")
	var cnt := {"fire": 0, "first": -1.0}
	sim.event.connect(func(n, d): if n == "enemy_fire" and cnt.fire == 0: cnt.fire = 1; cnt.first = tel.age)
	for i in 400: sim.step(1.0 / 60.0)
	check(cnt.first >= 0.9, "rifleman aims at least 0.9 s before the first shot (%.2f)" % cnt.first)
	# Headshots: a killing shot in the head zone adds a modest +50 and a CLEAN SHOT event.
	# Body shots (the centre of the hitbox) are unchanged. Civilians never get the bonus.
	sim = fresh()
	var hs: Dictionary = sim.spawn("rifleman", "mid"); settle(sim, hs)
	var head_events := []
	sim.event.connect(func(n, d): if n == "headshot": head_events.append(d))
	var head_pos: Vector2 = sim.headbox(hs).get_center() - Vector2(sim.camera_x, 0)
	check(sim.is_headshot(hs, head_pos), "the top of a soldier is a headshot")
	check(not sim.is_headshot(hs, center(sim, hs)), "the middle of a soldier is a body shot")
	check(sim.fire(head_pos), "headshot fires")
	check(hs.state == "dying" and sim.kills == 1, "a headshot downs a rifleman")
	check(sim.score == 120 + sim.HEADSHOT_BONUS, "mid-band headshot is 120 + 50")
	check(sim.score % 10 == 0, "headshot score is a multiple of 10")
	check(head_events.size() == 1 and int(head_events[0].bonus) == sim.HEADSHOT_BONUS, "headshot event carries the bonus")
	# Far body shot stays 150; far headshot is 200.
	sim = fresh()
	var fh: Dictionary = sim.spawn("rifleman", "far"); settle(sim, fh)
	sim.fire(sim.headbox(fh).get_center() - Vector2(sim.camera_x, 0))
	check(sim.score == 200, "far rifleman headshot scores 200")
	check(sim.score % 10 == 0, "far headshot is a multiple of 10")
	# Villager: shooting the head still costs the same penalty, no bonus.
	sim = fresh(); sim.score = 1000
	var civ: Dictionary = sim.spawn("villager", "mid")
	var civ_events := []
	sim.event.connect(func(n, d): if n == "headshot": civ_events.append(d))
	var civ_head: Vector2 = sim.headbox(civ).get_center() - Vector2(sim.camera_x, 0)
	check(sim.headbox(civ).size.y > 0.0, "villagers have a head zone")
	sim.fire(civ_head)
	check(sim.score == 1000 - sim.VILLAGER_PENALTY_SCORE, "a civilian headshot is still only the penalty")
	check(civ_events.is_empty(), "CLEAN SHOT is not awarded for civilians")
	# Vehicles have no head zone.
	sim = fresh()
	var tr: Dictionary = sim.spawn("truck", "mid")
	check(sim.headbox(tr).size.x == 0.0 and not sim.is_headshot(tr, center(sim, tr)), "trucks have no head zone")

	# Near-band soldiers stand above the bottom HUD, not behind it.
	sim = fresh()
	var zones: Array = sim.stage.bands.near.zones
	check(zones.size() > 0, "near band has walkable spans")
	check(sim.HUD_BAND_TOP == 940.0, "HUD band starts at y 940")
	var nr_box: Dictionary = sim.spawn("rifleman", "near", {"world_x": 700, "world_y": 920}); settle(sim, nr_box)
	var nr_hit := sim.hitbox(nr_box)
	check(nr_hit.position.y + nr_hit.size.y <= sim.HUD_BAND_TOP, "near rifleman feet stay above the HUD band")
	check(nr_hit.position.y < 700.0, "near rifleman head is well above the HUD")
	var aim := sim.fire_target(nr_box, true)
	var miss := sim.fire_target(nr_box, false)
	check(aim.y <= sim.HUD_BAND_TOP and miss.y <= sim.HUD_BAND_TOP, "incoming near fire lands above the HUD")

	print("Combat: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
