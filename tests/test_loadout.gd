extends SceneTree
## 0.3.0 loadout: three slots (pistol, primary, special), one weapon each with
## its own ammo; keys 1/2/3, next/previous, and the special on Space / right click.
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

const InputSetup := preload("res://scripts/input_setup.gd")
func run() -> void:
	var sim = fresh()
	check(sim.loadout.size() == 3, "three slots")
	check(sim.loadout[0].id == "viper_9" and sim.loadout[1].id == "hornet_9" and sim.loadout[2].id == "frag_grenades", "starter loadout: Viper 9, Hornet 9, Frag Grenades")
	check(sim.slot == 1, "the primary is selected at the start")
	var log := events(sim)
	check(sim.select_slot(0) and sim.slot == 0, "select the pistol")
	check(named(log, "weapon_switch").size() == 1, "switching emits weapon_switch")
	check(not sim.select_slot(0), "selecting the current slot does nothing")
	check(sim.select_slot(2) and sim.weapon().id == "frag_grenades", "select the special")
	check(sim.cycle_slot(1) and sim.slot == 0, "next wraps from special to pistol")
	check(sim.cycle_slot(-1) and sim.slot == 2, "previous wraps from pistol to special")
	check(not sim.select_slot(3) and not sim.select_slot(-1), "no slot outside 1-3")
	# Separate ammo per weapon.
	sim = fresh(); settle_all(sim)
	sim.select_slot(0); sim.fire_cooldown = 0.0
	sim.fire(Vector2(10, 10))
	check(sim.loadout[0].mag == int(Weapons.get_weapon("viper_9").mag) - 1, "pistol uses its own magazine")
	check(sim.loadout[1].mag == int(Weapons.get_weapon("hornet_9").mag), "primary magazine untouched by pistol fire")
	sim.select_slot(1); sim.fire_cooldown = 0.0
	sim.fire(Vector2(10, 10))
	check(sim.loadout[1].mag == int(Weapons.get_weapon("hornet_9").mag) - 1 and sim.loadout[0].mag == int(Weapons.get_weapon("viper_9").mag) - 1, "each weapon keeps its own count after switching")
	check(sim.fire_interval() < 1.0 / 8.0, "SMG fire interval comes from its data")
	sim.select_slot(0)
	check(is_equal_approx(sim.fire_interval(), 1.0 / float(Weapons.get_weapon("viper_9").fire_rate)), "pistol fire rate comes from its data")
	# Switching cancels a reload; the pistol never runs out.
	sim = fresh(); sim.loadout[1].mag = 3
	check(sim.reload() and sim.reload_timer > 0.0, "primary reload starts")
	sim.select_slot(0)
	check(sim.reload_timer == 0.0 and sim.loadout[1].mag == 3, "switching weapons cancels the reload")
	sim.loadout[0].mag = 0
	check(sim.reload(), "pistol reloads")
	for i in 120: sim.step(1.0 / 60.0)
	check(sim.loadout[0].mag == int(Weapons.get_weapon("viper_9").mag) and sim.loadout[0].reserve < 0, "pistol refills from an unlimited reserve")
	# Specials: slot 3 + fire, and Space / right click from any slot.
	sim = fresh()
	var before: int = sim.special_total()
	sim.select_slot(2)
	check(sim.fire(Vector2(900, 700)) and sim.grenades_in_flight.size() == 1, "left click with slot 3 selected fires the special")
	check(sim.special_total() == before - 1, "special count drops by one")
	sim.select_slot(1); sim.special_cooldown = 0.0
	check(sim.throw_grenade(Vector2(900, 700)) and sim.grenades_in_flight.size() == 2, "Space / right click fires the special from slot 2")
	check(sim.ammo == int(Weapons.get_weapon("hornet_9").mag), "the special does not use primary ammo")
	# Launchers from a profile.
	var p := Weapons.default_profile(); p.cash = 99999
	Weapons.buy(p, "thumper_gl"); Weapons.buy(p, "longshot_700"); Weapons.buy(p, "talon_50")
	sim = fresh(p)
	check(sim.loadout[0].id == "talon_50" and sim.loadout[1].id == "longshot_700" and sim.loadout[2].id == "thumper_gl", "bought weapons load into their slots")
	check(sim.loadout[2].mag == 6, "Thumper GL starts with 6 loaded")
	var log2 := events(sim)
	sim.throw_grenade(Vector2(800, 700))
	var thr := named(log2, "grenade_throw")
	check(thr.size() == 1 and thr[0][1].weapon == "thumper_gl" and thr[0][1].kind == "lobbed", "launcher shots carry their weapon and kind")
	check(is_equal_approx(float(sim.grenades_in_flight[0].radius), float(Weapons.get_weapon("thumper_gl").radius)), "blast radius comes from the weapon")
	# Longshot pierces up to 3 targets in a line.
	sim = fresh(p)
	var a: Dictionary = sim.spawn("rifleman", "far", {"world_x": 700, "world_y": 900}); settle(sim, a)
	var b: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 700, "world_y": 1000}); settle(sim, b)
	var c: Dictionary = sim.spawn("rifleman", "near", {"world_x": 700, "world_y": 1165}); settle(sim, c)
	var pt := Vector2(700, 860)
	var hits := 0
	for e in [a, b, c]:
		if sim.hitbox(e).has_point(pt + Vector2(sim.camera_x, 0)): hits += 1
	sim.fire(pt)
	var downs := [a, b, c].filter(func(e): return e.state == "dying").size()
	check(downs == hits and hits >= 2, "Longshot round downs every soldier on the line (%d of %d)" % [downs, hits])
	# Input actions.
	InputSetup.ensure(false)
	for n in [["weapon_1", KEY_1], ["weapon_2", KEY_2], ["weapon_3", KEY_3], ["weapon_next", KEY_Q]]:
		var k := InputEventKey.new(); k.physical_keycode = n[1]; k.pressed = true
		check(InputMap.event_is_action(k, n[0]), "%s on key %s" % [n[0], OS.get_keycode_string(n[1])])
	var wheel := InputEventMouseButton.new(); wheel.button_index = MOUSE_BUTTON_WHEEL_UP; wheel.pressed = true
	check(InputMap.event_is_action(wheel, "weapon_prev"), "mouse wheel up selects the previous weapon")
	var lb := InputEventJoypadButton.new(); lb.button_index = JOY_BUTTON_LEFT_SHOULDER; lb.pressed = true
	check(InputMap.event_is_action(lb, "weapon_next"), "gamepad LB cycles weapons")
	print("Loadout: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)

func settle_all(sim) -> void:
	for e in sim.entities: settle(sim, e)
