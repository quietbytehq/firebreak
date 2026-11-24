extends SceneTree
## Headless smoke: plays Coral Coast including the gunboat arena boss.
const StageSim := preload("res://scripts/stage_sim.gd")
const StageData := preload("res://scripts/stage_data.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var sim := StageSim.new()
	if not sim.setup(3, 21):
		printerr("SMOKE FAIL: Coral Coast did not load")
		quit(1)
		return
	# Fast-forward the approach, keeping the player alive, then wreck the boss.
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
	var pos := Vector2(gun.x - sim.camera_x, gun.y - 40.0)
	sim.damage_entity(gun, 999.0, pos, true)
	for i in 50:
		sim.step(dt)
	if sim.state != "cleared" or sim.end_reason != "boss":
		printerr("SMOKE FAIL: expected cleared/boss, got %s/%s" % [sim.state, sim.end_reason])
		quit(1)
		return
	print("SMOKE OK stage=3 quota=", sim.quota, " kills=", sim.kills, " score=", sim.score,
		" camera_x=", int(sim.camera_x), " time=", snapped(sim.time, 0.01),
		" reason=", sim.end_reason, " steps=", steps)
	quit(0)
