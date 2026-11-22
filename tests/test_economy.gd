extends SceneTree
## 0.3.0 economy: cash for kills (more for MG nests and helicopters), money drops,
## civilian penalties, and cash / ammo carried between stages in the saved profile.
const StageSim := preload("res://scripts/stage_sim.gd")
const Weapons := preload("res://scripts/weapons.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func center(sim, e: Dictionary) -> Vector2:
	return sim.hitbox(e).get_center() - Vector2(sim.camera_x, 0)
func fresh(profile: Dictionary = {}):
	var sim = StageSim.new(); sim.setup(1, 5, {}, profile); sim.stage.ambient = []; sim.stage.waves = []
	return sim
func settle(sim, e: Dictionary) -> void:
	e.rise = 1.0; e.state = "aim"; e.timer = 10.0
func events(sim) -> Array:
	var log := []
	sim.event.connect(func(n, d): log.append([n, d]))
	return log
func named(log: Array, n: String) -> Array:
	return log.filter(func(x): return x[0] == n)
func run() -> void:
	var eco := Weapons.economy()
	var sim = fresh()
	var r: Dictionary = sim.spawn("rifleman", "near"); settle(sim, r)
	var log := events(sim)
	sim.fire(center(sim, r))
	check(sim.cash == int(eco.kill_cash.rifleman), "near rifleman pays the base rifleman bounty")
	check(named(log, "cash").size() == 1, "kills emit a cash event")
	sim = fresh()
	var f: Dictionary = sim.spawn("rifleman", "far"); settle(sim, f)
	sim.fire(center(sim, f))
	check(sim.cash == int(round(int(eco.kill_cash.rifleman) * float(eco.band_cash_mult.far))), "far kills pay more")
	check(int(eco.kill_cash.mg) > int(eco.kill_cash.rifleman) * 2 and int(eco.kill_cash.heli) > int(eco.kill_cash.mg), "MG nests and helicopters pay much more")
	sim = fresh()
	var mg: Dictionary = sim.spawn("mg", "mid", {"world_x": 1150, "world_y": 748, "scale": 0.46}); settle(sim, mg)
	sim.damage_entity(mg, 99.0, center(sim, mg))
	check(sim.cash >= int(eco.kill_cash.mg), "an MG nest pays its bounty")
	sim = fresh()
	var h: Dictionary = sim.spawn("heli", "sky", {"from": "right"})
	h.gunner_alive = false
	sim.damage_entity(h, 999.0, Vector2(900, 200), true)
	check(sim.cash >= int(eco.kill_cash.heli), "a helicopter pays its bounty")
	sim = fresh()
	for kind in ["cash_small", "cash_large"]:
		var box: Dictionary = sim.spawn("powerup", "sky", {"kind": kind, "world_x": 900}); box.y = 400.0
		sim.fire_cooldown = 0.0; sim.fire(center(sim, box))
	check(sim.cash == int(eco.cash_drop.small) + int(eco.cash_drop.large), "shooting money drops pays both amounts")
	check(sim.stats.cash_drops == 2, "money drops are counted")
	sim = fresh(); sim.cash = 1000
	var v: Dictionary = sim.spawn("villager", "mid")
	var hp: float = sim.health
	sim.fire(center(sim, v))
	check(sim.cash == 1000 - int(eco.civilian_penalty) and sim.health < hp, "hitting a civilian costs cash and health")
	sim = fresh(); sim.cash = 100; sim.fire_cooldown = 0.0
	var v2: Dictionary = sim.spawn("villager", "mid")
	sim.fire(center(sim, v2))
	check(sim.cash == 0 and sim.cash_lost == 100, "cash never goes below zero")
	sim = fresh(); sim.cash = 500
	sim.spawn("villager", "mid")
	var e1: Dictionary = sim.spawn("rifleman", "mid"); settle(sim, e1)
	sim.airstrike_impact()
	check(sim.cash > 500 and sim.cash_lost == 0, "air strike kills pay and never cost civilian penalties")
	var p := Weapons.default_profile(); p.cash = 250
	sim = fresh(p)
	check(sim.cash == 250, "a stage starts with the saved cash")
	sim.add_cash(150, Vector2.ZERO, "drop"); sim.loadout[1].reserve = 37
	sim.write_profile(p)
	check(int(p.cash) == 400 and int(p.ammo.hornet_9.reserve) == 37 and int(p.earned_total) == 150, "write_profile saves cash, ammo and earnings")
	check(Weapons.save_profile(p), "profile saves to user://")
	var back := Weapons.load_profile()
	check(int(back.cash) == 400 and int(back.ammo.hornet_9.reserve) == 37, "profile loads back from user://")
	check(ProjectSettings.globalize_path(Weapons.PROFILE_PATH).contains("Firebreak"), "profile lives in the Firebreak user folder")
	var nxt = fresh(back)
	check(nxt.loadout[1].reserve >= Weapons.issue_reserve(Weapons.get_weapon("hornet_9")), "field issue tops up to the issue reserve each stage")
	print("Economy: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
