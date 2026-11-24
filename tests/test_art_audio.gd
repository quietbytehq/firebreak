extends SceneTree
## 0.2.0 art and audio wiring: adult-only villagers (children never spawned or
## loaded), painted sprites with mipmaps, audio files by base name, and the
## title music intro -> loop sequence.
const StageSim := preload("res://scripts/stage_sim.gd")
const SpriteArt := preload("res://scripts/sprite_art.gd")
const SpriteMeta := preload("res://scripts/sprite_meta.gd")
const AudioBank := preload("res://scripts/audio.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	# Children are never spawned.
	var sim = StageSim.new(); sim.setup(1, 99); sim.stage.waves = []
	var kinds := {}
	var bad := 0
	for i in 300:
		sim.camera_x = float((i * 37) % 1900)
		var v: Dictionary = sim.spawn("villager", ["far", "mid"][i % 2])
		if v.is_empty(): continue
		kinds[v.kind] = true
		if not (v.kind in ["farmer", "woman", "elder"]) or str(v.kind).contains("child"): bad += 1
		sim.entities.erase(v)
	check(bad == 0, "every spawned villager is an adult")
	check(kinds.size() == 3, "all three adult villager types appear (%s)" % str(kinds.keys()))
	# Whole-stage run: no child anywhere.
	sim = StageSim.new(); sim.setup(1, 5); sim.diff.accuracy = 0.0   # nobody shoots back, so the stage runs its full length
	var seen := {"child": 0, "villagers": 0}
	sim.event.connect(func(n, d):
		if n == "spawn" and d.entity.type == "villager":
			seen.villagers += 1
			if str(d.entity.kind).contains("child"): seen.child += 1)
	for i in 180 * 20: sim.step(0.05)
	check(seen.villagers > 5 and seen.child == 0, "a full stage spawns %d villagers, none of them children" % seen.villagers)
	# Child art is neither shipped nor loadable.
	var dir := DirAccess.open("res://assets/sprites/units")
	var files := dir.get_files() if dir else PackedStringArray()
	var child_files := 0
	for f in files: if f.contains("child"): child_files += 1
	check(files.size() > 40 and child_files == 0, "no child sprite files in the game's assets")
	var meta_child := 0
	for k in SpriteMeta.UNITS.keys(): if str(k).contains("child"): meta_child += 1
	check(meta_child == 0, "sprite table has no child entries")
	check(SpriteArt.tex("villager_child_run_01") == null, "child sprites can't be loaded")
	var n := SpriteArt.preload_all()
	check(n == SpriteMeta.UNITS.size() + SpriteMeta.VEHICLES.size(), "all %d sprites load" % n)
	var any_child := false
	for k in SpriteArt.loaded_names(): if str(k).contains("child"): any_child = true
	check(not any_child, "no child sprite in the loaded set")
	# Painted sprites: textures, mipmaps, anchors.
	for name in ["rifleman_aim", "mg_nest", "paratrooper_descend", "villager_farmer_walk_01", "heli_gunner", "jet_a", "bomb", "explosion_big", "fx_muzzle_rifle_01"]:
		var t := SpriteArt.tex(name)
		check(t != null, "sprite loads: " + name)
		if t: check(t.get_image() != null and t.get_image().has_mipmaps(), "sprite imported with mipmaps: " + name)
		var m := SpriteArt.meta(name)
		if t and not m.is_empty(): check(t.get_width() == int(m[0]) and t.get_height() == int(m[1]), "sprite size matches its metadata: " + name)
	check(SpriteArt.fig_h("rifleman_aim") > 200.0, "figure height measured from the art")
	# Audio files by base name.
	var bank = AudioBank.new()
	root.add_child(bank)
	await process_frame
	for base in ["music_title_intro", "music_title_intro_loop", "title_call", "music_bg_01", "music_bg_02", "music_bg_03", "music_dune_sea", "ambience_dune", "truck_dune", "camel", "wind_gust", "bricks", "music_coral_coast", "ambience_coral", "speedboat_loop", "jeep_idle", "gunboat_engine", "pier_creak",
			"fire", "fire_rapid", "fire_spread", "enemy_rifle", "enemy_rifle_near", "enemy_rifle_far", "enemy_mg",
			"airstrike_jet", "airstrike_whistle", "airstrike_explosion", "helicopter_rotor", "helicopter_mg",
			"helicopter_crash", "heartbeat", "ambience_river", "villager_gasp", "ui_pause",
			"rayan_lock_and_load", "rayan_fire_in_the_hole", "rayan_airstrike_now", "rayan_care_package",
			"rayan_watch_the_civilians", "rayan_mission_complete", "rayan_hit_grunt_01", "rayan_that_all_you_got",
			"rayan_keep_your_head_down", "rayan_nests_down", "rayan_chopper_inbound",
			"rayan_still_standing", "rayan_clean_shot", "rayan_theyre_breaking", "rayan_not_today",
			"rayan_this_is_the_firebreak", "rayan_one_more_push", "rayan_almost_over",
			"rayan_ill_wear_it"]:
		check(bank.has_sound(base), "audio present: " + base)
	check(not bank.has_sound("definitely_missing"), "missing sounds stay silent")
	for path in ["res://assets/ui/briefing_bg.jpg", "res://assets/ui/travel_map.jpg", "res://assets/fonts/BarlowCondensed-Bold.ttf"]:
		check(ResourceLoader.exists(path), "story asset present: " + path)
	bank.play_music("music_title_intro_loop", "music_title_intro")
	check(bank.music_player.stream == bank.find_stream("music_title_intro") and bank.music_next == "music_title_intro_loop", "title intro plays first, loop queued")
	var vol0: float = bank.music_player.volume_db
	bank.duck_music(-7.0, 3.8)
	check(bank.music_player.volume_db < vol0 - 4.0, "title call ducks the music")
	bank.duck_left = 0.0
	bank._apply_music_vol()
	check(absf(bank.music_player.volume_db - vol0) < 0.05, "music volume returns after the duck")
	check(not bool(bank.find_stream("music_title_intro").get("loop")), "title intro plays once (no loop)")
	bank._on_music_finished()
	check(bank.music_player.stream == bank.find_stream("music_title_intro_loop") and bool(bank.music_player.stream.get("loop")), "after the intro the title loop repeats")
	bank.set_music_on(false)
	check(not bank.music_player.playing, "music off stops the music")
	bank.set_music_on(true)
	bank.play_music("music_bg_02")
	check(bank.music_player.stream == bank.find_stream("music_bg_02"), "background track switch")
	# Voice rate limiting.
	check(bank.voice("rayan_fire_in_the_hole", 6.0), "voice line plays")
	check(not bank.voice("rayan_care_package", 6.0), "a second line right after is suppressed")
	check(not bank.voice("rayan_fire_in_the_hole", 6.0, true), "a line can't repeat inside its cooldown")
	check(bank.voice("rayan_airstrike_now", 1.0, true), "key moments (air strike call) always speak")
	bank.loop_on("heartbeat")
	check(bank.is_looping("heartbeat"), "heartbeat loops")
	bank.stop_loops()
	check(not bank.is_looping("heartbeat"), "loops stop")
	bank.queue_free()
	await process_frame
	print("Art and audio: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
