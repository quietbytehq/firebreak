extends SceneTree
## Stage timer never exceeds 180 s; the stage always ends; clearing, failing,
## pausing, scrolling and determinism.
const StageSim := preload("res://scripts/stage_sim.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")

## Simple bot: shoots the most dangerous visible enemy, never villagers.
func bot_step(sim, skill: float) -> void:
	for e in sim.entities:
		if not sim.is_hittable(e) or e.type == "villager": continue
		if e.age < skill: continue
		var p: Vector2 = sim.hitbox(e).get_center() - Vector2(sim.camera_x, 0)
		if p.x < 0 or p.x > 1920: continue
		var safe := true
		# A careful player also keeps the weapon's bullet spread off civilians.
		var sp: float = float(sim.weapon().get("spread", 0.0)) + 2.0
		for off in ([Vector2(-46, 10), Vector2.ZERO, Vector2(46, 10)] if sim.spread_timer > 0.0 else [Vector2.ZERO]):
			for k in 9:
				var ring: Vector2 = Vector2.ZERO if k == 0 else Vector2.from_angle(TAU * k / 8.0) * sp
				var under: Dictionary = sim.entity_at(p + off + ring)
				if not under.is_empty() and under.type == "villager": safe = false
		if safe:
			sim.fire(p); return

func play(seed: int, skill: float, dt: float = 1.0 / 60.0) -> Dictionary:
	var sim = StageSim.new(); sim.setup(1, seed)
	var max_t := 0.0
	var steps := 0
	while sim.state == "playing" and steps < 200 * 60:
		if skill >= 0.0: bot_step(sim, skill)
		sim.step(dt); steps += 1
		max_t = maxf(max_t, sim.time)
	return {"sim": sim, "max_t": max_t, "steps": steps}

func run() -> void:
	# Idle player: the stage still ends within 180 s (failed or held).
	var idle := play(3, -1.0)
	check(idle.sim.state != "playing", "idle run ends")
	check(idle.max_t <= 180.0, "timer never exceeds 180 s (idle)")
	check(idle.sim.state == "failed", "an idle player is overrun (enemies are dangerous)")
	# Skilled bot clears or holds; average bot survives stage 1.
	var results := []
	for seed in [1, 2, 3, 4, 5]:
		var r := play(seed, 0.9)
		results.append([r.sim.state, r.sim.end_reason, int(r.sim.time), int(r.sim.health), r.sim.kills, r.sim.score])
		check(r.max_t <= 180.0, "timer never exceeds 180 s (seed %d)" % seed)
		check(r.sim.state == "cleared", "a steady player clears stage 1 (seed %d)" % seed)
		check(r.sim.stats.villagers_hit == 0, "careful bot never hits villagers")
		check(r.sim.clear_bonus > 0 and r.sim.score > r.sim.clear_bonus, "clear bonus added")
	# Fast bot clears by quota before time runs out.
	var fast := play(9, 0.3)
	check(fast.sim.state == "cleared" and fast.sim.end_reason == "quota" and fast.sim.time < 180.0, "clearing the quota ends the stage early")
	# Determinism: the same seed and inputs give the same result.
	var a := play(42, 0.9); var b := play(42, 0.9)
	check(a.sim.score == b.sim.score and a.sim.kills == b.sim.kills and is_equal_approx(a.sim.time, b.sim.time), "same seed, same run")
	# Pause stops time, spawning and enemy fire.
	var sim = StageSim.new(); sim.setup(1, 8)
	for i in 600: sim.step(1.0 / 60.0)
	var t: float = sim.time; var hp: float = sim.health; var n: int = sim.entities.size()
	sim.paused = true
	for i in 600: sim.step(1.0 / 60.0)
	check(sim.time == t and sim.health == hp and sim.entities.size() == n, "pause freezes the stage")
	check(not sim.fire(Vector2(960, 540)), "cannot fire while paused")
	sim.paused = false; sim.step(1.0 / 60.0)
	check(sim.time > t, "resume continues")
	# Scrolling: slow, monotonic, left to right, across the panorama.
	sim = StageSim.new(); sim.setup(1, 1)
	var prev := -1.0; var mono := true; var fastest := 0.0
	for i in 1800:
		var x: float = sim.camera_at(i * 0.1)
		if x < prev - 0.001: mono = false
		if prev >= 0.0: fastest = maxf(fastest, (x - prev) / 0.1)
		prev = x
	check(mono, "camera only pans left to right")
	check(fastest < 40.0, "scroll is slow (max %.1f px/s)" % fastest)
	check(is_equal_approx(sim.camera_at(180.0), 1920.0), "camera reaches the end of the panorama")
	# Health reaching zero fails the stage.
	sim = StageSim.new(); sim.setup(1, 1); sim.damage_player(150.0); sim.step(0.016)
	check(sim.state == "failed", "zero health fails the stage")
	print("Stage flow: ", checks, " checks, ", failures, " failures; runs ", results, " fast ", [fast.sim.end_reason, int(fast.sim.time)])
	quit(0 if failures == 0 else 1)
