extends SceneTree
## 0.3.0 ammo: per-weapon magazines and reserves, reloads, ammo and grenade
## drops refilling the right weapon (capped), dry fire and the empty-primary fallback.
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
func drop(sim, kind: String) -> void:
	var box: Dictionary = sim.spawn("powerup", "sky", {"kind": kind, "world_x": 900}); box.y = 400.0
	sim.fire_cooldown = 0.0; sim.special_cooldown = 0.0
	var prev: int = sim.slot
	if prev == 2: sim.slot = 1   # shoot it with the primary, then restore
	sim.fire(center(sim, box))
	sim.slot = prev
func run() -> void:
	var hornet := Weapons.get_weapon("hornet_9")
	var sim = fresh()
	check(sim.ammo == int(hornet.mag), "primary starts with a full magazine")
	check(sim.loadout[1].reserve == Weapons.issue_reserve(hornet), "primary starts with its issue reserve")
	var res0: int = sim.loadout[1].reserve
	drop(sim, "ammo")
	check(sim.loadout[1].reserve == mini(res0 + int(hornet.drop_mags) * int(hornet.mag), int(hornet.max_reserve)), "ammo drop adds magazines to the selected primary")
	sim = fresh(); sim.select_slot(0); res0 = sim.loadout[1].reserve
	drop(sim, "ammo")
	check(sim.loadout[1].reserve > res0 and sim.loadout[0].reserve < 0, "with the unlimited pistol selected, ammo goes to the primary")
	var p := Weapons.default_profile(); p.cash = 99999; Weapons.buy(p, "talon_50")
	sim = fresh(p); sim.select_slot(0)
	var tr: int = sim.loadout[0].reserve; var pr: int = sim.loadout[1].reserve
	drop(sim, "ammo")
	check(sim.loadout[0].reserve > tr and sim.loadout[1].reserve == pr, "ammo drop refills the selected pistol only")
	sim = fresh(); var g0: int = sim.special_total()
	drop(sim, "grenade")
	check(sim.special_total() > g0, "grenade drop refills the special")
	sim = fresh(); sim.loadout[1].reserve = int(hornet.max_reserve) - 5
	drop(sim, "ammo")
	check(sim.loadout[1].reserve == int(hornet.max_reserve), "reserve is capped at the weapon's max")
	sim = fresh(); sim.loadout[1].mag = 10; res0 = sim.loadout[1].reserve
	check(sim.reload(), "reload starts")
	check(is_equal_approx(sim.reload_duration, float(hornet.reload)), "reload time comes from the weapon")
	for i in 90: sim.step(1.0 / 60.0)
	check(sim.ammo == int(hornet.mag) and sim.loadout[1].reserve == res0 - (int(hornet.mag) - 10), "reload takes only what the magazine needs")
	sim = fresh(); var log := events(sim)
	sim.loadout[1].mag = 0; sim.loadout[1].reserve = 0
	sim.fire(Vector2(10, 10))
	var empt := named(log, "empty")
	check(empt.size() == 1 and empt[0][1].weapon == "hornet_9", "dry fire reports the weapon (for its click sound)")
	check(sim.slot == 0, "an empty primary falls back to the pistol")
	check(sim.slot_empty(1) and not sim.slot_empty(0), "slot_empty reflects magazine and reserve")
	sim = fresh(); sim.select_slot(2)
	var shots := 0
	for i in 12:
		sim.special_cooldown = 0.0; sim.special_reload = 0.0; sim.fire_cooldown = 0.0
		if sim.fire(Vector2(900, 700)): shots += 1
	check(shots == 5 and sim.special_total() == 0, "exactly 5 frag grenades, then empty (%d)" % shots)
	print("Ammo: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
