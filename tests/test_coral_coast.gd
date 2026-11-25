extends SceneTree
## Coral Coast (stage 3): data, new enemies, arena boss, quota and campaign hooks.
const StageData := preload("res://scripts/stage_data.gd")
const StageSim := preload("res://scripts/stage_sim.gd")
const Ground := preload("res://scripts/stage_ground.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var s := StageData.load_stage(3)
	check(not s.is_empty(), "Coral Coast loads")
	check(StageData.validate(s).is_empty(), "Coral Coast validates: " + str(StageData.validate(s)))
	check(float(s.duration) == 180.0, "Coral Coast is 3 minutes")
	check(str(s.music) == "music_coral_coast", "Coral Coast uses Caribbean Steel Drums 2")
	check(str(s.ambience) == "ambience_coral", "Coral Coast uses the bay ambience")
	check(float(s.get("shimmer", 0.0)) == 0.0, "heat shimmer is off")
	check(s.has("arena") and str(s.arena.get("type", "")) == "gunboat", "arena block names the gunboat")
	check(float(s.arena.get("t", 0.0)) == 140.0, "arena starts at 2:20")
	check(ResourceLoader.exists(str(s.background)) or FileAccess.file_exists(str(s.background)), "Coral Coast background file exists")
	var tex: Texture2D = load(str(s.background))
	check(tex != null and tex.get_width() == 3840 and tex.get_height() == 1080, "Coral Coast background is 3840x1080")
	check(s.has("ground") and (s.ground.near.points as Array).size() >= 2, "Coral Coast has a near ground map")
	check(s.has("roads") and (s.roads.track.points as Array).size() >= 2, "Coral Coast has a coast track")
	check((s.roads.water.points as Array).size() >= 2, "Coral Coast has a water path")
	check((s.roads.pier.points as Array).size() >= 2, "Coral Coast has a pier path")
	var g1: Array = s.ground.near.points[0]
	check(float(g1[1]) <= 940.0, "near ground stays above the HUD lip")
	var types := {}
	var has_heli := false
	for w in s.waves:
		types[str(w.type)] = true
		if str(w.type) == "heli": has_heli = true
	check(not has_heli, "Coral Coast has no helicopter")
	for typ in ["rifleman", "speedboat", "jeep", "pier_gunner", "gunboat", "food", "villager", "rusher", "grenadier"]:
		var in_waves := types.has(typ)
		var in_amb := false
		for r in s.ambient:
			if str(r.type) == typ: in_amb = true
		check(in_waves or in_amb, "Coral Coast uses " + typ)
	check(FileAccess.file_exists("res://assets/audio/music_coral_coast.ogg"), "Steel Drums 2 is shipped")
	check(FileAccess.file_exists("res://assets/audio/ambience_coral.ogg"), "coral ambience is shipped")
	check(FileAccess.file_exists("res://assets/audio/speedboat_loop.ogg"), "speedboat loop is shipped")
	check(FileAccess.file_exists("res://assets/audio/jeep_idle.ogg"), "jeep idle is shipped")
	check(FileAccess.file_exists("res://assets/audio/gunboat_engine.ogg"), "gunboat engine is shipped")

	var sim := StageSim.new()
	check(sim.setup(3, 7), "sim starts Coral Coast")
	check(sim.quota == 128, "computed quota is 128 (116 x 1.10, rounded)")
	check(sim.stage_number == 3, "stage number is 3")
	check(sim.has_arena(), "sim sees the arena")
	check(sim.diff.fire_rate > StageData.difficulty(3).fire_rate, "Coral Coast fire rate is boosted on top of the campaign curve")
	check(is_equal_approx(float(sim.diff.fire_rate) / float(StageData.difficulty(3).fire_rate), 1.15), "fire rate boost is +15%")

	var boat: Dictionary = sim.spawn("speedboat", "mid")
	check(not boat.is_empty(), "speedboat spawns")
	check(boat.max_hp == 9.0, "speedboat HP is 8 x 1.10, rounded to 9")
	check(int(StageSim.BASE_SCORE.speedboat) % 10 == 0, "speedboat score is a multiple of 10")
	check(Ground.road_for("speedboat", "mid") == "water", "speedboats use the water path")
	var b2: Dictionary = sim.spawn("speedboat", "mid")
	check(not b2.is_empty() and sim.count_alive("speedboat") == 2, "two speedboats can be alive")

	var jeep: Dictionary = sim.spawn("jeep", "mid")
	check(not jeep.is_empty(), "jeep spawns")
	check(jeep.max_hp == 12.0, "jeep HP is 11 x 1.10, rounded to 12")
	check(jeep.get("gunner_alive", false), "jeep has a bed gunner")
	check(Ground.road_for("jeep", "mid") == "track", "jeeps use the coast track")
	check(int(StageSim.BASE_SCORE.jeep) % 10 == 0, "jeep score is a multiple of 10")

	var pier: Dictionary = sim.spawn("pier_gunner", "mid", {"world_x": 2280.0, "world_y": 800.0, "scale": 0.50})
	check(not pier.is_empty() and pier.max_hp == 3.0, "pier gunner has 3 HP after difficulty")
	check(pier.get("planted", false), "pier gunner is planted on the planks")
	check(int(StageSim.BASE_SCORE.pier_gunner) % 10 == 0, "pier gunner score is a multiple of 10")

	var civ: Dictionary = sim.spawn("villager", "mid")
	check(not civ.is_empty(), "town civilian spawns")
	check(str(civ.kind).begins_with("town_"), "civilian uses a town kind")
	var food: Dictionary = sim.spawn("food", "sky", {"kind": "mango"})
	check(not food.is_empty() and food.kind == "mango", "mango pickup spawns")

	var rush: Dictionary = sim.spawn("rusher", "mid")
	check(not rush.is_empty(), "machete rusher spawns")
	check(rush.max_hp == 2.0, "rusher HP is 2")
	check(int(StageSim.BASE_SCORE.rusher) % 10 == 0, "rusher score is a multiple of 10")
	check("rusher" in StageSim.WADING_TYPES, "rushers may wade")
	check("rusher" in StageSim.FACING_TYPES, "rushers face the player")
	check(FileAccess.file_exists("res://assets/sprites/units/coast_rusher_charge.png"), "rusher charge art ships")
	check(FileAccess.file_exists("res://assets/sprites/units/coast_rusher_hit.png"), "rusher hit art ships")

	var gre: Dictionary = sim.spawn("grenadier", "mid", {"world_x": 1700.0, "world_y": 710.0, "scale": 0.5})
	check(not gre.is_empty(), "pier grenadier spawns")
	check(gre.max_hp == 2.0, "grenadier HP is 2")
	check(gre.get("planted", false) or str(gre.get("path", "")) == "pier", "grenadier is planted on the pier")
	check("grenadier" in Ground.DRY_TYPES, "grenadiers stay dry on the planks")
	check("grenadier" in StageSim.FACING_TYPES, "grenadiers face the player")
	check(FileAccess.file_exists("res://assets/sprites/units/coast_grenadier_aim.png"), "grenadier aim art ships")
	check(FileAccess.file_exists("res://assets/sprites/units/coast_grenadier_throw.png"), "grenadier throw art ships")
	check(FileAccess.file_exists("res://assets/sprites/units/coast_grenade.png"), "enemy grenade art ships")
	# Lob a grenade and shoot it down.
	sim.enemy_nades.clear()
	sim._throw_enemy_nade(gre)
	check(sim.enemy_nades.size() == 1, "grenadier lobs a grenade")
	var g0: Dictionary = sim.enemy_nades[0]
	var midpos: Vector2 = sim.nade_screen_pos(g0)
	var hp0 := sim.health
	check(sim.shoot_point(midpos), "the player can shoot the grenade in the air")
	check(str(g0.get("state", "")) == "shot", "the grenade is shot down")
	sim._update_enemy_nades(0.05)
	check(sim.health == hp0, "a shot-down grenade does not damage the player")
	# A landed grenade hurts the player, not a civilian.
	sim._throw_enemy_nade(gre)
	var landed: Dictionary = sim.enemy_nades[0]
	landed.t = landed.dur
	var civ2: Dictionary = sim.spawn("villager", "mid")
	sim._update_enemy_nades(0.05)
	check(sim.health < hp0, "a landed grenade damages the player")
	check(civ2.is_empty() or civ2.state != "dying", "a landed grenade does not harm civilians")
	# Rusher melee if allowed to close.
	var melee_hits := []
	sim.event.connect(func(n, _d): if n == "rusher_melee": melee_hits.append(1))
	var r2: Dictionary = sim.spawn("rusher", "near", {"world_x": 960.0, "world_y": 900.0})
	if not r2.is_empty():
		r2.band = "near"
		r2.target_x = r2.x
		r2.target_y = r2.y
		r2.age = 4.0
		for i in 90:
			if r2.get("melee", false):
				break
			sim.step(0.05)
		check(r2.get("melee", false) or melee_hits.size() > 0, "a close rusher lands a melee hit if not shot")

	# Quota and time must not clear the stage before the gunboat is down.
	sim.kills = sim.quota
	sim.step(0.05)
	check(sim.state == "playing", "meeting the quota does not clear the harbour arena")
	sim.time = 180.0
	sim.step(0.05)
	check(sim.state == "playing", "reaching 3:00 does not clear the harbour arena")
	sim.kills = 0
	sim.time = 0.0
	sim.camera_x = 0.0

	# Boss: skip to the harbour hold, spawn, wreck, clear.
	var boss_sim := StageSim.new()
	check(boss_sim.setup(3, 11), "second sim starts Coral Coast")
	boss_sim.skip_to(140.0)
	for i in 80:
		boss_sim.step(0.05)
	var gun := {}
	for e in boss_sim.entities:
		if e.type == "gunboat":
			gun = e
			break
	check(not gun.is_empty(), "gunboat spawns at the harbour hold")
	if not gun.is_empty():
		check(gun.max_hp == 33.0, "gunboat HP is 30 x 1.10, rounded to 33")
		check(gun.get("gunner_alive", false), "gunboat has a bow gunner")
		check(gun.get("gunner2_alive", false), "gunboat has a second deck gunner")
		check(str(gun.get("band", "")) == "mid", "gunboat stays on the mid water path, not the far shore")
		check(str(gun.get("path", "")) == "water", "gunboat path is the close harbour water")
		check(gun.y >= 740.0, "gunboat sits in the deep basin (y=%.1f)" % gun.y)
		check(gun.scale >= 0.9, "gunboat is the larger close scale")
		check(int(StageSim.BASE_SCORE.gunboat) % 10 == 0, "gunboat score is a multiple of 10")
		# Time running past the planned 180 s still does not clear while it lives.
		boss_sim.time = 180.0
		boss_sim.step(0.1)
		check(boss_sim.state == "playing", "time past 3:00 does not clear while the gunboat lives")
		# Wreck the hull with a blast so the bow gunner does not soak the shot.
		var pos := Vector2(gun.x - boss_sim.camera_x, gun.y - 40.0)
		boss_sim.damage_entity(gun, 999.0, pos, true)
		check(boss_sim.arena_sink > 0.0, "destroying the gunboat starts the wreck delay")
		check(boss_sim.state == "playing", "the stage holds during the wreck")
		for i in 40:
			boss_sim.step(0.05)
		check(boss_sim.state == "cleared", "stage clears after the gunboat wrecks")
		check(boss_sim.end_reason == "boss", "clear reason is the boss")
	check(StageData.next_playable(2) == 3, "campaign offers Coral Coast after Dune Sea")
	print("Coral Coast: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
