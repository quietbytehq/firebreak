extends SceneTree
## Headless smoke: 3-civilian fail, a continue retry, then the gunboat still clears.
const StageSim := preload("res://scripts/stage_sim.gd")
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await process_frame
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	if main == null:
		printerr("SMOKE FAIL: main scene did not load")
		quit(1)
		return
	root.add_child(main)
	await frames(3)
	main.qa = {"run": true, "seed": 21}
	main.begin_run()
	main.start_stage(3)
	await frames(8)
	if main.sim == null or main.sim.quota != 128:
		printerr("SMOKE FAIL: Coral Coast quota is %s" % (str(main.sim.quota) if main.sim else "missing"))
		quit(1)
		return
	if main.run_continues != 3:
		printerr("SMOKE FAIL: expected 3 continues, got %d" % main.run_continues)
		quit(1)
		return
	_fail_civilians(main.sim)
	if main.sim.state != "failed" or main.sim.end_reason != "civilians":
		printerr("SMOKE FAIL: expected failed/civilians, got %s/%s" % [main.sim.state, main.sim.end_reason])
		quit(1)
		return
	if not main.use_continue():
		printerr("SMOKE FAIL: continue was refused")
		quit(1)
		return
	await frames(8)
	if main.run_continues != 2 or main.sim == null or main.sim.state != "playing":
		printerr("SMOKE FAIL: continue did not restart the stage")
		quit(1)
		return
	if int(main.sim.stats.villagers_hit) != 0:
		printerr("SMOKE FAIL: retried stage kept old civilian hits")
		quit(1)
		return
	# Still able to reach and sink the gunboat on the retried run.
	var sim = main.sim
	var dt := 0.05
	var steps := 0
	while sim.time < 140.0 and sim.state == "playing":
		sim.health = sim.max_health
		sim.step(dt)
		steps += 1
		if steps > 8000:
			printerr("SMOKE FAIL: did not reach the harbour")
			quit(1)
			return
	for i in 80:
		sim.health = sim.max_health
		sim.step(dt)
	var gun := {}
	for e in sim.entities:
		if e.type == "gunboat":
			gun = e
			break
	if gun.is_empty():
		printerr("SMOKE FAIL: gunboat did not spawn")
		quit(1)
		return
	if not bool(gun.get("gunner2_alive", false)):
		printerr("SMOKE FAIL: gunboat is missing the second gunner")
		quit(1)
		return
	var pos := Vector2(gun.x - sim.camera_x, gun.y - 40.0)
	sim.damage_entity(gun, 999.0, pos, true)
	for i in 50:
		sim.step(dt)
	if sim.state != "cleared" or sim.end_reason != "boss":
		printerr("SMOKE FAIL: expected cleared/boss, got %s/%s" % [sim.state, sim.end_reason])
		quit(1)
		return
	print("SMOKE OK stage=3 quota=", sim.quota, " continues_after_retry=", main.run_continues,
		" camera_x=", int(sim.camera_x), " time=", snapped(sim.time, 0.01),
		" reason=", sim.end_reason, " gun_hp=", int(gun.max_hp),
		" gun_y=", int(gun.y), " steps=", steps)
	quit(0)

func _fail_civilians(sim) -> void:
	for i in 3:
		var v: Dictionary = sim.spawn("villager", "mid")
		if v.is_empty():
			v = sim.spawn("villager", "near")
		if v.is_empty():
			printerr("SMOKE FAIL: could not spawn civilian %d" % (i + 1))
			quit(1)
			return
		sim.damage_entity(v, 99.0, Vector2(v.x - sim.camera_x, v.y - 40.0))
