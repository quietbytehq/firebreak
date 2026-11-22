extends SceneTree
## 0.3.0 HUD weapon bar: three slots with icon and ammo; clicking a slot selects
## it and never fires; clicks elsewhere still fire.
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
const Hud := preload("res://scripts/hud.gd")
func frames(n: int) -> void:
	for i in n: await process_frame
func click(pos: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> void:
	var ev := InputEventMouseButton.new(); ev.button_index = button; ev.pressed = pressed
	# Window coordinates: the headless window is tiny, so map the 1920x1080 point.
	var wp: Vector2 = root.get_final_transform() * pos
	ev.position = wp; ev.global_position = wp
	Input.parse_input_event(ev)
func run() -> void:
	for i in 3:
		check(Hud.slot_at(Hud.slot_rect(i).get_center()) == i, "slot %d is hit at its centre" % (i + 1))
		check(Hud.slot_rect(i).end.y <= 1080.0 and Hud.slot_rect(i).position.y >= 900.0, "slot %d sits in the bottom bar" % (i + 1))
	check(Hud.slot_at(Vector2(960, 500)) == -1 and Hud.slot_at(Vector2(100, 1000)) == -1, "play area and health panel are not slots")
	check(not Hud.slot_rect(0).intersects(Hud.slot_rect(1)) and not Hud.slot_rect(1).intersects(Hud.slot_rect(2)), "slots do not overlap")
	check(Hud.icon_for("hornet_9") != null and Hud.icon_for("frag_grenades") != null, "slot icons load")
	check(Hud.money(1234567) == "$1,234,567" and Hud.money(0) == "$0", "cash formatting")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	main.start_stage(1)
	main.sim.stage.ambient = []; main.sim.stage.waves = []
	await frames(25)
	check(main.mode == "playing", "stage running")
	main.fire_grace = 0.0
	var shots: int = main.sim.stats.shots
	click(Hud.slot_rect(2).get_center(), true)
	await frames(4)
	check(main.sim.slot == 2, "clicking slot 3 selects the special")
	check(main.sim.stats.shots == shots and main.sim.grenades_in_flight.is_empty(), "the click on the bar does not fire")
	click(Hud.slot_rect(2).get_center(), false)
	await frames(2)
	click(Hud.slot_rect(0).get_center(), true, MOUSE_BUTTON_RIGHT)
	await frames(4)
	check(main.sim.slot == 0 and main.sim.grenades_in_flight.is_empty(), "right click on the bar selects without throwing")
	click(Hud.slot_rect(0).get_center(), false, MOUSE_BUTTON_RIGHT)
	await frames(2)
	click(Hud.slot_rect(1).get_center(), true)
	await frames(20)
	check(main.sim.slot == 1 and main.sim.stats.shots == shots, "holding the button on the bar never starts automatic fire")
	click(Hud.slot_rect(1).get_center(), false)
	await frames(2)
	main.sim.fire_cooldown = 0.0
	click(Vector2(960, 400), true)
	main.crosshair = Vector2(960, 400)
	await frames(3)
	check(main.sim.stats.shots > shots, "a click in the play area fires")
	click(Vector2(960, 400), false)
	await frames(2)
	for n in [[KEY_3, 2], [KEY_1, 0], [KEY_2, 1]]:
		var k := InputEventKey.new(); k.physical_keycode = n[0]; k.keycode = n[0]; k.pressed = true
		Input.parse_input_event(k)
		await frames(2)
		var up: InputEventKey = k.duplicate(); up.pressed = false; Input.parse_input_event(up)
		await frames(1)
		check(main.sim.slot == n[1], "key %s selects slot %d" % [OS.get_keycode_string(n[0]), n[1] + 1])
	check(main.hud.ammo_text(0).ends_with("∞") and main.hud.ammo_text(2).begins_with("×"), "bar shows pistol unlimited and special count")
	main.queue_free()
	await frames(2)
	print("HUD click: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
