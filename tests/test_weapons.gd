extends SceneTree
## 0.2.0 weapons: grenade loadout and blast size, civilians in grenade blasts,
## the air strike (destroys every enemy on screen, never civilians), the air
## strike drop, and the truck parking clear of the painted background truck.
const StageSim := preload("res://scripts/stage_sim.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func fresh():
	var sim = StageSim.new(); sim.setup(1, 11); sim.stage.ambient = []; sim.stage.waves = []
	return sim
func settle(e: Dictionary) -> void:
	e.rise = 1.0; e.state = "aim"; e.timer = 30.0
func center(sim, e: Dictionary) -> Vector2:
	return sim.hitbox(e).get_center() - Vector2(sim.camera_x, 0)
func run() -> void:
	# Loadout.
	var sim = fresh()
	check(sim.grenades == 5, "Rayan starts with 5 grenades (%d)" % sim.grenades)
	check(sim.airstrikes == 1, "one air strike per stage at the start (%d)" % sim.airstrikes)
	sim.grenades = 0; sim.airstrikes = 0; sim.setup(1, 12)
	check(sim.grenades == 5 and sim.airstrikes == 1, "a new stage restores 5 grenades and 1 air strike")
	# Blast radius covers ~30% of the screen.
	var frac: float = PI * sim.GRENADE_RADIUS * sim.GRENADE_RADIUS / (1920.0 * 1080.0)
	check(absf(frac - 0.30) < 0.005, "grenade blast covers about 30%% of the screen (%.3f)" % frac)
	check(sim.GRENADE_RADIUS > 430.0 and sim.GRENADE_RADIUS < 460.0, "grenade radius about 445 px")
	# Inside / outside the blast. Ground y 748 on the mid band; target point at the soldiers' chest height.
	sim = fresh()
	var inside: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 900, "world_y": 748}); settle(inside)
	var edge: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 1250, "world_y": 748}); settle(edge)
	var outside: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 1500, "world_y": 748}); settle(outside)
	var g0: int = sim.grenades
	check(sim.throw_grenade(Vector2(900, 670)), "grenade thrown toward the crosshair")
	check(sim.grenades == g0 - 1, "grenade count drops by one")
	check(sim.grenades_in_flight.size() == 1 and sim.grenades_in_flight[0].to.x == 900.0 + sim.camera_x, "grenade flies to the aimed point")
	for i in 45: sim.step(1.0 / 60.0)
	check(inside.state == "dying", "enemy at the aim point is destroyed")
	check(edge.state == "dying", "enemy 350 px away is inside the blast")
	check(outside.state != "dying", "enemy 600 px away is outside the blast")
	# Grenades hurt civilians, with the usual penalty.
	sim = fresh(); sim.score = 2000
	var v: Dictionary = sim.spawn("villager", "mid", {"world_x": 1000, "world_y": 748})
	var r: Dictionary = sim.spawn("rifleman", "mid", {"world_x": 950, "world_y": 748}); settle(r)
	sim.throw_grenade(Vector2(980, 680))
	for i in 45: sim.step(1.0 / 60.0)
	check(v.state == "dying", "a grenade kills a civilian inside the blast")
	check(sim.stats.villagers_hit == 1, "civilian casualty counted")
	check(sim.health == 100.0 - sim.VILLAGER_PENALTY_HEALTH, "civilian in a grenade blast costs life")
	check(sim.score == 2000 - sim.VILLAGER_PENALTY_SCORE + int(100 * 1.2), "civilian costs score, soldier still scores")
	# No grenades left.
	sim.grenades = 0
	check(not sim.throw_grenade(Vector2(900, 600)), "no throw with zero grenades")
	# Air strike: everything hostile on screen is destroyed, civilians never.
	sim = fresh(); sim.diff.accuracy = 0.0
	var foes := []
	for band in ["far", "mid", "near"]:
		var e: Dictionary = sim.spawn("rifleman", band); settle(e); foes.append(e)
	var hiding: Dictionary = sim.spawn("rifleman", "mid"); hiding.rise = 0.0; hiding.state = "rise"; foes.append(hiding)
	foes.append(sim.spawn("mg", "mid", {"world_x": 1150, "world_y": 752, "scale": 0.46}))
	foes.append(sim.spawn("paratrooper", "mid"))
	var truck: Dictionary = sim.spawn("truck", "mid"); truck.x = sim.camera_x + 1400.0; truck.state = "aim"; truck.timer = 30.0; foes.append(truck)
	var heli: Dictionary = sim.spawn("heli", "sky", {"from": "right"}); heli.sx = 900.0; heli.x = sim.camera_x + 900.0; foes.append(heli)
	var civ := []
	for i in 4:
		civ.append(sim.spawn("villager", ["far", "mid"][i % 2]))
	var food: Dictionary = sim.spawn("food", "sky", {"kind": "rice", "world_x": 700})
	var ev := {"impact": 0, "strike": 0}
	sim.event.connect(func(n, d):
		if n == "airstrike": ev.strike += 1
		if n == "airstrike_impact": ev.impact += 1)
	var kills0: int = sim.kills
	check(sim.call_airstrike(), "air strike called")
	check(sim.airstrikes == 0 and ev.strike == 1, "air strike used up and announced")
	check(not sim.call_airstrike(), "cannot call a second strike without another")
	for i in int(sim.AIRSTRIKE_IMPACT * 60.0) + 6: sim.step(1.0 / 60.0)
	check(ev.impact == 1, "bombs land once")
	var all_down := true
	for e in foes:
		if not (e.state == "dying" or e.state == "crash" or not sim.entities.has(e)): all_down = false
	check(all_down, "air strike destroys every soldier, MG nest, paratrooper, truck and helicopter on screen")
	check(heli.state == "crash" or not sim.entities.has(heli), "air strike brings the helicopter down")
	check(sim.kills - kills0 == foes.size(), "every destroyed enemy counts as a kill (%d of %d)" % [sim.kills - kills0, foes.size()])
	var civ_ok := true
	for c in civ:
		if c.state == "dying" or c.hp < c.max_hp: civ_ok = false
	check(civ_ok, "air strike never harms civilians")
	check(sim.stats.villagers_hit == 0 and sim.health == 100.0, "no civilian penalty from an air strike")
	check(food.state != "dying", "air strike leaves supply drops alone")
	for i in 120: sim.step(1.0 / 60.0)
	check(sim.strike.is_empty(), "strike finishes")
	# Rare drop adds a strike.
	sim = fresh(); sim.airstrikes = 0
	var drop: Dictionary = sim.spawn("powerup", "sky", {"kind": "airstrike", "world_x": 900}); drop.y = 400.0
	sim.fire(center(sim, drop))
	check(sim.airstrikes == 1, "an air strike drop adds one strike")
	var kinds: Dictionary = {}
	for a in sim.StageData.load_stage(1).ambient:
		if a.type == "powerup": kinds = a.kinds
	check(kinds.has("airstrike") and float(kinds.airstrike) < float(kinds.ammo) * 0.25, "air strike drop is rare")
	# Truck never parks beside the truck painted into the background.
	sim = StageSim.new(); sim.setup(1, 3)
	var spans: Array = sim.stage.get("truck_avoid", [])
	check(not spans.is_empty(), "stage lists the painted truck's position")
	var bad := 0
	for cam in range(0, 1921, 60):
		sim.camera_x = float(cam)
		var tr: Dictionary = sim.spawn("truck", "mid")
		if tr.is_empty(): continue
		var half: float = tr.size.x * tr.scale * 0.5
		for sp in spans:
			if tr.target_x + half > float(sp[0]) and tr.target_x - half < float(sp[1]): bad += 1
		sim.entities.erase(tr)
	check(bad == 0, "truck parking spot never overlaps the painted truck (%d overlaps)" % bad)
	sim = StageSim.new(); sim.setup(1, 3); sim.stage.ambient = []
	sim.skip_to(119.0)
	var parked := {}
	for i in 60 * 40:
		sim.step(1.0 / 60.0)
		for e in sim.entities:
			if e.type == "truck" and e.state != "drive" and parked.is_empty(): parked = {"x": e.x, "half": e.size.x * e.scale * 0.5}
		if not parked.is_empty(): break
	check(not parked.is_empty(), "the stage truck drives in and stops")
	if not parked.is_empty():
		check(parked.x - parked.half > 2810.0 or parked.x + parked.half < 2550.0, "stage truck stops clear of the painted truck (x %.0f)" % parked.x)
	print("Weapons: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
