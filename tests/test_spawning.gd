extends SceneTree
## Spawning respects the three depth bands and the landscape zones.
const StageSim := preload("res://scripts/stage_sim.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func in_zone(sim, e: Dictionary) -> bool:
	for z in sim.band_info(e.band).zones:
		if e.x >= float(z[0]) - 1.0 and e.x <= float(z[1]) + 1.0 and is_equal_approx(e.ground_y, float(z[2])): return true
	return false
func run() -> void:
	var sim = StageSim.new()
	check(sim.setup(1, 7), "sim setup")
	var heights := {}
	for band in ["far", "mid", "near"]:
		var ok := true
		var visible := true
		for i in 40:
			var e: Dictionary = sim.spawn("rifleman", band)
			if e.is_empty(): ok = false; continue
			if e.band != band or not is_equal_approx(e.scale, sim.band_scale(band)) or not in_zone(sim, e): ok = false
			if e.x < sim.camera_x or e.x > sim.camera_x + 1920.0: visible = false
		check(ok, "riflemen spawn on %s band ground inside its zones" % band)
		check(visible, "%s spawns are inside the view" % band)
		heights[band] = sim.entities.back().size.y * sim.entities.back().scale
		sim.entities.clear()
	check(heights.far < heights.mid and heights.mid < heights.near, "far targets are smaller than near ones")
	# Camera over the river: mid band has no ground there, so spawns fall back.
	sim.camera_x = 1300.0
	var e: Dictionary = sim.spawn("rifleman", "mid")
	check(not e.is_empty() and in_zone(sim, e), "spawn over water falls back to valid ground")
	sim.entities.clear(); sim.camera_x = 0.0
	var p: Dictionary = sim.spawn("paratrooper", "mid")
	check(p.state == "descend" and p.y < p.ground_y, "paratrooper starts in the air")
	var cnt := {"fired": 0, "bad": 0}
	sim.event.connect(func(n, d): if n == "enemy_fire": cnt.fired += 1)
	for i in 600:
		sim._update_entity(p, 1.0 / 60.0)
		if p.state != "descend": break
	check(p.state != "descend" and is_equal_approx(p.y, p.ground_y), "paratrooper lands on its band")
	check(cnt.fired >= 1, "paratrooper shoots while descending")
	var landed_fire: int = cnt.fired
	for i in 300: sim._update_entity(p, 1.0 / 60.0)
	check(cnt.fired > landed_fire, "paratrooper keeps shooting after landing")
	var mg: Dictionary = sim.spawn("mg", "mid", {"world_x": 1150, "world_y": 748, "scale": 0.46})
	check(mg.x == 1150.0 and mg.max_hp >= 3.0, "machine-gun nest uses its fixed position and is tougher")
	var v: Dictionary = sim.spawn("villager", "mid")
	check(absf(v.vx) > 0.0, "villagers walk")
	var f: Dictionary = sim.spawn("food", "sky", {"kind": "rice"})
	check(f.y < 0.0 and f.vy > 0.0 and f.kind == "rice", "food falls from the sky")
	# Full timeline: spawns happen and nothing is placed outside its band zones.
	var sim2 = StageSim.new(); sim2.setup(1, 11)
	var spawned := {}
	sim2.event.connect(func(n, d):
		if n == "spawn":
			spawned[d.entity.type] = spawned.get(d.entity.type, 0) + 1
			if d.entity.band in ["far", "mid", "near"] and d.entity.type != "truck" and not d.entity.has("fixed") and d.entity.type != "mg" and not in_zone(sim2, d.entity): cnt.bad += 1)
	for i in 180 * 30:
		sim2.health = 100.0
		sim2.step(1.0 / 30.0)
	for t in ["rifleman", "paratrooper", "mg", "villager", "food", "powerup", "truck"]:
		check(spawned.get(t, 0) > 0, "timeline spawns " + t)
	check(cnt.bad == 0, "no spawn outside its landscape zone (%d)" % cnt.bad)
	check(spawned.get("rifleman", 0) >= 40, "enough riflemen for a 3-minute stage")
	print("Spawning: ", checks, " checks, ", failures, " failures; spawned ", spawned)
	quit(0 if failures == 0 else 1)
