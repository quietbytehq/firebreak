extends SceneTree
## Air strike: root cause was leftover GUI focus swallowing E in
## _unhandled_input. The action is now also polled in _process, so a
## strike still fires. This checks the strike hits enemies and that
## a key event works even with a focused LineEdit.
const StageSim := preload("res://scripts/stage_sim.gd")
const Hud := preload("res://scripts/hud.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame
func fresh():
	var sim = StageSim.new(); sim.setup(1, 5); sim.stage.ambient = []; sim.stage.waves = []
	return sim
func run() -> void:
	var sim = fresh()
	check(sim.airstrikes >= 1, "stage starts with an air strike")
	var a: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 800.0, "world_y": 752.0})
	var b: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 1100.0, "world_y": 752.0})
	a.rise = 1.0; a.state = "aim"; b.rise = 1.0; b.state = "aim"
	check(sim.call_airstrike(), "call_airstrike spends the charge")
	check(sim.airstrikes == 0, "charge is consumed")
	check(not sim.call_airstrike(), "a second call is rejected while one is inbound or empty")
	var before_kills: int = sim.kills
	for i in 80:
		sim.step(0.05)
	check(a.state == "dying" or not sim.entities.has(a), "first rifleman is hit by the strike")
	check(b.state == "dying" or not sim.entities.has(b), "second rifleman is hit by the strike")
	check(sim.kills >= before_kills + 2, "the strike counts both kills (%d)" % sim.kills)

	# Civilians are spared.
	sim = fresh()
	var civ: Dictionary = sim.spawn("villager", "mid")
	check(not civ.is_empty() and sim.call_airstrike(), "strike can be called with a civilian in view")
	for i in 80:
		sim.step(0.05)
	check(civ.state != "dying" and sim.entities.has(civ), "civilians are not harmed by the strike")

	# Input path: leftover LineEdit focus must not eat E.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(4)
	main.start_stage(1)
	main.sim.stage.ambient = []; main.sim.stage.waves = []
	var r: Dictionary = main.sim.spawn("rifleman", "mid", {"world_x": 960.0, "world_y": 752.0})
	if not r.is_empty():
		r.rise = 1.0; r.state = "aim"
	await frames(8)
	check(main.mode == "playing", "stage is playing")
	check(main.sim.airstrikes >= 1, "dev stage has a charge")
	var le := LineEdit.new()
	le.text = "x"
	main.add_child(le)
	le.grab_focus()
	await frames(2)
	check(main.get_viewport().gui_get_focus_owner() == le, "a leftover LineEdit has focus (the old failure case)")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_E
	ev.keycode = KEY_E
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(3)
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await frames(2)
	check(not main.sim.strike.is_empty() or main.sim.airstrikes == 0, "E still calls the strike while a LineEdit has focus")
	le.queue_free()
	# HUD panel is a hit target.
	check(Hud.airstrike_hit(Hud.airstrike_rect().get_center()), "air-strike panel hits at its centre")
	check(not Hud.airstrike_hit(Vector2(960, 400)), "play area is not the air-strike panel")
	check(not Hud.airstrike_rect().intersects(Hud.slot_rect(2)), "air-strike panel does not overlap slot 3")
	main.queue_free()
	await frames(2)
	print("Air strike: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
