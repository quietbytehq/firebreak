extends SceneTree
## 0.2.1: every enemy faces and fires toward the player (who stands behind
## the screen), never sideways along the battlefield at other soldiers.
const StageSim := preload("res://scripts/stage_sim.gd")
const SpriteArt := preload("res://scripts/sprite_art.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func fresh():
	var sim = StageSim.new(); sim.setup(1, 5); sim.stage.ambient = []; sim.stage.waves = []
	return sim

## The barrel must sit on the player's side of the body: a figure left of
## centre aims right (toward the middle), one right of centre aims left.
func barrel_toward_centre(e: Dictionary, sim) -> bool:
	var pos := Vector2(e.x - sim.camera_x, e.y)
	var mz: Vector2 = SpriteArt.muzzle_point(e, pos)
	if absf(pos.x - 960.0) < sim.FACE_DEADZONE: return true
	# A front-on gun (the MG nest) points straight out of the screen at the camera.
	if absf(mz.x - pos.x) <= 4.0 * float(e.scale): return true
	return signf(mz.x - pos.x) == signf(960.0 - pos.x)

func run() -> void:
	var sim = fresh()
	var placed := 0; var faced := 0; var barrels := 0
	for type in ["rifleman", "mg", "paratrooper"]:
		for band in ["far", "mid", "near"]:
			if type == "mg" and band == "far": continue
			for frac in [0.05, 0.25, 0.75, 0.95]:
				var e: Dictionary = sim.spawn(type, band, {"frac": frac})
				if e.is_empty(): continue
				placed += 1
				sim.step(1.0 / 60.0)
				var sx: float = e.x - sim.camera_x
				if absf(sx - 960.0) < sim.FACE_DEADZONE or e.facing == (1.0 if sx < 960.0 else -1.0): faced += 1
				if barrel_toward_centre(e, sim): barrels += 1
				sim.entities.erase(e)
	check(placed >= 20, "placed enemies across the screen (%d)" % placed)
	check(faced == placed, "every enemy faces the player's side (%d of %d)" % [faced, placed])
	check(barrels == placed, "every barrel points in toward the player, not along the line (%d of %d)" % [barrels, placed])

	# Left and right soldiers face opposite ways (toward each other's side of
	# the screen centre = toward the player), and their shots both end low,
	# at the player's edge of the screen.
	sim = fresh()
	var left: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 300.0, "world_y": 752.0})
	var right: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 1650.0, "world_y": 752.0})
	sim.step(1.0 / 60.0)
	check(left.facing > 0.0 and right.facing < 0.0, "soldiers on both sides turn in toward the player")
	check(SpriteArt.front_flip(left) != SpriteArt.front_flip(right), "their front poses are mirrored to point inward")
	var shots := []
	sim.diff.accuracy = 1.0
	sim.event.connect(func(n, d): if n == "enemy_fire": shots.append(d))
	for i in 60 * 6: sim.step(1.0 / 60.0)
	check(shots.size() >= 2, "both soldiers fired (%d shots)" % shots.size())
	var toward := 0
	for d in shots:
		var e: Dictionary = d.entity
		var from: Vector2 = SpriteArt.muzzle_point(e, Vector2(e.x - sim.camera_x, e.y))
		var to: Vector2 = d.to
		# Out of the screen toward the player: ends lower (nearer the camera) than the barrel.
		if to.y > from.y + 100.0 and to.y >= 900.0 and to.x >= 0.0 and to.x <= 1920.0: toward += 1
	check(toward == shots.size(), "every shot travels out of the screen toward the player (%d of %d)" % [toward, shots.size()])
	var sides_ok := true
	for d in shots:
		if (d.entity == left and d.side >= 0.0) or (d.entity == right and d.side <= 0.0): sides_ok = false
	check(sides_ok, "hit marker side matches where the shot came from")

	# Aiming and firing frames are all front/three-quarter poses.
	var bad := []
	var probe := {"type": "rifleman", "state": "aim", "muzzle": 0.0, "variant": 0, "pose": "", "timer": 1.0}
	for v in 4:
		for st in ["rise", "aim", "recover", "duck"]:
			for mz in [0.0, 0.05]:
				for pose in ["", "kneel"]:
					probe.variant = v; probe.state = st; probe.muzzle = mz; probe.pose = pose
					var fr: String = SpriteArt._soldier_frame(probe)
					if not (fr in SpriteArt.FRONT_FRAMES): bad.append(fr)
	check(bad.is_empty(), "soldiers never aim or fire in a side pose (%s)" % str(bad))
	for name in SpriteArt.FRONT_FRAMES:
		check(SpriteArt.tex(name) != null, "front pose loads: " + name)

	# Facing does not flicker while the camera scrolls past the centre.
	sim = fresh()
	var c: Dictionary = sim.spawn("mg", "mid", {"world_x": 960.0, "world_y": 752.0})
	var flips := 0; var last: float = c.facing
	for i in 120:
		sim.camera_x = float(i)
		sim.face_player(c)
		if c.facing != last: flips += 1; last = c.facing
	check(flips <= 1, "facing turns at most once as the camera scrolls past (%d)" % flips)

	# Helicopter door gunner shots also come at the player.
	sim = fresh()
	var h: Dictionary = sim.spawn("heli", "sky", {"from": "left"})
	var hs := []
	sim.event.connect(func(n, d): if n == "enemy_fire" and d.entity == h: hs.append(d))
	for i in 60 * 8: sim.step(1.0 / 60.0)
	var ok := hs.size() > 0
	for d in hs:
		if d.to.y < 900.0: ok = false
	check(ok, "door gunner rounds come out toward the player (%d)" % hs.size())

	# Villager walk art faces left; flip it so they walk in the direction of vx.
	check(SpriteArt.VILLAGER_NATIVE == -1.0, "villager frames are painted facing left")
	sim = fresh()
	var right_v: Dictionary = sim.spawn("villager", "mid")
	right_v.vx = 50.0; right_v.facing = 1.0
	var left_v: Dictionary = sim.spawn("villager", "mid")
	left_v.vx = -50.0; left_v.facing = -1.0
	check(SpriteArt.villager_flip(right_v) < 0.0, "a villager walking right is drawn flipped (faces right)")
	check(SpriteArt.villager_flip(left_v) > 0.0, "a villager walking left is drawn unflipped (faces left)")
	check(SpriteArt.villager_flip(right_v) == -right_v.facing, "villager flip is facing times VILLAGER_NATIVE")
	# Dune Sea robes are painted facing right (the opposite of stage 1).
	var robe_r := {"kind": "robe_man", "facing": 1.0}
	var robe_l := {"kind": "robe_woman", "facing": -1.0}
	check(SpriteArt.villager_native(robe_r) == 1.0, "robe frames are painted facing right")
	check(SpriteArt.villager_flip(robe_r) > 0.0, "a robe villager walking right is drawn unflipped")
	check(SpriteArt.villager_flip(robe_l) < 0.0, "a robe villager walking left is drawn flipped")

	print("Facing: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
