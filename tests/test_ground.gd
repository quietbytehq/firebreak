extends SceneTree
## Ground contact along the panorama, moving-sprite facing vs velocity,
## and vehicles / camels staying on their paths.
const StageSim := preload("res://scripts/stage_sim.gd")
const StageData := preload("res://scripts/stage_data.gd")
const Ground := preload("res://scripts/stage_ground.gd")
const SpriteArt := preload("res://scripts/sprite_art.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")

func fresh(stage: int):
	var sim = StageSim.new()
	sim.setup(stage, 7)
	sim.stage.ambient = []
	sim.stage.waves = []
	return sim

func run() -> void:
	for n in [1, 2]:
		var s := StageData.load_stage(n)
		check(StageData.validate(s).is_empty(), "stage %d still validates with the ground map" % n)
		_ground_contact(n, s)
		_no_water(n, s)
	_paratrooper_lands()
	_facing_vs_velocity()
	_vehicles_on_path()
	_camels_on_sand()
	_snipers_stay_planted()
	_near_body_visible()
	_death_scale_matches_living()
	_death_stays_on_ground()
	for n in [1, 2]:
		_sixty_second_contact(n)
	print("Ground: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

func _ground_contact(stage_n: int, s: Dictionary) -> void:
	var sim = fresh(stage_n)
	# Walk the camera along the scroll and spawn each ground band in view.
	var max_x := float(s.get("world_width", 3840)) - 1920.0
	var ok := 0
	var tried := 0
	var cam := 0.0
	while cam <= max_x + 1.0:
		sim.camera_x = cam
		for band in ["far", "mid", "near"]:
			var p: Vector2 = sim.pick_point(band, 140.0)
			if p.x < 0.0:
				continue
			tried += 1
			var e: Dictionary = sim.spawn("rifleman", band, {"world_x": p.x})
			var gy := Ground.ground_y(s, band, e.x)
			if absf(e.y - gy) <= 1.5 and Ground.on_ground(s, band, e.x):
				ok += 1
			sim.entities.erase(e)
		cam += 240.0
	check(tried >= 8, "stage %d produced ground spawns across the scroll (%d)" % [stage_n, tried])
	check(ok == tried and tried > 0, "stage %d: every unplanted spawn sits on its band ground (%d/%d)" % [stage_n, ok, tried])

func _no_water(stage_n: int, s: Dictionary) -> void:
	# Mid and far spans must not cover the known water: river village 1350-2300,
	# Dune Sea oasis 1550-2180.
	var lo: float
	var hi: float
	if stage_n == 1:
		lo = 1350.0; hi = 2280.0
	else:
		lo = 1550.0; hi = 2180.0
	var wet := 0
	for band in ["mid", "far"]:
		var x := lo
		while x <= hi:
			if Ground.on_ground(s, band, x):
				wet += 1
			x += 40.0
	check(wet == 0, "stage %d mid/far ground skips the water (%d hits)" % [stage_n, wet])
	# Near must also skip the river village river gap.
	if stage_n == 1:
		var nwet := 0
		var x2 := 1300.0
		while x2 <= 2000.0:
			if Ground.on_ground(s, "near", x2):
				nwet += 1
			x2 += 40.0
		check(nwet == 0, "River Village near band skips the river fence gap")

func _paratrooper_lands() -> void:
	var sim = fresh(1)
	sim.camera_x = 0.0
	var p: Vector2 = sim.pick_point("mid", 140.0)
	check(p.x >= 0.0, "a mid landing site exists at the start of River Village")
	var e: Dictionary = sim.spawn("paratrooper", "mid", {"world_x": p.x})
	check(e.state == "descend" and e.y < e.ground_y, "paratrooper starts in the air")
	for i in 60 * 12:
		sim.step(1.0 / 60.0)
		if e.get("landed", false):
			break
	check(e.get("landed", false), "paratrooper lands")
	var gy := Ground.ground_y(sim.stage, "mid", e.x)
	check(absf(e.y - gy) <= 2.0, "paratrooper lands on the mid ground line")

func _facing_vs_velocity() -> void:
	# Stage 1 villagers (left-facing art) and Dune Sea robes (right-facing art).
	var sim = fresh(1)
	var v: Dictionary = sim.spawn("villager", "mid", {"kind": "farmer"})
	v.vx = 50.0; v.facing = 1.0
	check(SpriteArt.villager_flip(v) < 0.0, "stage 1 villager walking right is flipped")
	sim.step(0.2)
	check(v.facing > 0.0 and v.vx > 0.0, "stage 1 villager facing matches +vx")
	var sim2 = fresh(2)
	var r: Dictionary = sim2.spawn("villager", "mid", {"kind": "robe_man"})
	r.vx = 50.0; r.facing = 1.0
	check(SpriteArt.villager_native(r) == 1.0, "robe native facing is right")
	check(SpriteArt.villager_flip(r) > 0.0, "robe villager walking right is unflipped (faces right)")
	r.vx = -50.0; r.facing = -1.0
	check(SpriteArt.villager_flip(r) < 0.0, "robe villager walking left is flipped (faces left)")
	sim2.step(0.2)
	check(r.facing < 0.0 and r.vx < 0.0, "robe villager facing follows -vx")

func _vehicles_on_path() -> void:
	for stage_n in [1, 2]:
		var sim = fresh(stage_n)
		# Put the camera where the track is in view (the right half of each panorama).
		sim.camera_x = 1920.0
		var typ := "truck" if stage_n == 1 else "technical"
		var e: Dictionary = sim.spawn(typ, "mid")
		check(str(e.get("path", "")) == "track", "stage %d %s is assigned the track" % [stage_n, typ])
		check(Ground.on_road(sim.stage, "track", e.x), "stage %d %s spawns on the track" % [stage_n, typ])
		var off := 0
		for i in 60 * 8:
			sim.step(1.0 / 60.0)
			if e.get("escaped", false) or not (e in sim.entities):
				break
			if Ground.dist_to_road(sim.stage, "track", e.x, e.ground_y) > 3.0:
				off += 1
			if absf(e.vx) > 1.0 and ((e.vx < 0.0 and e.facing >= 0.0) or (e.vx > 0.0 and e.facing <= 0.0)):
				off += 1
		check(off == 0, "stage %d %s stays on the track and faces its travel (%d slips)" % [stage_n, typ, off])
		if typ == "technical":
			# Must not cross the oasis: track starts around x 2220.
			check(Ground.road_bounds(sim.stage, "track").x > 2000.0, "Dune Sea track starts after the oasis")

func _camels_on_sand() -> void:
	var sim = fresh(2)
	sim.camera_x = 0.0
	var e: Dictionary = sim.spawn("camel", "mid")
	check(str(e.get("path", "")) == "sand", "mid camel uses the sand track")
	check(Ground.on_road(sim.stage, "sand", e.x), "camel spawns on the sand track")
	var off := 0
	for i in 60 * 10:
		sim.step(1.0 / 60.0)
		if e.get("escaped", false) or not (e in sim.entities):
			break
		# Bounce is a few pixels; compare against ground_y (pre-bounce).
		if Ground.dist_to_road(sim.stage, "sand", e.x, e.ground_y) > 3.0:
			off += 1
		if e.x > 1550.0:
			off += 1  # walked into the oasis
		if absf(e.vx) > 1.0 and ((e.vx < 0.0 and e.facing >= 0.0) or (e.vx > 0.0 and e.facing <= 0.0)):
			off += 1
	check(off == 0, "camel stays on the sand, faces its travel, and skips the oasis (%d slips)" % off)
	# Far camel uses the far sand path on the village approach.
	sim = fresh(2)
	sim.camera_x = 1920.0
	var f: Dictionary = sim.spawn("camel", "far")
	check(str(f.get("path", "")) == "sand_far", "far camel uses the far sand track")

func _snipers_stay_planted() -> void:
	var sim = fresh(2)
	sim.camera_x = 1920.0
	var e: Dictionary = sim.spawn("sniper", "mid", {"world_x": 3380, "world_y": 700})
	check(e.planted and is_equal_approx(e.y, 700.0), "a rooftop sniper keeps its planted y")
	sim.step(1.0)
	check(is_equal_approx(e.y, 700.0), "a rooftop sniper is not snapped down to the road")

func _near_body_visible() -> void:
	# A near rifleman standing on the sandbags must still show above the HUD.
	for stage_n in [1, 2]:
		var sim = fresh(stage_n)
		sim.camera_x = 0.0 if stage_n == 2 else 0.0
		var p: Vector2 = sim.pick_point("near", 140.0)
		if p.x < 0.0:
			sim.camera_x = 2500.0
			p = sim.pick_point("near", 140.0)
		check(p.x >= 0.0, "stage %d has a near standing site" % stage_n)
		var e: Dictionary = sim.spawn("rifleman", "near", {"world_x": p.x})
		var top: float = e.y - e.size.y * e.scale
		check(top < sim.HUD_BAND_TOP - 120.0, "stage %d near soldier body shows above the HUD (top %.0f, feet %.0f)" % [stage_n, top, e.y])
		check(Ground.on_ground(sim.stage, "near", e.x), "stage %d near soldier is on a near span" % stage_n)

func _death_scale_matches_living() -> void:
	SpriteArt.preload_all()
	for stage_n in [1, 2]:
		var sim = fresh(stage_n)
		for band in ["far", "mid", "near"]:
			var p: Vector2 = sim.pick_point(band, 140.0, 0.4)
			if p.x < 0.0:
				p = sim.pick_point(band, 80.0)
			if p.x < 0.0:
				check(false, "stage %d %s has no ground point for death-scale" % [stage_n, band])
				continue
			for kneel in [false, true]:
				var e: Dictionary = sim.spawn("rifleman", band, {"world_x": p.x})
				if e.is_empty():
					check(false, "stage %d %s rifleman failed to spawn" % [stage_n, band])
					continue
				if kneel:
					e.pose = "kneel"; e.size = Vector2(150, 250); e.variant = 3
				e.state = "aim"; e.rise = 1.0; e.muzzle = 0.0
				var k_live := SpriteArt.soldier_draw_k(e)
				var target := SpriteArt.TARGET_H.kneel if kneel else SpriteArt.TARGET_H.rifleman
				check(absf(k_live * _live_fig(e, kneel) - float(e.scale) * target) <= 1.5,
					"stage %d %s %s living height tracks TARGET_H (k=%.4f)" % [stage_n, band, "kneel" if kneel else "stand", k_live])
				e.state = "dying"; e.timer = 0.6; e.fall_rot = 0.2
				var k_die := SpriteArt.soldier_draw_k(e)
				check(absf(k_live - k_die) <= 0.0001,
					"stage %d %s %s death scale matches living (live=%.4f die=%.4f)" % [stage_n, band, "kneel" if kneel else "stand", k_live, k_die])
				# The bug used the short stage-1 side-view refs, which oversized dune skins.
				if str(e.get("skin", "")) != "":
					var bad := float(e.scale) * target / SpriteArt.fig_h("rifleman_kneel" if kneel else "rifleman_aim")
					check(absf(k_die - bad) > 0.05,
						"stage %d %s %s must not use the unsinned side-view death scale (k=%.4f bad=%.4f)" % [stage_n, band, "kneel" if kneel else "stand", k_die, bad])
				sim.entities.erase(e)

func _live_fig(e: Dictionary, kneel: bool) -> float:
	var name := "rifleman_kneel_front" if kneel else "rifleman_front_aim"
	var skin := str(e.get("skin", ""))
	if skin != "" and SpriteArt.tex(skin + name.substr(8)) != null:
		name = skin + name.substr(8)
	return SpriteArt.fig_h(name)

func _death_stays_on_ground() -> void:
	# Log y vs ground_y for a mid kneeling Dune Sea militiaman across the
	# shot and the death, the case in s2early-016s.jpg.
	var sim = fresh(2)
	var p: Vector2 = sim.pick_point("mid", 140.0, 0.45)
	check(p.x >= 0.0, "Dune Sea mid spawn for death log")
	var e: Dictionary = sim.spawn("rifleman", "mid", {"world_x": p.x})
	e.pose = "kneel"; e.size = Vector2(150, 250); e.variant = 3
	e.state = "aim"; e.rise = 1.0
	var gy0 := Ground.ground_y(sim.stage, "mid", e.x)
	var lines: Array = []
	for i in 12:
		sim.step(1.0 / 60.0)
		# Re-find e (step shouldn't drop an aiming rifleman this fast)
		if e not in sim.entities:
			break
		lines.append("t=%.3f state=%s y=%.2f ground_y=%.2f off=%.2f k=%.4f" % [
			sim.time, e.state, e.y, Ground.ground_y(sim.stage, "mid", e.x),
			Ground.feet_off(sim.stage, e), SpriteArt.soldier_draw_k(e)])
	var y_before := float(e.y)
	sim.damage_entity(e, 99.0, Vector2(e.x - sim.camera_x, e.y - 80.0))
	check(e.state == "dying", "mid kneel rifleman enters dying after a fatal hit")
	var max_off := 0.0
	for i in 36:
		sim.step(1.0 / 60.0)
		if e not in sim.entities:
			break
		var off := Ground.feet_off(sim.stage, e)
		max_off = maxf(max_off, off)
		lines.append("t=%.3f state=%s y=%.2f ground_y=%.2f off=%.2f k=%.4f fall_rot=%.2f" % [
			sim.time, e.state, e.y, Ground.ground_y(sim.stage, "mid", e.x),
			off, SpriteArt.soldier_draw_k(e), e.fall_rot])
		check(absf(e.y - y_before) <= 0.01, "dying mid kneel y must not leave the ground (y=%.2f was %.2f)" % [e.y, y_before])
	check(max_off <= Ground.feet_slack(e), "dying mid kneel feet stay on the mid ground (max off=%.2f)" % max_off)
	check(absf(y_before - gy0) <= 1.5, "pre-death y was on mid ground (y=%.2f gy=%.2f)" % [y_before, gy0])
	print("DEATH LOG mid kneel Dune Sea:
  " + "
  ".join(lines))

func _sixty_second_contact(stage_n: int) -> void:
	var sim = StageSim.new()
	sim.setup(stage_n, 7)
	sim.diff.accuracy = 0.0
	var samples := 0
	var dying_n := 0
	var offenders := 0
	var first := ""
	for i in 60 * 60:
		# Periodically drop a ground enemy so dying frames are sampled too.
		if i % 20 == 0:
			for e in sim.entities:
				if e.type in ["rifleman", "mg", "sniper"] and e.state != "dying" and e.get("rise", 1.0) >= 1.0:
					sim.damage_entity(e, 99.0, Vector2(e.x - sim.camera_x, e.y - 80.0))
					break
		sim.step(1.0 / 60.0)
		var hits: Array = []
		var n := sim.grounded_offenders(hits)
		for e in sim.entities:
			if Ground.feet_off(sim.stage, e) < 0.0:
				continue
			samples += 1
			if e.state == "dying":
				dying_n += 1
		if n > 0:
			offenders += n
			if first == "" and not hits.is_empty():
				var h: Dictionary = hits[0]
				first = "t=%.2f %s id=%s band=%s y=%.1f off=%.1f" % [
					sim.time, h.type, str(h.id), h.band, h.y, h.off]
		if sim.state != "playing":
			break
	check(samples > 200, "stage %d 60s autoplay sampled grounded feet (%d)" % [stage_n, samples])
	check(dying_n > 20, "stage %d 60s autoplay sampled dying feet (%d)" % [stage_n, dying_n])
	check(offenders == 0, "stage %d 60s: every living and dying ground unit stays on the map (%d offenders: %s)" % [stage_n, offenders, first])

