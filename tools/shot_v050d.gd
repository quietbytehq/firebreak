extends SceneTree
## 0.5.1 shots: Stage 1 outlines, an air strike, a dialogue line, and the
## Coral Coast rusher and grenadier.
const Scores := preload("res://scripts/scores.gd")
const Ground := preload("res://scripts/stage_ground.gd")
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await process_frame
func capture(main: Node, path: String) -> void:
	await frames(6)
	var img := main.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("wrote ", path, " ", img.get_width(), "x", img.get_height())
func run() -> void:
	var out := str(OS.get_environment("FIREBREAK_SHOT_DIR"))
	if out == "":
		out = "/tmp/firebreak_v050d"
	DirAccess.make_dir_recursive_absolute(out)
	Scores.save_player_name("ACE")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(16)
	main.settings.fullscreen = false
	main.settings.airstrike_hint_seen = true  # keep this shot on the outlines, not the hint
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	main.qa = {"seed": 17}
	main.begin_run()
	main.start_stage(1)
	await frames(12)
	main.sim.stage.ambient = []
	main.sim.stage.waves = []
	main.sim.camera_x = 0.0
	# Stage 1 white outlines: a mid and a near rifleman plus an MG, fully up.
	for item in [["rifleman", "mid", 620.0, 752.0], ["rifleman", "near", 980.0, 900.0], ["mg", "mid", 1280.0, 760.0]]:
		var e: Dictionary = main.sim.spawn(str(item[0]), str(item[1]), {"world_x": item[2], "world_y": item[3]})
		if not e.is_empty():
			e.rise = 1.0
			e.state = "aim"
			e.timer = 8.0
	await frames(10)
	await capture(main, out.path_join("stage1_outlines.png"))
	# Air strike inbound over those enemies.
	main.sim.airstrikes = 1
	main.sim.call_airstrike()
	# Mid-flight: jets on screen, bombs not yet landed.
	for i in 20:
		main.sim.step(0.05)
		await frames(1)
	await capture(main, out.path_join("airstrike.png"))
	# Dialogue line on Coral Coast.
	main.begin_run()
	main.settings.airstrike_hint_seen = true
	main.start_stage(3)
	await frames(10)
	if main.dialogue:
		main.dialogue.current = {"speaker": "Rayan", "text": "Bay's crowded. Boats, pier, and the town.", "kind": "start", "life": 8.0}
		main.dialogue.queue.clear()
	await frames(8)
	await capture(main, out.path_join("dialogue.png"))
	# Rusher wading in the mid bay, plus a grenadier on the pier.
	main.sim.camera_x = 800.0
	main.sim.time = 24.0
	var p: Vector2 = main.sim.pick_water_point("mid")
	if p.x < 0.0:
		p = Vector2(main.sim.camera_x + 700.0, 780.0)
	var rushers := 0
	for k in 3:
		var wx := p.x - 90.0 + k * 80.0
		var r: Dictionary = main.sim.spawn("rusher", "mid", {"world_x": wx})
		if not r.is_empty():
			r.rise = 1.0
			r.state = "charge"
			if bool(r.get("wading", false)):
				rushers += 1
	var gre: Dictionary = main.sim.spawn("grenadier", "mid", {"world_x": 1700.0, "world_y": 710.0, "scale": 0.7})
	if not gre.is_empty():
		gre.state = "aim"
		gre.timer = 0.4
		main.sim._throw_enemy_nade(gre)
		# Put the grenade mid-arc with a visible shadow.
		if not main.sim.enemy_nades.is_empty():
			main.sim.enemy_nades[0].t = 0.55
	print("rushers_wading=", rushers, " grenadier=", int(not gre.is_empty()), " camera_x=", int(main.sim.camera_x))
	await frames(10)
	await capture(main, out.path_join("rusher.png"))
	await capture(main, out.path_join("grenadier.png"))
	print("shot_v050d done")
	quit(0)
