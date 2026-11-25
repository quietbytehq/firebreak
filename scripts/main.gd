extends Node
## Firebreak entry point: menus, stage lifecycle, input, audio cues and the
## optional QA autopilot (only active with --qa-run after "--" on the command line).

const StageSim := preload("res://scripts/stage_sim.gd")
const StageData := preload("res://scripts/stage_data.gd")
const Ground := preload("res://scripts/stage_ground.gd")
const StageView := preload("res://scripts/stage_view.gd")
const Hud := preload("res://scripts/hud.gd")
const InputSetup := preload("res://scripts/input_setup.gd")
const Scores := preload("res://scripts/scores.gd")
const AudioBank := preload("res://scripts/audio.gd")
const SpriteArt := preload("res://scripts/sprite_art.gd")
const TitleScreen := preload("res://scripts/title_screen.gd")
const ResultPortrait := preload("res://scripts/result_portrait.gd")
const ScreenFx := preload("res://shaders/screen_fx.gdshader")
const Weapons := preload("res://scripts/weapons.gd")
const Online := preload("res://scripts/online.gd")
const FpView := preload("res://scripts/fp_view.gd")
const BriefingScreen := preload("res://scripts/briefing_screen.gd")
const TravelMapScreen := preload("res://scripts/travel_map_screen.gd")
const UiStyle := preload("res://scripts/ui_style.gd")
const TARGET_FPS := 60
const MUSIC_TRACKS := ["music_bg_01", "music_bg_02", "music_bg_03"]
var music_override := ""
const TITLE_INTRO := "music_title_intro"
const TITLE_LOOP := "music_title_intro_loop"
const GRUNTS := ["rayan_hit_grunt_01", "rayan_hit_grunt_02", "rayan_hit_grunt_03"]

var mode := "title"   # title | briefing | travel_map | playing | paused | result | scores | controls | store
var profile: Dictionary
var bar_press := false      # a mouse press that began on the weapon bar never fires
var store_cat := "pistol"
var store_sel := "viper_9"
var store_note := ""
var store_back := "title"
var sim
var view: Node2D
var hud: Node2D
var fp: Node2D         # first-person weapon view (under the HUD layer)
var fx_rect: ColorRect
var ui_layer: CanvasLayer
var menu_root: Control
var title_bg: TextureRect
var title_screen: Node2D
var briefing: Node2D
var travel_map: Node2D
var briefing_kind := "play"    # play | story
var map_kind := "preview"      # preview | after_clear
var title_menu_open := false
var bust_tex: Texture2D
var pending_sounds: Array = []   # [seconds_left, callable]
## Title announcer plays once per launch.
var title_call_played := false
var audio
var settings: Dictionary
var bg_tex: Texture2D
var crosshair := Vector2(960, 540)
var end_delay := 0.0
var fire_grace := 0.0
var rebinding := ""
var return_mode := "title"
var stage_number := 1
var run_score := 0          # campaign total for the current run (all finished stages)
var run_score_saved := false
var run_stages := 1         # last stage reached in this run
var run_live := false       # a run is in progress
var run_banked := false     # current stage score has been added to run_score
const RUN_CONTINUES := 3
var run_continues := 3      # diamonds left this run; spent on a failed-stage retry
var online_hint: Label
var name_prompt_kind := ""
var player_name_edit: LineEdit
var theme: Theme
var title_t := 0.0
var last_mouse := Vector2(-1, -1)

# QA autopilot
var qa := {}
var qa_frames: Array = []
var qa_raw: Array = []      # wall-clock frame times (not delta-smoothed)
var qa_last_us := 0
var qa_clock := 0.0
var qa_shots_done := {}
var qa_finished := false
var qa_skip_frames := 0
var qa_fire_capture: Array = []   # [path] captured on the next frame
var qa_ground_hits: Array = []
var qa_ground_frames := 0
var kill_streak_times: Array = []  # sim.time of recent kills, for catchphrases
var was_critical := false          # health dropped below 20% this stage
var said_one_more := false

func _ready() -> void:
	# Steady 60 fps even on 120/144 Hz panels (vsync stays on in project settings).
	Engine.max_fps = TARGET_FPS
	_choose_vsync()
	InputSetup.ensure()
	settings = Scores.load_settings()
	_parse_qa_args()
	if qa.has("demo_scores"):
		_seed_demo_scores()
	profile = Weapons.load_profile()
	if qa.has("cash"): profile.cash = int(qa.cash)
	if qa.has("loadout"):
		for id in qa.loadout:
			if not Weapons.get_weapon(id).is_empty():
				if not profile.owned.has(id): profile.owned.append(id); profile.ammo[id] = Weapons.fresh_ammo(id)
				Weapons.equip(profile, id)
	bg_tex = load("res://assets/backgrounds/river_village.jpg")
	audio = AudioBank.new(); add_child(audio)
	audio.set_volumes(float(settings.sfx_volume), float(settings.music_volume))
	audio.music_on = bool(settings.music_on)
	SpriteArt.preload_all()
	bust_tex = load("res://assets/ui/rayan_bust.png")
	view = StageView.new(); add_child(view)
	var fx_layer := CanvasLayer.new(); fx_layer.layer = 1; add_child(fx_layer)
	fp = FpView.new(); fp.visible = false; fx_layer.add_child(fp)
	fx_rect = ColorRect.new(); fx_rect.size = Vector2(1920, 1080); fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new(); mat.shader = ScreenFx; fx_rect.material = mat
	fx_layer.add_child(fx_rect)
	var hud_layer := CanvasLayer.new(); hud_layer.layer = 3; add_child(hud_layer)
	hud = Hud.new(); hud_layer.add_child(hud); hud.visible = false
	ui_layer = CanvasLayer.new(); ui_layer.layer = 4; add_child(ui_layer)
	title_bg = TextureRect.new(); title_bg.texture = bg_tex; title_bg.stretch_mode = TextureRect.STRETCH_KEEP
	title_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; title_bg.visible = false
	var bg_layer := CanvasLayer.new(); bg_layer.layer = -1; add_child(bg_layer); bg_layer.add_child(title_bg)
	title_screen = TitleScreen.new(); bg_layer.add_child(title_screen)
	briefing = BriefingScreen.new(); briefing.visible = false; bg_layer.add_child(briefing)
	briefing.finished.connect(_on_briefing_finished)
	briefing.voice_cb = func(): audio.voice("rayan_lock_and_load", 8.0, true)
	travel_map = TravelMapScreen.new(); travel_map.visible = false; bg_layer.add_child(travel_map)
	travel_map.finished.connect(_on_travel_map_finished)
	_build_theme()
	if not qa.is_empty() and not DisplayServer.get_name() == "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif bool(settings.fullscreen) and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if qa.has("store"):
		show_store("title")
	elif qa.has("briefing"):
		show_title()
		show_briefing("story")
	elif qa.has("map"):
		show_travel_map("after_clear", int(qa.get("stage", 1)))
	elif qa.has("run") and not qa.has("title"):
		begin_run()
		start_stage(int(qa.get("stage", 1)))
	else:
		show_title()

# ------------------------------------------------------------------ stage
func begin_run() -> void:
	run_score = 0
	run_stages = 1
	run_live = true
	run_banked = false
	run_score_saved = false
	run_continues = RUN_CONTINUES

## Keeps the campaign total and starts another stage (used when later stages ship, and in tests).
func continue_run_to(number: int) -> void:
	run_banked = false
	run_live = true
	start_stage(number)

func bank_run_score() -> void:
	if run_banked or sim == null: return
	run_score += sim.score
	run_stages = stage_number
	run_banked = true
	run_live = false

func displayed_score() -> int:
	if sim == null: return run_score
	return run_score if run_banked else run_score + sim.score

func start_stage(number: int) -> void:
	stage_number = number
	sim = StageSim.new()
	var seed := int(qa.get("seed", Time.get_ticks_usec() % 1000000))
	if not sim.setup(number, seed, {}, profile):
		push_error("Stage %d could not be loaded" % number); show_title(); return
	if qa.has("skip"):
		sim.skip_to(float(qa.skip))
	sim.event.connect(_on_sim_event)
	audio.clear_pause()
	fp.bind(sim)
	view.bind(sim, load(str(sim.stage.get("background", "res://assets/backgrounds/river_village.jpg"))))
	view.fp = fp
	view.visible = true; title_screen.visible = false
	hud.sim = sim; hud.stage_name = str(sim.stage.get("name", "")); hud.run_base = run_score if not run_banked else 0; hud.visible = true
	hud.continues = run_continues; hud.continues_max = RUN_CONTINUES
	title_bg.visible = false
	_clear_menu()
	mode = "playing"; end_delay = 0.0; fire_grace = 0.25; bar_press = false
	crosshair = Vector2(960, 540); last_mouse = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	audio.stop_loops()
	music_override = str(sim.stage.get("music", "")) if sim != null else ""
	play_game_music()
	audio.play("stage_start")
	audio.play_ambience(str(sim.stage.get("ambience", "ambience_river")))
	pending_sounds.clear()
	kill_streak_times.clear()
	was_critical = false
	said_one_more = false
	_later(0.9, _opening_line)

func play_game_music() -> void:
	if music_override != "" and audio.has_sound(music_override):
		audio.play_music(music_override)
		return
	var track := clampi(int(settings.get("music_track", 1)), 1, MUSIC_TRACKS.size())
	audio.play_music(MUSIC_TRACKS[track - 1])

func _later(seconds: float, cb: Callable) -> void:
	pending_sounds.append([seconds, cb])

func stages_cleared() -> int:
	return int(profile.get("stages_cleared", 0))

## Speak a catchphrase if the player has unlocked that tier.
func _say(base: String, need: int, cooldown: float, force: bool = false) -> bool:
	if stages_cleared() < need:
		return false
	return audio.voice(base, cooldown, force)

func _opening_line() -> void:
	# Stage 12 prefers the closer-to-the-end line; stages 8–11 use the firebreak call.
	if stage_number >= 12 and stages_cleared() >= 7:
		audio.voice("rayan_almost_over", 30.0, true)
	elif stage_number >= 8 and stages_cleared() >= 7:
		audio.voice("rayan_this_is_the_firebreak", 30.0, true)
	else:
		audio.voice("rayan_lock_and_load", 30.0, true)

## Gunshots get quieter with depth: near 0 dB, mid about -6 dB, far about -12 dB.
static func depth_db(scale: float) -> float:
	return lerpf(-12.0, 0.0, clampf((scale - 0.26) / (0.95 - 0.26), 0.0, 1.0))

func _on_sim_event(name: String, d: Dictionary) -> void:
	fp.on_event(name, d)
	match name:
		"shot":
			var w := Weapons.get_weapon(str(d.get("weapon", "")))
			var snd := str(w.get("sound", "fire"))
			var vol := -4.0 if float(w.get("fire_rate", 4.0)) < 9.0 else -6.0
			if sim.spread_timer > 0.0: vol -= 1.0
			audio.play_first([snd, "fire"], vol, randf_range(0.96, 1.04))
		"miss": audio.play("ricochet", -10.0, randf_range(0.9, 1.1))
		"hit":
			if d.entity.type in ["mg", "truck", "heli"] and not d.get("gunner", false): audio.play("hit_metal", -4.0)
		"kill":
			if d.entity.type != "heli": audio.play("enemy_down", -2.0, randf_range(0.92, 1.08))
			if d.entity.type == "sniper":
				audio.play("bricks", -6.0)
			if d.entity.type == "mg":
				_say("rayan_nests_down", 0, 15.0)
			var now_t: float = float(sim.time)
			kill_streak_times.append(now_t)
			kill_streak_times = kill_streak_times.filter(func(t): return now_t - float(t) <= 1.8)
			if kill_streak_times.size() >= 5:
				_say("rayan_theyre_breaking", 3, 20.0)
		"enemy_fire":
			var e: Dictionary = d.entity
			var db := depth_db(float(e.scale))
			if e.type == "heli":
				if sim.time - float(e.get("snd_t", -9.0)) > 1.3:
					e.snd_t = sim.time; audio.play_first(["helicopter_mg", "enemy_mg"], -5.0)
			elif e.type in ["mg", "truck"]:
				if sim.time - float(e.get("snd_t", -9.0)) > 1.25:
					e.snd_t = sim.time; audio.play("enemy_mg", db - 3.0, randf_range(0.95, 1.05))
			else:
				var base := "enemy_rifle"
				if e.band == "near": base = "enemy_rifle_near"
				elif e.band == "far": base = "enemy_rifle_far"
				audio.play_first([base, "enemy_rifle"], db - 4.0, randf_range(0.95, 1.05))
		"player_hit":
			audio.play("player_hit", -3.0)
			hud.hit_flash = 1.0
			if sim.health < sim.max_health * 0.2:
				was_critical = true
			if sim.health < sim.max_health * 0.3:
				_say("rayan_keep_your_head_down", 0, 18.0)
			elif float(d.get("amount", 0.0)) >= 10.0:
				_say("rayan_still_standing", 3, 20.0)
			if d.get("source") is Dictionary and d.source.get("type", "") == "villager": pass
			elif randf() < 0.45: audio.voice(GRUNTS[randi() % GRUNTS.size()], 3.0)
		"villager_hit":
			audio.play("villager_penalty")
			audio.play("villager_gasp", -4.0)
			audio.voice("rayan_watch_the_civilians", 10.0, true)
		"pickup":
			if str(d.get("kind", "")).begins_with("cash"): pass   # the "cash" event plays the coin sound
			else:
				audio.play("pickup_food" if d.entity.type == "food" else "pickup_power")
				if was_critical:
					_say("rayan_not_today", 3, 20.0)
					was_critical = false
				else:
					audio.voice("rayan_care_package", 25.0)
		"reload_start":
			var w := Weapons.get_weapon(str(d.get("weapon", "")))
			audio.play_first([str(w.get("reload_sound", "reload")), "reload"])
		"empty":
			var w := Weapons.get_weapon(str(d.get("weapon", "")))
			audio.play_first([str(w.get("dry_sound", "empty_click")), "empty_click"])
		"grenade_throw":
			if str(d.get("kind", "thrown")) == "thrown":
				audio.play("grenade_throw")
				audio.voice("rayan_fire_in_the_hole", 6.0)
			else:
				var w := Weapons.get_weapon(str(d.get("weapon", "")))
				audio.play_first([str(w.get("sound", "grenade_throw")), "grenade_throw"], -2.0)
		"weapon_switch": audio.play("weapon_switch", -6.0)
		"cash":
			if str(d.get("reason", "")) == "drop": audio.play_first(["cash_pickup", "pickup_power"], -2.0)
			else: audio.play("cash_pickup", -16.0, randf_range(1.05, 1.15))
			hud.pop_cash(int(d.amount), d.pos, true)
		"cash_lost":
			if int(d.amount) > 0: hud.pop_cash(int(d.amount), d.pos, false)
		"explosion":
			audio.play("explosion", -2.0 if float(d.radius) > 300.0 else -5.0, randf_range(0.94, 1.04))
		"airstrike":
			audio.voice("rayan_airstrike_now", 1.0, true)
			audio.play("airstrike_jet", 0.0)
			_later(0.45, func(): audio.play("airstrike_whistle", -3.0))
		"airstrike_impact":
			audio.play_first(["airstrike_explosion", "explosion"], 0.0)
			audio.play("explosion", -6.0, 0.85)
		"headshot":
			_say("rayan_clean_shot", 3, 12.0)
		"gunner_down": audio.voice("rayan_that_all_you_got", 20.0)
		"heli_down":
			audio.play_first(["helicopter_crash", "explosion"], 0.0)
			audio.voice("rayan_that_all_you_got", 20.0)
		"gunboat_down":
			audio.play_first(["explosion", "airstrike_explosion"], -2.0)
			audio.voice("rayan_that_all_you_got", 20.0)
		"spawn":
			if d.entity.type == "paratrooper": audio.play("parachute_open", -8.0)
			elif d.entity.type in ["truck", "technical", "convoy"]:
				audio.play_first(["truck_dune", "truck_engine"], -6.0)
			elif d.entity.type == "jeep":
				audio.play("jeep_idle", -6.0)
			elif d.entity.type == "speedboat":
				audio.play("speedboat_loop", -8.0)
			elif d.entity.type == "gunboat":
				audio.play("gunboat_engine", -6.0)
			elif d.entity.type == "pier_gunner":
				audio.play("pier_creak", -12.0)
			elif d.entity.type == "camel":
				audio.play("camel", -8.0)
			elif d.entity.type == "heli":
				_say("rayan_chopper_inbound", 0, 20.0, true)
		"cleared":
			audio.stop_music(); audio.stop_ambience(); audio.stop_loops(); audio.play("stage_clear")
			if was_critical:
				_later(0.5, func(): _say("rayan_not_today", 3, 20.0, true))
			_later(1.2, func(): audio.voice("rayan_mission_complete", 30.0, true))
		"failed": audio.stop_music(); audio.stop_ambience(); audio.stop_loops(); audio.play("game_over")

## Looping sounds that follow the game state: helicopter rotor and low-health heartbeat.
func _update_loops() -> void:
	var heli_near := false
	var truck_near := false
	var jeep_near := false
	var boat_near := false
	var gunboat_near := false
	for e in sim.entities:
		if e.type == "heli" and e.state != "crash" and e.get("sx", -999.0) > -300.0 and e.get("sx", 9999.0) < 2220.0:
			heli_near = true
		var sx: float = e.x - sim.camera_x
		if e.type in ["technical", "convoy", "truck"] and e.state != "dying":
			if sx > -200.0 and sx < 2120.0:
				truck_near = true
		if e.type == "jeep" and e.state != "dying" and sx > -200.0 and sx < 2120.0:
			jeep_near = true
		if e.type == "speedboat" and e.state != "dying" and sx > -200.0 and sx < 2120.0:
			boat_near = true
		if e.type == "gunboat" and e.state != "dying" and sx > -200.0 and sx < 2120.0:
			gunboat_near = true
	if heli_near: audio.loop_on("helicopter_rotor", -6.0)
	else: audio.loop_off("helicopter_rotor")
	if truck_near: audio.loop_on("truck_dune", -10.0)
	else: audio.loop_off("truck_dune")
	if jeep_near: audio.loop_on("jeep_idle", -10.0)
	else: audio.loop_off("jeep_idle")
	if boat_near: audio.loop_on("speedboat_loop", -8.0)
	else: audio.loop_off("speedboat_loop")
	if gunboat_near: audio.loop_on("gunboat_engine", -8.0)
	else: audio.loop_off("gunboat_engine")
	if sim.has_method("dust_amount") and sim.dust_amount() > 0.15:
		audio.loop_on("wind_gust", -8.0)
	else:
		audio.loop_off("wind_gust")
	if sim.state == "playing" and sim.health > 0.0 and sim.health < sim.max_health * 0.3:
		audio.loop_on("heartbeat", -2.0)
	else:
		audio.loop_off("heartbeat")
	# Late-campaign nudge once the quota is almost met or time is short.
	if (not said_one_more and sim.state == "playing" and stage_number >= 8
			and stages_cleared() >= 7
			and (sim.time_left() <= 30.0 or sim.kills >= int(sim.quota * 0.85))):
		said_one_more = true
		_say("rayan_one_more_push", 7, 30.0)

func _process(delta: float) -> void:
	title_t += delta
	if title_bg.visible:
		title_bg.position.x = -960.0 - sin(title_t * 0.05) * 900.0
	if not audio.paused:   # delayed sounds wait while the game is paused
		for p in pending_sounds.duplicate():
			p[0] -= delta
			if p[0] <= 0.0:
				pending_sounds.erase(p); p[1].call()
	fp.visible = mode in ["playing", "paused"] and sim != null and not qa.has("no_fp")
	if fx_rect.material:
		var in_game := mode in ["playing", "paused"] and sim != null
		fx_rect.material.set_shader_parameter("hurt", view.hurt if in_game else 0.0)
		fx_rect.material.set_shader_parameter("blood", view.blood if in_game else 0.0)
		var low := clampf(1.0 - sim.health / (sim.max_health * 0.35), 0.0, 1.0) if in_game and sim.health > 0.0 else 0.0
		fx_rect.material.set_shader_parameter("low_health", low)
		fx_rect.material.set_shader_parameter("pulse", 0.5 + 0.5 * sin(title_t * 7.5))
	if qa.has("run") or qa.has("title") or qa.has("briefing") or qa.has("map") or qa.has("name_prompt"):
		_qa_tick(delta)
	elif qa.has("store"):
		qa_phase_t += delta; _qa_store_tick()
	if mode != "playing":
		return
	var dt := minf(delta, 0.05)
	fire_grace = maxf(0.0, fire_grace - dt)
	var mouse := get_viewport().get_mouse_position()
	if mouse.distance_to(last_mouse) > 0.5 and not qa.has("run"):
		crosshair = mouse
	last_mouse = mouse
	var dir := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if dir.length() > 0.0:
		var speed := 1250.0 * float(settings.get("aim_speed", 1.0)) * pow(dir.length(), 1.4)
		crosshair += dir.normalized() * speed * dt
	if qa.has("run"):
		_qa_autopilot(dt)
	crosshair = crosshair.clamp(Vector2(4, 4), Vector2(1916, 1076))
	hud.crosshair = crosshair
	hud.run_base = run_score if not run_banked else maxi(0, run_score - sim.score)
	fp.crosshair = crosshair
	if bar_press and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		bar_press = false
	if Input.is_action_pressed("fire") and fire_grace <= 0.0 and not bar_press and not qa.has("run") and Hud.slot_at(crosshair) < 0:
		sim.fire(crosshair)
	sim.step(dt)
	_update_loops()
	if qa.has("run"):
		var now_us := Time.get_ticks_usec()
		if qa_skip_frames > 0: qa_skip_frames -= 1   # PNG saving stalls the frame; not counted
		else:
			qa_frames.append(delta)
			if qa_last_us > 0: qa_raw.append((now_us - qa_last_us) / 1000000.0)
		qa_last_us = now_us
	if sim.state != "playing":
		end_delay += dt
		if end_delay > 1.8:
			show_result()

func _unhandled_input(event: InputEvent) -> void:
	if rebinding != "":
		return
	# Clicks on the weapon bar select that slot and never fire or throw.
	if mode == "playing" and event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		var hit := Hud.slot_at(event.position)
		if hit >= 0:
			bar_press = true
			sim.select_slot(hit)
			get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("fullscreen"):
		toggle_fullscreen(); get_viewport().set_input_as_handled(); return
	if mode == "briefing" and _is_press(event):
		briefing.advance(); get_viewport().set_input_as_handled(); return
	if mode == "travel_map" and _is_press(event):
		_on_travel_map_finished(); get_viewport().set_input_as_handled(); return
	if mode == "player_name":
		if event.is_action_pressed("ui_cancel") and name_prompt_kind in ["menu", "change"]:
			show_title(true); get_viewport().set_input_as_handled(); return
		# Enter is handled by the LineEdit; a gamepad face button confirms the prefilled name.
		if event is InputEventJoypadButton and event.pressed:
			confirm_player_name(player_name_edit.text if player_name_edit else "")
			get_viewport().set_input_as_handled(); return
		if event.is_action_pressed("ui_accept") and not (event is InputEventKey):
			confirm_player_name(player_name_edit.text if player_name_edit else "")
			get_viewport().set_input_as_handled(); return
	if mode == "title":
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if title_screen.name_hit(event.position):
				show_name_prompt("change"); get_viewport().set_input_as_handled(); return
			var tab: String = title_screen.tab_hit(event.position)
			if tab != "":
				title_screen.select_tab(tab); get_viewport().set_input_as_handled(); return
			if title_screen.global_hit(event.position):
				open_global_scores(); get_viewport().set_input_as_handled(); return
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F1:
			show_briefing("story"); get_viewport().set_input_as_handled(); return
		if not title_menu_open and _is_press(event):
			open_title_menu(); get_viewport().set_input_as_handled(); return
	if mode == "playing":
		if event.is_action_pressed("pause"):
			pause_game(); get_viewport().set_input_as_handled()
		elif event.is_action_pressed("reload"):
			sim.reload()
		elif event.is_action_pressed("grenade"):
			sim.throw_grenade(crosshair)
		elif event.is_action_pressed("airstrike"):
			sim.call_airstrike()
		elif event.is_action_pressed("weapon_1"): sim.select_slot(0)
		elif event.is_action_pressed("weapon_2"): sim.select_slot(1)
		elif event.is_action_pressed("weapon_3"): sim.select_slot(2)
		elif event.is_action_pressed("weapon_next"): sim.cycle_slot(1)
		elif event.is_action_pressed("weapon_prev"): sim.cycle_slot(-1)
		elif event.is_action_pressed("fire") and fire_grace <= 0.0 and not bar_press:
			sim.fire(crosshair)
	elif mode == "paused" and event.is_action_pressed("pause"):
		resume_game(); get_viewport().set_input_as_handled()
	elif mode in ["scores", "controls", "store"] and event.is_action_pressed("ui_cancel"):
		_back(); get_viewport().set_input_as_handled()

func _is_press(event: InputEvent) -> bool:
	if event is InputEventKey: return event.pressed and not event.echo
	if event is InputEventMouseButton: return event.pressed
	if event is InputEventJoypadButton: return event.pressed
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "playing" and not qa.has("run"):
		pause_game()

func toggle_fullscreen() -> void:
	var fs := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
	settings.fullscreen = not fs
	Scores.save_settings(settings)

func pause_game() -> void:
	if mode != "playing": return
	sim.paused = true; mode = "paused"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	audio.pause_all()   # freezes SFX, loops, voice and stage music; starts the pause track
	audio.play("ui_pause")
	show_pause()

func resume_game() -> void:
	if mode != "paused": return
	_clear_menu()
	sim.paused = false; mode = "playing"; fire_grace = 0.25
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	audio.resume_all()

# ------------------------------------------------------------------ UI
func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font = UiStyle.font("semibold")
	theme.default_font_size = 30
	var normal := StyleBoxFlat.new(); normal.bg_color = Color(0.1, 0.08, 0.06, 0.88)
	normal.border_color = Color(0.85, 0.55, 0.25, 0.6); normal.set_border_width_all(2); normal.set_corner_radius_all(6)
	normal.content_margin_left = 24; normal.content_margin_right = 24; normal.content_margin_top = 10; normal.content_margin_bottom = 10
	var hover := normal.duplicate(); hover.bg_color = Color(0.45, 0.24, 0.08, 0.95); hover.border_color = Color(1, 0.8, 0.45)
	var pressed := hover.duplicate(); pressed.bg_color = Color(0.6, 0.3, 0.1, 0.95)
	for s in ["normal", "disabled"]: theme.set_stylebox(s, "Button", normal)
	theme.set_stylebox("hover", "Button", hover); theme.set_stylebox("focus", "Button", hover); theme.set_stylebox("pressed", "Button", pressed)
	theme.set_color("font_color", "Button", Color(1, 0.93, 0.82))
	theme.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.45))
	theme.set_color("font_color", "Label", Color(1, 0.93, 0.82))
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0))
	theme.set_constant("outline_size", "Label", 8)
	var le := normal.duplicate(); theme.set_stylebox("normal", "LineEdit", le); theme.set_stylebox("focus", "LineEdit", hover)
	var track := StyleBoxFlat.new(); track.bg_color = Color(0.1, 0.08, 0.06, 0.9); track.set_corner_radius_all(6)
	track.border_color = Color(0.85, 0.55, 0.25, 0.6); track.set_border_width_all(2)
	track.content_margin_top = 8; track.content_margin_bottom = 8
	var fillbox := StyleBoxFlat.new(); fillbox.bg_color = Color(0.95, 0.55, 0.15); fillbox.set_corner_radius_all(6)
	fillbox.content_margin_top = 8; fillbox.content_margin_bottom = 8
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", fillbox)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fillbox)

func _clear_menu() -> void:
	if menu_root:
		menu_root.queue_free(); menu_root = null

func _new_menu(dim: float = 0.45) -> VBoxContainer:
	_clear_menu()
	menu_root = Control.new(); menu_root.theme = theme
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT); menu_root.size = Vector2(1920, 1080)
	ui_layer.add_child(menu_root)
	var shade := ColorRect.new(); shade.color = Color(0, 0, 0, dim); shade.size = Vector2(1920, 1080)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; menu_root.add_child(shade)
	var box := VBoxContainer.new(); box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.position = Vector2(460, 0); box.size = Vector2(1000, 1080)
	box.add_theme_constant_override("separation", 16)
	menu_root.add_child(box)
	return box

func _label(box: Control, text: String, size: int, col: Color = Color(1, 0.93, 0.82)) -> Label:
	var l := Label.new(); l.text = text; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	box.add_child(l); return l

func _button(box: Control, text: String, cb: Callable, disabled: bool = false) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size = Vector2(520, 56); b.disabled = disabled
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): audio.play("ui_select"); cb.call())
	b.focus_entered.connect(func(): audio.play("ui_move", -10.0))
	box.add_child(b); return b

func _focus_first(box: Control) -> void:
	for c in box.get_children():
		if c is Button and not c.disabled:
			c.call_deferred("grab_focus"); return

func start_mission() -> void:
	# QA runs skip the name box and keep the saved (or default) name.
	if qa.has("run"):
		_apply_player_name(Scores.player_name())
		_begin_mission()
		return
	show_name_prompt("start")

## Asks for the player name once at the start of a run, or from the title
## "Change name" button. The box is prefilled with the last used name.
func show_name_prompt(kind: String = "start") -> void:
	name_prompt_kind = kind
	mode = "player_name"
	_clear_menu()
	title_menu_open = false
	if briefing: briefing.visible = false
	if travel_map: travel_map.visible = false
	hud.visible = false
	view.visible = false
	title_screen.visible = true
	title_screen.press_start = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var box := _new_menu(0.0)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.position = Vector2(110, 500); box.size = Vector2(540, 560)
	box.add_theme_constant_override("separation", 8)
	_label(box, "PLAYER NAME", 40, Color(1, 0.82, 0.45))
	_label(box, "This name is used for every high score this run.", 22, Color(0.95, 0.88, 0.75, 0.9))
	player_name_edit = LineEdit.new()
	player_name_edit.text = Scores.player_name()
	player_name_edit.max_length = Scores.NAME_MAX
	player_name_edit.custom_minimum_size = Vector2(520, 64)
	player_name_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	player_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_name_edit.text_submitted.connect(func(txt): confirm_player_name(txt))
	player_name_edit.gui_input.connect(_on_name_gui_input)
	box.add_child(player_name_edit)
	online_hint = _label(box, "", 20, Color(1, 0.85, 0.35))
	_refresh_online_hint()
	_button(box, "Continue", func(): confirm_player_name(player_name_edit.text if player_name_edit else ""))
	if kind in ["menu", "change"]:
		_button(box, "Back", func(): show_title(true))
	_label(box, "Type a name, then press Enter or a gamepad button.", 20, Color(0.95, 0.88, 0.75, 0.85))
	player_name_edit.call_deferred("grab_focus")
	player_name_edit.call_deferred("select_all")

func confirm_player_name(text: String = "") -> void:
	if mode != "player_name" and text == "":
		return
	if text == "" and player_name_edit:
		text = player_name_edit.text
	_apply_player_name(text)
	var kind := name_prompt_kind
	name_prompt_kind = ""
	player_name_edit = null
	if mode != "player_name":
		if title_screen:
			title_screen.refresh_scores()
		return
	if kind in ["menu", "change"]:
		show_title(true)
	else:
		_begin_mission()

func _apply_player_name(text: String) -> void:
	settings.player_name = Scores.save_player_name(text)

func _begin_mission() -> void:
	if qa.has("run") or bool(settings.get("seen_briefing", false)):
		begin_run()
		start_stage(1)
		return
	show_briefing("play")

func show_briefing(kind: String = "play") -> void:
	briefing_kind = kind
	mode = "briefing"
	_clear_menu()
	title_menu_open = false
	hud.visible = false
	view.visible = false
	if travel_map: travel_map.visible = false
	title_screen.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	audio.clear_pause()
	audio.stop_loops()
	if audio.current_music != TITLE_LOOP:
		audio.play_music(TITLE_LOOP, TITLE_INTRO)
	briefing.reset()
	briefing.visible = true
	if qa.has("run") and not qa.has("briefing"):
		briefing.skip()
		_on_briefing_finished()

func _on_briefing_finished() -> void:
	if briefing: briefing.visible = false
	if briefing_kind == "story":
		show_travel_map("preview")
		return
	if briefing_kind == "pause":
		if sim != null:
			sim.paused = true
		mode = "paused"
		hud.visible = true
		view.visible = true
		title_screen.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		audio.pause_all()
		show_pause()
		return
	_mark_briefing_seen()
	begin_run()
	start_stage(1)

func _mark_briefing_seen() -> void:
	if qa.has("run") or qa.has("briefing") or qa.has("map") or qa.has("title"):
		return
	settings.seen_briefing = true
	Scores.save_settings(settings)

func show_travel_map(kind: String = "preview", cleared: int = 0) -> void:
	map_kind = kind
	mode = "travel_map"
	_clear_menu()
	title_menu_open = false
	hud.visible = false
	view.visible = false
	title_screen.visible = false
	if briefing: briefing.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	audio.clear_pause()
	audio.stop_loops()
	if audio.current_music != TITLE_LOOP and audio.current_music != TITLE_INTRO:
		audio.play_music(TITLE_LOOP, TITLE_INTRO)
	var stage_cleared := cleared if cleared > 0 else (stage_number if kind == "after_clear" else 0)
	travel_map.setup(stage_cleared, kind == "preview")
	travel_map.visible = true
	if qa.has("run") and not qa.has("map") and not qa.has("briefing"):
		_on_travel_map_finished()

func _on_travel_map_finished() -> void:
	if travel_map: travel_map.visible = false
	if map_kind == "preview":
		show_title(true)
		return
	var nxt := StageData.next_playable(travel_map.cleared_stage if travel_map else stage_number)
	show_store("continue" if nxt > 0 else "title")

func _after_clear_continue() -> void:
	if qa.has("run"):
		show_store("title")
		return
	show_travel_map("after_clear", stage_number)

func show_title(menu: bool = false) -> void:
	mode = "title"; hud.visible = false; view.visible = false; title_bg.visible = false
	if briefing: briefing.visible = false
	if travel_map: travel_map.visible = false
	title_screen.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	audio.clear_pause()
	audio.stop_loops()
	if audio.current_music != TITLE_LOOP:
		audio.play_music(TITLE_LOOP, TITLE_INTRO)
	if not title_call_played:
		_later(0.45, _play_title_call)
	title_screen.refresh_scores()
	_clear_menu()
	title_menu_open = false
	title_screen.press_start = true
	if menu: open_title_menu()

func _play_title_call() -> void:
	if title_call_played or mode != "title":
		return
	if not audio.has_sound("title_call"):
		return
	title_call_played = true
	audio.play("title_call", 2.0)
	# Line is about five seconds; duck slightly under the announcer, then ease back.
	audio.duck_music(-7.0, 3.8)

func open_global_scores() -> void:
	# Opens the public board in the system browser. Never fetch the host from here.
	OS.shell_open("https://firebreak.quietbytehq.uk")

func open_title_menu() -> void:
	title_menu_open = true
	title_screen.press_start = false
	audio.play("ui_select", -6.0)
	var box := _new_menu(0.0)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.position = Vector2(110, 500); box.size = Vector2(540, 560)
	box.add_theme_constant_override("separation", 8)
	_button(box, "START", start_mission)
	_button(box, "Change name", func(): show_name_prompt("change"))
	_button(box, "Store", func(): show_store("title"))
	_button(box, "Controls", func(): show_controls("title"))
	_button(box, "Fullscreen (F11)", toggle_fullscreen)
	_button(box, "Quit", func(): get_tree().quit())
	_label(box, "F1  Story briefing", 24, Color(1, 0.88, 0.62, 0.85))
	_focus_first(box)

func show_pause() -> void:
	var box := _new_menu(0.55)
	box.add_theme_constant_override("separation", 12)
	_label(box, "PAUSED", 90, Color(1, 0.78, 0.4))
	_button(box, "Resume", resume_game)
	_button(box, "Story briefing", func(): show_briefing("pause"))
	var music_btn := _button(box, "", func(): pass)
	music_btn.text = "Music: " + ("ON" if settings.music_on else "OFF")
	music_btn.pressed.connect(func(): set_music_on(not bool(settings.music_on)); music_btn.text = "Music: " + ("ON" if settings.music_on else "OFF"))
	var track_btn := _button(box, "", func(): pass)
	track_btn.text = "Track: %d of %d" % [int(settings.music_track), MUSIC_TRACKS.size()]
	track_btn.pressed.connect(func(): set_music_track(int(settings.music_track) % MUSIC_TRACKS.size() + 1); track_btn.text = "Track: %d of %d" % [int(settings.music_track), MUSIC_TRACKS.size()])
	_slider(box, "Music volume", float(settings.music_volume), func(v): set_volumes(float(settings.sfx_volume), v))
	_slider(box, "Effects volume", float(settings.sfx_volume), func(v): set_volumes(v, float(settings.music_volume)))
	_button(box, "Controls", func(): show_controls("paused"))
	_button(box, "Restart stage", func(): _bank_stage(); start_stage(stage_number))
	_button(box, "Quit to title", func(): _bank_stage(); audio.stop_music(); audio.stop_ambience(); show_title(true))
	_focus_first(box)

func _slider(box: Control, text: String, value: float, cb: Callable) -> HSlider:
	var row := HBoxContainer.new(); row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 18)
	var l := Label.new(); l.text = text; l.custom_minimum_size = Vector2(250, 0); l.add_theme_font_size_override("font_size", 28)
	row.add_child(l)
	var sl := HSlider.new(); sl.min_value = 0.0; sl.max_value = 1.0; sl.step = 0.05; sl.value = value
	sl.custom_minimum_size = Vector2(320, 40); sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.value_changed.connect(func(v): cb.call(v))
	row.add_child(sl)
	box.add_child(row)
	return sl

func set_music_on(on: bool) -> void:
	settings.music_on = on
	audio.set_music_on(on)
	if on and mode in ["playing", "paused"]: play_game_music()
	Scores.save_settings(settings)

func set_music_track(track: int) -> void:
	settings.music_track = clampi(track, 1, MUSIC_TRACKS.size())
	music_override = ""
	if mode in ["playing", "paused"]: play_game_music()
	Scores.save_settings(settings)

func set_volumes(sfx: float, music: float) -> void:
	settings.sfx_volume = clampf(sfx, 0.0, 1.0); settings.music_volume = clampf(music, 0.0, 1.0)
	audio.set_volumes(float(settings.sfx_volume), float(settings.music_volume))
	Scores.save_settings(settings)

## Cash, ammo and air strikes left at the end of a stage go back into the saved profile.
func _bank_stage() -> void:
	if sim == null or sim.get_meta("banked", false): return
	sim.set_meta("banked", true)
	sim.write_profile(profile)
	if sim.state == "cleared": profile.stages_cleared = int(profile.get("stages_cleared", 0)) + 1
	_save_profile()

func _save_profile() -> void:
	if qa.has("run") or qa.has("store"): return   # QA runs never touch the player's save
	Weapons.save_profile(profile)

## Saves a qualifying stage score under the name chosen at the start.
## The overall run table is written only when the run ends (fail, last stage,
## or quit to the title). Never asks for a name here. Returns a short status, or "".
func _record_scores() -> String:
	if qa.has("run") or sim == null:
		return ""
	if sim.get_meta("scores_recorded", false):
		return str(sim.get_meta("score_note", ""))
	var player := Scores.player_name()
	var stage_score := int(sim.score)
	var notes: Array = []
	var stage_rank := Scores.add_stage_score(player, stage_score, stage_number)
	if stage_rank > 0:
		var sn := str(StageData.stage_entry(stage_number).get("name", "Stage %d" % stage_number))
		notes.append("%s best saved as %s (#%d)" % [sn, player, stage_rank])
	var ending: bool = sim.state != "cleared" or StageData.next_playable(stage_number) <= 0
	if ending:
		var before := run_score_saved
		_record_run_score()
		if run_score_saved and not before and Scores.qualifies(run_score):
			notes.append("Run score saved as %s" % player)
		if bool(settings.get("online", true)) and run_score >= Online.MIN_SCORE:
			notes.append("Posted to the global top 100")
	var note := "    ".join(notes)
	sim.set_meta("scores_recorded", true)
	sim.set_meta("score_note", note)
	if title_screen:
		title_screen.refresh_scores()
	return note

func _record_run_score() -> void:
	if qa.has("run"):
		return
	if run_score_saved:
		return
	var name := Scores.player_name()
	Scores.add_score(name, run_score, run_stages)
	run_score_saved = true
	if bool(settings.get("online", true)) and run_score >= Online.MIN_SCORE:
		Online.submit(self, Scores.player_name(), run_score, run_stages)
	if title_screen:
		title_screen.refresh_scores()

func _quit_run_to_title() -> void:
	_record_run_score()
	show_title(true)

func can_use_continue() -> bool:
	return sim != null and sim.state == "failed" and run_continues > 0

## Spends one continue diamond and restarts the current stage. The failed
## attempt is discarded; earlier cleared stages keep their run score. The run
## high score is not written until the diamonds run out or the player gives up.
func use_continue() -> bool:
	if not can_use_continue():
		return false
	run_continues -= 1
	start_stage(stage_number)
	return true

func _finalize_failed_run() -> void:
	_bank_stage()
	bank_run_score()
	_record_scores()

func show_result() -> void:
	mode = "result"; hud.visible = false; qa_phase_t = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var cleared: bool = sim.state == "cleared"
	var offer: bool = can_use_continue()
	if not offer:
		_bank_stage()
		bank_run_score()
	var box := _new_menu(0.6)
	var portrait := ResultPortrait.new()
	portrait.fail = not cleared
	menu_root.add_child(portrait)
	menu_root.move_child(portrait, 1)
	box.position = Vector2(640, 0); box.size = Vector2(1220, 1080)
	var title := "STAGE CLEAR" if cleared else ("MISSION FAILED" if offer else "GAME OVER")
	_label(box, title, 110, Color(1, 0.8, 0.4) if cleared else Color(1, 0.4, 0.3))
	var reason := ""
	if cleared:
		if sim.end_reason == "quota":
			reason = "All enemy forces cleared"
		elif sim.end_reason == "boss":
			reason = "The harbour gunboat is sunk"
		else:
			reason = "You held the line until the timer ran out"
	elif sim.end_reason == "civilians":
		reason = "Too many civilians were hit"
	elif sim.end_reason == "health":
		reason = "You were overrun"
	_label(box, reason, 30)
	var acc := 100.0 * float(sim.stats.hits) / maxf(1.0, float(sim.stats.shots))
	_label(box, "Enemies down %d / %d    Accuracy %d%%    Villagers hit %d" % [sim.kills, sim.quota, int(acc), sim.stats.villagers_hit], 30)
	if cleared: _label(box, "Clear bonus %d" % sim.clear_bonus, 30)
	var shown: int = run_score if (run_banked or offer) else run_score + sim.score
	if offer:
		shown = run_score + sim.score
	_label(box, "SCORE %d" % shown, 60, Color(1, 1, 1))
	var cash_line := "Cash earned %s" % Hud.money(sim.cash_earned)
	if sim.cash_lost > 0: cash_line += "    Civilian penalties -%s" % Hud.money(sim.cash_lost)
	cash_line += "    Wallet %s" % Hud.money(int(profile.cash))
	_label(box, cash_line, 30, Color(0.6, 1, 0.55))
	if not offer:
		var note := _record_scores()
		if note != "":
			_label(box, note, 26, Color(1, 0.85, 0.4))
	if cleared:
		_button(box, "Continue", _after_clear_continue)
		_button(box, "Play again", func(): _record_run_score(); begin_run(); start_stage(stage_number))
		_button(box, "Title screen", func(): _quit_run_to_title())
	elif offer:
		_label(box, "Continues left: %d" % run_continues, 28, Color(0.55, 0.92, 1.0))
		_button(box, "Continue", func(): audio.play("ui_select"); use_continue())
		_button(box, "Give up", func(): _finalize_failed_run(); _quit_run_to_title())
		_button(box, "Title screen", func(): _finalize_failed_run(); _quit_run_to_title())
	else:
		_button(box, "Play again", func(): begin_run(); start_stage(stage_number))
		_button(box, "Store", func(): show_store("result"))
		_button(box, "Title screen", func(): _quit_run_to_title())
	_focus_first(box)
	if cleared:
		var nxt := StageData.next_playable(stage_number)
		if nxt > 0:
			_label(box, "Next: %s" % str(StageData.stage_entry(nxt).get("name", "the next stage")), 24, Color(0.9, 0.8, 0.65))
		else:
			_label(box, "Later Ember Ring stages arrive in later versions.", 24, Color(0.9, 0.8, 0.65))


func _refresh_online_hint() -> void:
	if online_hint == null: return
	if bool(settings.get("online", true)):
		online_hint.text = "Your name and score will also be posted to the global top 100 at %s  -  Tab: keep it on this computer only" % Online.SITE
	else:
		online_hint.text = "This score stays on this computer  -  Tab: also post it to the global top 100 at %s" % Online.SITE

func _on_name_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		settings.online = not bool(settings.get("online", true))
		Scores.save_settings(settings)
		_refresh_online_hint()
		var focused := get_viewport().gui_get_focus_owner()
		if focused: focused.accept_event()

func show_scores(back: String) -> void:
	return_mode = back; mode = "scores"; title_screen.visible = true; title_screen.press_start = false; view.visible = false; hud.visible = false
	var box := _new_menu(0.6)
	_label(box, "TOP SCORES", 90, Color(1, 0.78, 0.4))
	_label(box, "RUN", 36, Color(1, 0.82, 0.45))
	var list := Scores.load_scores()
	if list.is_empty():
		_label(box, "No run scores yet.", 28)
	for i in list.size():
		var s: Dictionary = list[i]
		_label(box, "%2d.  %-12s  %8d   %s" % [i + 1, str(s.name), int(s.score), str(s.get("date", ""))], 28)
	for stage in StageData.campaign().get("stages", []):
		if not bool(stage.get("playable", false)):
			continue
		var num := int(stage.get("number", 0))
		_label(box, str(stage.get("name", "Stage %d" % num)).to_upper(), 36, Color(1, 0.82, 0.45))
		var slist := Scores.load_stage_scores(num)
		if slist.is_empty():
			_label(box, "No scores yet.", 26)
		for i in slist.size():
			var s2: Dictionary = slist[i]
			_label(box, "%2d.  %-12s  %8d   %s" % [i + 1, str(s2.name), int(s2.score), str(s2.get("date", ""))], 26)
	_button(box, "Back", _back)
	_focus_first(box)

func show_controls(back: String) -> void:
	if back != "controls": return_mode = back
	var was_mode := mode
	mode = "controls"
	var box := _new_menu(0.7)
	_label(box, "CONTROLS", 80, Color(1, 0.78, 0.4))
	_label(box, "Mouse aims. Gamepad left stick or arrow keys / WASD also move the crosshair.", 24)
	var grid := GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)
	for action in InputSetup.ACTIONS:
		var l := Label.new(); l.text = InputSetup.LABELS[action]; l.add_theme_font_size_override("font_size", 24); grid.add_child(l)
		var v := Label.new(); v.text = InputSetup.describe_action(action); v.custom_minimum_size = Vector2(620, 0)
		v.add_theme_font_size_override("font_size", 22); v.autowrap_mode = TextServer.AUTOWRAP_WORD; grid.add_child(v)
		var b := Button.new(); b.text = "Rebind"; b.add_theme_font_size_override("font_size", 24); b.custom_minimum_size = Vector2(150, 44)
		b.disabled = action == "fullscreen"
		b.pressed.connect(func(): _start_rebind(action, v))
		grid.add_child(b)
	_button(box, "Reset to defaults", func(): InputSetup.reset_defaults(); show_controls("controls"))
	_button(box, "Back", _back)
	box.position = Vector2(160, 0); box.size = Vector2(1600, 1080)
	_focus_first(grid)

func _start_rebind(action: String, label: Label) -> void:
	rebinding = action
	label.text = "Press a key, mouse button or pad button…  (Esc cancels)"

func _input(event: InputEvent) -> void:
	if rebinding == "": return
	var accept := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			rebinding = ""; get_viewport().set_input_as_handled(); show_controls("controls"); return
		accept = true
	elif event is InputEventMouseButton and event.pressed:
		accept = true
	elif event is InputEventJoypadButton and event.pressed:
		accept = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		accept = true
	if accept:
		InputSetup.rebind(rebinding, event)
		InputSetup.save_remaps()
		rebinding = ""
		get_viewport().set_input_as_handled()
		show_controls.call_deferred("controls")

func _back() -> void:
	if mode == "store":
		_save_profile()
		if store_back == "result" and sim != null: show_result(); return
		show_title(true); return
	if return_mode == "paused":
		mode = "paused"; view.visible = true; title_screen.visible = false; show_pause()
	else:
		show_title(true)

# On a display whose refresh is not a whole multiple of 60 Hz (e.g. 144 Hz),
# vsync plus a 60 fps cap paces frames 13.9/20.8 ms. There the frame limiter
# alone gives an even 16.7 ms (measured on a 144 Hz laptop: frames over 18 ms
# fell from ~20% to ~3%). On 60/120/240 Hz displays vsync stays on.
var vsync_note := ""
func _choose_vsync() -> void:
	var hz := DisplayServer.screen_get_refresh_rate()
	if is_nan(hz) or hz <= 0.0: vsync_note = "unknown refresh, vsync as configured"; return
	var ratio := hz / float(TARGET_FPS)
	if absf(ratio - roundf(ratio)) > 0.05 and DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		vsync_note = "%.0f Hz display: vsync off, 60 fps limiter" % hz
	else:
		vsync_note = "%.0f Hz display: vsync as configured" % hz

# ------------------------------------------------------------------ QA autopilot
func _seed_demo_scores() -> void:
	Scores.add_score("RAYAN", 15400, 2)
	Scores.add_score("ACE", 12100, 2)
	Scores.add_score("AMIRA", 9800, 1)
	Scores.add_stage_score("RAYAN", 8200, 1)
	Scores.add_stage_score("ACE", 6100, 1)
	Scores.add_stage_score("RAYAN", 7300, 2)
	settings.player_name = "RAYAN"
	Scores.save_settings(settings)
	if title_screen:
		title_screen.refresh_scores()

func _parse_qa_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--qa-run": qa.run = true
		elif arg.begins_with("--qa-stage="): qa.stage = int(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-out="): qa.out = arg.get_slice("=", 1)
		elif arg.begins_with("--qa-seconds="): qa.seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-skip="): qa.skip = float(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-seed="): qa.seed = int(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-shots="): qa.shots = Array(arg.get_slice("=", 1).split(",")).map(func(s): return float(s))
		elif arg.begins_with("--qa-tag="): qa.tag = arg.get_slice("=", 1)
		elif arg.begins_with("--qa-react="): qa.react = float(arg.get_slice("=", 1))
		elif arg == "--qa-title": qa.title = true
		elif arg == "--qa-briefing": qa.briefing = true
		elif arg == "--qa-map": qa.map = true
		elif arg.begins_with("--qa-pause-at="): qa.pause_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-grenade-at="): qa.grenade_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-airstrike-at="): qa.airstrike_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-hurt-at="): qa.hurt_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-cash="): qa.cash = int(arg.get_slice("=", 1))
		elif arg.begins_with("--qa-loadout="): qa.loadout = Array(arg.get_slice("=", 1).split(","))
		elif arg.begins_with("--qa-store"): qa.store = arg.get_slice("=", 1) if arg.contains("=") else "pistol"
		elif arg == "--qa-no-fp": qa.no_fp = true
		elif arg.begins_with("--qa-fire-shots="): qa.fire_shots = Array(arg.get_slice("=", 1).split(",")).map(func(x): return float(x))
		elif arg.begins_with("--qa-slot-at="): qa.slot_at = Array(arg.get_slice("=", 1).split(",")).map(func(x): return float(x))
		elif arg.begins_with("--qa-reload-at="): qa.reload_at = float(arg.get_slice("=", 1))
		elif arg == "--qa-aim-head": qa.aim_head = true
		elif arg == "--qa-name": qa.name_prompt = true
		elif arg == "--qa-demo-scores": qa.demo_scores = true
		elif arg.begins_with("--qa-fail-at="): qa.fail_at = float(arg.get_slice("=", 1))

func _qa_autopilot(dt: float) -> void:
	# Aims at the most urgent enemy (or a drop), avoids villagers, fires when on target.
	var best := {}; var best_score := -INF
	for e in sim.entities:
		if not sim.is_hittable(e) or e.type == "villager" or e.age < float(qa.get("react", 0.0)): continue
		var r: Rect2 = sim.hitbox(e)
		var p := r.get_center() - Vector2(sim.camera_x, 0)
		if p.x < 20 or p.x > 1900 or p.y < 100 or p.y > 1070: continue
		var s := 0.0
		if e.type in ["food", "powerup"]: s = 2.0 + (2.0 if sim.health < 60 and e.type == "food" else 0.0)
		else: s = 3.0 + e.scale * 2.0 + (3.0 if e.state == "aim" and e.timer < 0.6 else 0.0)
		s -= p.distance_to(crosshair) / 900.0
		if s > best_score: best_score = s; best = e
	if not best.is_empty():
		var goal: Vector2 = sim.hitbox(best).get_center() - Vector2(sim.camera_x, 0)
		if qa.has("aim_head") and best.type in ["rifleman", "paratrooper", "mg", "sniper", "camel"]:
			var hb: Rect2 = sim.headbox(best)
			if hb.size.x > 0.0:
				goal = hb.get_center() - Vector2(sim.camera_x, 0)
		var step := 2400.0 * dt
		crosshair = crosshair.move_toward(goal, step)
		var under: Dictionary = sim.entity_at(crosshair)
		var safe: bool = not under.is_empty() and under.type != "villager"
		var sp: float = float(sim.weapon().get("spread", 0.0)) + 2.0
		for k in 8:
			var ring: Dictionary = sim.entity_at(crosshair + Vector2.from_angle(TAU * k / 8.0) * sp)
			if not ring.is_empty() and ring.type == "villager": safe = false
		if sim.spread_timer > 0.0:
			for off in [Vector2(-46, 10), Vector2(46, 10)]:
				var side: Dictionary = sim.entity_at(crosshair + off)
				if not side.is_empty() and side.type == "villager": safe = false
		if safe:
			sim.fire(crosshair)
		if best.type in ["mg", "truck", "heli"] and sim.grenades > 0 and randf() < dt * 0.3 and not _villager_near(goal, sim.GRENADE_RADIUS + 60.0):
			sim.throw_grenade(goal)

## A safe aim point for a forced QA shot: the nearest enemy away from villagers.
func _qa_fire_target() -> Vector2:
	var best := crosshair; var best_d := INF
	for e in sim.entities:
		if not sim.is_hittable(e) or e.type in ["villager", "food", "powerup"]: continue
		var p: Vector2 = sim.hitbox(e).get_center() - Vector2(sim.camera_x, 0)
		if p.x < 80 or p.x > 1840 or p.y < 120 or p.y > 900 or _villager_near(p, 160.0): continue
		var d := p.distance_to(crosshair)
		if d < best_d: best_d = d; best = p
	return best

func _villager_near(p: Vector2, r: float) -> bool:
	for e in sim.entities:
		if e.type == "villager" and (sim.hitbox(e).get_center() - Vector2(sim.camera_x, 0)).distance_to(p) < r: return true
	return false

var qa_phase_t := 0.0
func _qa_tick(delta: float) -> void:
	var out := str(qa.get("out", "user://qa"))
	var tag := str(qa.get("tag", "gameplay"))
	qa_phase_t += delta
	if mode != "playing": qa_last_us = 0   # don't count title/pause time as a frame
	if mode == "briefing":
		if qa_phase_t > 3.8 and not qa_shots_done.has("briefing"):
			qa_shots_done["briefing"] = true; _qa_capture(out.path_join(tag + "-briefing.png"))
		if qa_phase_t > 4.3:
			briefing.skip(); _on_briefing_finished(); qa_phase_t = 0.0
		return
	if mode == "travel_map":
		if qa_phase_t > 1.4 and not qa_shots_done.has("map"):
			qa_shots_done["map"] = true; _qa_capture(out.path_join(tag + "-map.png"))
		if qa_phase_t > 2.0:
			if qa.has("map") or (qa.has("briefing") and qa_shots_done.has("briefing")):
				_qa_finish(out)
			else:
				_on_travel_map_finished(); qa_phase_t = 0.0
		return
	if qa.has("name_prompt") and not qa.has("run"):
		if mode == "title" and qa_phase_t > 0.6:
			show_name_prompt("start")
		if mode == "player_name":
			if qa_phase_t > 2.2 and not qa_shots_done.has("name"):
				qa_shots_done["name"] = true
				_qa_capture(out.path_join(tag + "-name.png"))
			if qa_phase_t > 2.8:
				_qa_finish(out)
			return
	if mode == "title":
		if qa_phase_t > 3.0 and not qa_shots_done.has("title"):
			qa_shots_done["title"] = true; _qa_capture(out.path_join(tag + "-title.png"))
		if qa.has("title") and not qa.has("run"):
			if qa_phase_t > 3.15 and not title_menu_open:
				open_title_menu()
			if qa_phase_t > 3.6 and not qa_shots_done.has("title-menu"):
				qa_shots_done["title-menu"] = true; _qa_capture(out.path_join(tag + "-title-menu.png"))
			if qa_phase_t > 4.1:
				_qa_finish(out)
			return
		if qa_phase_t > 3.5: start_stage(1); qa_phase_t = 0.0
		return
	if mode == "paused":
		if qa_phase_t > 0.6 and not qa_shots_done.has("pause"):
			qa_shots_done["pause"] = true; _qa_capture(out.path_join(tag + "-pause.png"))
		if qa_phase_t > 1.0: resume_game(); qa_phase_t = 0.0
		return
	if mode == "result":
		if qa_phase_t > 1.0:
			_qa_capture(out.path_join(tag + "-result.png")); _qa_finish(out)
		return
	if mode != "playing": return
	qa_clock += delta
	if qa.has("pause_at") and qa_clock >= float(qa.pause_at) and not qa_shots_done.has("pause"):
		pause_game(); qa_phase_t = 0.0; return
	# Scripted QA moments (each fires once): a grenade at the busiest group of
	# enemies, an air strike, and a 12-point hit for the hit-feedback capture.
	if qa.has("grenade_at") and qa_clock >= float(qa.grenade_at) and not qa_shots_done.has("grenade"):
		qa_shots_done["grenade"] = true; sim.throw_grenade(_qa_cluster())
	if qa.has("reload_at") and qa_clock >= float(qa.reload_at) and not qa_shots_done.has("reload"):
		qa_shots_done["reload"] = true
		# Empty the current mag so a reload is legal, then start it.
		if not sim.loadout.is_empty():
			sim.loadout[sim.slot].mag = 0
			sim.reload()
	if qa.has("airstrike_at") and qa_clock >= float(qa.airstrike_at) and not qa_shots_done.has("airstrike"):
		qa_shots_done["airstrike"] = true; sim.call_airstrike()
	if qa.has("slot_at"):
		var sa: Array = qa.slot_at
		for i in sa.size():
			if qa_clock >= sa[i] and not qa_shots_done.has("slot%d" % i):
				qa_shots_done["slot%d" % i] = true; sim.select_slot(i % 3)
	if qa.has("hurt_at") and qa_clock >= float(qa.hurt_at) and not qa_shots_done.has("hurt"):
		qa_shots_done["hurt"] = true; sim.damage_player(12.0)
	if qa.has("fail_at") and qa_clock >= float(qa.fail_at) and not qa_shots_done.has("fail"):
		qa_shots_done["fail"] = true
		if sim.state == "playing":
			sim.damage_player(sim.health + 20.0)
	# Mid-fire captures: force one shot at each time, then grab the next frame,
	# which shows the muzzle flash and sparks drawn for that shot.
	if not qa_fire_capture.is_empty():
		_qa_capture(qa_fire_capture[0]); qa_fire_capture = []
	for ft in qa.get("fire_shots", []):
		var key := "fire%.2f" % ft
		if qa_clock >= ft and not qa_shots_done.has(key):
			qa_shots_done[key] = true
			sim.fire_cooldown = 0.0; sim.special_cooldown = 0.0
			crosshair = _qa_fire_target(); hud.crosshair = crosshair; fp.crosshair = crosshair
			sim.fire(crosshair)
			qa_fire_capture = [out.path_join("%s-fire-%03ds.png" % [tag, int(ft)])]
	for st in qa.get("shots", []):
		if qa_clock >= st and not qa_shots_done.has(st):
			qa_shots_done[st] = true
			_qa_capture(out.path_join("%s-%03ds.png" % [tag, int(st)]))
	if sim != null:
		var hits: Array = []
		if sim.grounded_offenders(hits) > 0:
			qa_ground_frames += 1
			if qa_ground_hits.size() < 24:
				for h in hits:
					qa_ground_hits.append(h)
					if qa_ground_hits.size() >= 24:
						break
	if qa_clock >= float(qa.get("seconds", 30.0)):
		_qa_finish(out)
	elif sim.state != "playing":
		qa_phase_t = 0.0

func _qa_cluster() -> Vector2:
	var best := Vector2(960, 700); var best_n := -1
	for e in sim.entities:
		if not (e.type in sim.ENEMY_TYPES) or not sim.is_hittable(e): continue
		var c: Vector2 = sim.hitbox(e).get_center() - Vector2(sim.camera_x, 0)
		var n := 0
		for o in sim.entities:
			if o.type in sim.ENEMY_TYPES and sim.is_hittable(o) and (sim.hitbox(o).get_center() - Vector2(sim.camera_x, 0)).distance_to(c) < sim.GRENADE_RADIUS * 0.8: n += 1
		if n > best_n: best_n = n; best = c
	return best

func _qa_capture(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	qa_skip_frames = 2

func _qa_finish(out: String) -> void:
	if qa_finished: return
	qa_finished = true
	var frames := qa_frames.slice(30)   # skip warm-up frames
	var total := 0.0
	var worst := 0.0
	var over := 0
	for f in frames:
		total += f; worst = maxf(worst, f)
		if f > 1.0 / 55.0: over += 1
	var sorted := frames.duplicate(); sorted.sort()
	var p99: float = sorted[int(sorted.size() * 0.99)] if not sorted.is_empty() else 0.0
	var report := {
		"frames": frames.size(), "seconds": total, "avg_fps": frames.size() / maxf(0.001, total),
		"worst_frame_ms": worst * 1000.0, "p99_frame_ms": p99 * 1000.0, "frames_over_18ms": over,
		"low_1pct_fps": 1.0 / maxf(0.0001, p99), "refresh_hz": DisplayServer.screen_get_refresh_rate(),
		"vsync_mode": DisplayServer.window_get_vsync_mode(), "excluded_capture_frames": true,
		"adapter": RenderingServer.get_video_adapter_name(), "vendor": RenderingServer.get_video_adapter_vendor(),
		"api": RenderingServer.get_video_adapter_api_version(), "display": DisplayServer.get_name(),
		"window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"max_fps": Engine.max_fps,
		"vsync_note": vsync_note,
		"delta_smoothing": ProjectSettings.get_setting("application/run/delta_smoothing", true),
	}
	if sim != null:
		report["stage_time"] = sim.time
		report["stage_state"] = sim.state
		report["end_reason"] = sim.end_reason
		report["score"] = sim.score
		report["kills"] = sim.kills
		report["quota"] = sim.quota
		report["health"] = sim.health
		report["villagers_hit"] = sim.stats.villagers_hit
		report["shots"] = sim.stats.shots
		report["hits"] = sim.stats.hits
		report["grenades_left"] = sim.grenades
		report["airstrikes_left"] = sim.airstrikes
	else:
		report["stage_state"] = mode
	# Wall-clock timing measured between _process calls, independent of Godot's delta smoothing.
	var raw := qa_raw.slice(30)
	if not raw.is_empty():
		var rt := 0.0; var rw := 0.0; var ro := 0
		for f in raw:
			rt += f; rw = maxf(rw, f)
			if f > 1.0 / 55.0: ro += 1
		var rs := raw.duplicate(); rs.sort()
		var rp99: float = rs[int(rs.size() * 0.99)]
		report["raw_frames"] = raw.size(); report["raw_avg_fps"] = raw.size() / maxf(0.001, rt)
		report["raw_p99_frame_ms"] = rp99 * 1000.0; report["raw_low_1pct_fps"] = 1.0 / maxf(0.0001, rp99)
		report["raw_worst_frame_ms"] = rw * 1000.0; report["raw_frames_over_18ms"] = ro
		var hist := {}
		for f in raw:
			var b := str(clampi(int(round(f * 1000.0)), 0, 60))
			hist[b] = int(hist.get(b, 0)) + 1
		report["raw_ms_histogram"] = hist
	report["ground_off_frames"] = qa_ground_frames
	report["ground_offenders"] = qa_ground_hits
	var f := FileAccess.open(out.path_join("%s-performance.json" % str(qa.get("tag", "gameplay"))), FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(report, " ")); f.close()
	print("QA ", JSON.stringify(report))
	if qa_ground_frames > 0:
		push_error("QA ground contact failed: %d frames, first %s" % [qa_ground_frames, str(qa_ground_hits[0] if qa_ground_hits else {})])
		get_tree().quit(1)
	else:
		get_tree().quit()

# ------------------------------------------------------------------ store
const STORE_STATS := [["Damage", "damage", 5.0], ["Fire rate", "fire_rate", 18.0], ["Magazine", "mag", 100.0]]

func show_store(back: String = "title") -> void:
	if mode != "store": store_back = back
	mode = "store"; hud.visible = false; view.visible = false; title_screen.visible = true; title_screen.press_start = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var cats := Weapons.categories().map(func(c): return str(c.id))
	if not cats.has(store_cat): store_cat = "pistol"
	if store_item(store_sel).is_empty() or str(store_item(store_sel).category) != store_cat:
		store_sel = str(Weapons.in_category(store_cat)[0].id)
	var box := _new_menu(0.86); box.visible = false
	var root := menu_root
	_place(root, _mk_label("STORE", 84, Color(1, 0.78, 0.4)), Vector2(80, 28))
	_place(root, _mk_label("Buy and equip between missions. Carry one pistol, one primary and one special.", 24), Vector2(84, 128))
	var cash_l := _mk_label("CASH  " + Hud.money(int(profile.cash)), 52, Color(0.6, 1, 0.55))
	cash_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; cash_l.size = Vector2(700, 70)
	_place(root, cash_l, Vector2(1140, 40))
	# Category tabs
	var tabs := HBoxContainer.new(); tabs.add_theme_constant_override("separation", 12)
	_place(root, tabs, Vector2(80, 180))
	var sel_btn: Button = null
	for c in Weapons.categories():
		var b := Button.new(); b.text = str(c.name).to_upper(); b.custom_minimum_size = Vector2(250, 62)
		b.add_theme_font_size_override("font_size", 30)
		if str(c.id) == store_cat:
			b.add_theme_color_override("font_color", Color(0.1, 0.05, 0.0))
			var st := StyleBoxFlat.new(); st.bg_color = Color(1, 0.7, 0.3); st.set_corner_radius_all(6)
			b.add_theme_stylebox_override("normal", st)
		var cid := str(c.id)
		b.pressed.connect(func(): audio.play("ui_select"); store_cat = cid; store_sel = ""; store_note = ""; show_store())
		tabs.add_child(b)
	# Item list
	var list := VBoxContainer.new(); list.add_theme_constant_override("separation", 8)
	_place(root, list, Vector2(80, 264))
	var items: Array = Weapons.in_category(store_cat)
	if store_cat == "special": items = items + [Weapons.support()]
	for w in items:
		var id := str(w.id)
		var b := Button.new(); b.custom_minimum_size = Vector2(780, 96)
		var tex := Hud.icon_for(id)
		if tex:
			var tr := TextureRect.new(); tr.texture = tex; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; tr.position = Vector2(14, 8); tr.size = Vector2(170, 80)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(tr)
		var nm := _mk_label(str(w.name), 30); nm.position = Vector2(206, 26); nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nm)
		var tag := _mk_label(_store_status(id), 26, _store_status_color(id))
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; tag.size = Vector2(300, 40); tag.position = Vector2(460, 28)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(tag)
		if id == store_sel:
			var st := StyleBoxFlat.new(); st.bg_color = Color(0.42, 0.22, 0.07, 0.96); st.border_color = Color(1, 0.75, 0.35)
			st.set_border_width_all(3); st.set_corner_radius_all(6)
			b.add_theme_stylebox_override("normal", st); sel_btn = b
		b.pressed.connect(func(): audio.play("ui_move", -6.0); store_sel = id; store_note = ""; show_store())
		list.add_child(b)
	_store_detail(root)
	_store_loadout(root)
	var nav := HBoxContainer.new(); nav.add_theme_constant_override("separation", 16)
	_place(root, nav, Vector2(1200, 960))
	var back_b := Button.new(); back_b.text = "Back"; back_b.custom_minimum_size = Vector2(300, 72)
	back_b.pressed.connect(func(): audio.play("ui_select"); _back()); nav.add_child(back_b)
	var nxt := StageData.next_playable(run_stages if store_back == "continue" else 0)
	var go := Button.new(); go.custom_minimum_size = Vector2(340, 72)
	if store_back == "continue" and nxt > 0:
		go.text = "Continue to %s" % str(StageData.stage_entry(nxt).get("name", "next stage"))
		go.pressed.connect(func(): audio.play("ui_select"); _save_profile(); continue_run_to(nxt))
	else:
		go.text = "Start mission"
		go.pressed.connect(func(): audio.play("ui_select"); _save_profile(); start_mission())
	nav.add_child(go)
	if sel_btn: sel_btn.call_deferred("grab_focus")

func store_item(id: String) -> Dictionary:
	if id == "air_strike": return Weapons.support()
	return Weapons.get_weapon(id)

func _store_status(id: String) -> String:
	if id == "air_strike": return "%d / %d carried" % [int(profile.airstrikes), int(Weapons.support().get("max", 3))]
	if profile.loadout.has(id): return "EQUIPPED"
	if profile.owned.has(id): return "OWNED"
	return Hud.money(int(Weapons.get_weapon(id).price))

func _store_status_color(id: String) -> Color:
	if id == "air_strike": return Color(1, 0.85, 0.5)
	if profile.loadout.has(id): return Color(1, 0.75, 0.3)
	if profile.owned.has(id): return Color(0.7, 0.9, 1)
	return Color(0.6, 1, 0.55) if int(profile.cash) >= int(Weapons.get_weapon(id).price) else Color(1, 0.45, 0.35)

func _mk_label(text: String, size: int, col: Color = Color(1, 0.93, 0.82)) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	return l

func _place(root: Control, c: Control, pos: Vector2) -> Control:
	c.position = pos; root.add_child(c); return c

func _store_detail(root: Control) -> void:
	var w := store_item(store_sel)
	var panel := Panel.new(); panel.position = Vector2(900, 264); panel.size = Vector2(940, 610)
	var st := StyleBoxFlat.new(); st.bg_color = Color(0.08, 0.06, 0.04, 0.92); st.border_color = Color(0.85, 0.55, 0.25, 0.7)
	st.set_border_width_all(2); st.set_corner_radius_all(8); panel.add_theme_stylebox_override("panel", st)
	root.add_child(panel)
	var tex := Hud.icon_for(store_sel)
	if tex:
		var tr := TextureRect.new(); tr.texture = tex; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; tr.position = Vector2(30, 20); tr.size = Vector2(500, 210)
		panel.add_child(tr)
	_place(panel, _mk_label(str(w.get("name", "")).to_upper(), 46, Color(1, 0.8, 0.45)), Vector2(560, 30))
	var price := _mk_label(("Free" if int(w.get("price", 0)) == 0 else Hud.money(int(w.get("price", 0)))) + "   " + str(w.get("category", "")).to_upper(), 26, Color(0.6, 1, 0.55))
	_place(panel, price, Vector2(562, 92))
	var blurb := _mk_label(str(w.get("blurb", "")), 24); blurb.autowrap_mode = TextServer.AUTOWRAP_WORD
	blurb.size = Vector2(350, 120); _place(panel, blurb, Vector2(562, 132))
	var y := 250.0
	if store_sel == "air_strike":
		_place(panel, _mk_label("Called with E, middle click or pad RB. One is issued free every stage.", 26), Vector2(40, y))
		_place(panel, _mk_label("Carried: %d / %d" % [int(profile.airstrikes), int(w.get("max", 3))], 30), Vector2(40, y + 60))
	else:
		var rows := []
		if str(w.category) == "special":
			rows = [["Blast damage", float(w.get("blast_damage", 0)) / 40.0, str(w.get("blast_damage", 0))],
				["Blast radius", float(w.get("radius", 0)) / 450.0, "%d px" % int(w.get("radius", 0))],
				["Shots", float(w.mag) / 6.0, "%d per load" % int(w.mag)],
				["Reload", 1.0 - clampf(float(w.reload) / 4.0, 0.0, 0.95), "%.1f s" % float(w.reload)]]
		else:
			rows = [["Damage", float(w.damage) / 5.0, str(snappedf(float(w.damage), 0.01))],
				["Fire rate", float(w.fire_rate) / 18.0, "%.1f /s" % float(w.fire_rate)],
				["Magazine", float(w.mag) / 100.0, "%d" % int(w.mag)],
				["Reload", 1.0 - clampf(float(w.reload) / 3.5, 0.0, 0.95), "%.1f s" % float(w.reload)],
				["Accuracy", 1.0 - clampf(float(w.spread) / 26.0, 0.0, 0.95), "pierces %d" % int(w.pierce) if w.has("pierce") else ""]]
		for r in rows:
			_place(panel, _mk_label(r[0], 26), Vector2(40, y))
			var bg := ColorRect.new(); bg.color = Color(0.2, 0.16, 0.12); bg.size = Vector2(520, 22); _place(panel, bg, Vector2(240, y + 8))
			var fg := ColorRect.new(); fg.color = Color(1, 0.65, 0.25); fg.size = Vector2(520 * clampf(float(r[1]), 0.04, 1.0), 22); _place(panel, fg, Vector2(240, y + 8))
			_place(panel, _mk_label(str(r[2]), 22), Vector2(776, y + 2))
			y += 42.0
		var a: Dictionary = profile.ammo.get(store_sel, {})
		if profile.owned.has(store_sel):
			var ammo_txt := "Ammo: unlimited" if Weapons.is_infinite(store_sel) else "Ammo: %d loaded + %d spare (max %d)" % [int(a.get("mag", 0)), int(a.get("reserve", 0)), int(w.get("max_reserve", 0))]
			_place(panel, _mk_label(ammo_txt, 26, Color(0.8, 0.9, 1)), Vector2(40, y + 8))
	# Actions
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 14)
	_place(panel, row, Vector2(40, 506))
	if store_sel == "air_strike":
		var why := Weapons.can_buy_airstrike(profile)
		_store_action(row, "Buy air strike  " + Hud.money(int(w.price)), why, func(): Weapons.buy_airstrike(profile))
	elif not profile.owned.has(store_sel):
		_store_action(row, "Buy  " + Hud.money(int(w.price)), Weapons.can_buy(profile, store_sel), func(): Weapons.buy(profile, store_sel))
	else:
		var eq: bool = profile.loadout.has(store_sel)
		var b := Button.new(); b.text = "Equipped" if eq else "Equip"; b.disabled = eq; b.custom_minimum_size = Vector2(240, 66)
		b.pressed.connect(func(): Weapons.equip(profile, store_sel); audio.play("weapon_switch"); store_note = str(w.name) + " equipped"; _save_profile(); show_store())
		row.add_child(b)
		if not Weapons.is_infinite(store_sel):
			_store_action(row, "Ammo +%d  %s" % [int(w.ammo_pack), Hud.money(int(w.ammo_price))], Weapons.can_buy_ammo(profile, store_sel), func(): Weapons.buy_ammo(profile, store_sel))
	if store_note != "":
		_place(panel, _mk_label(store_note, 22, Color(1, 0.85, 0.5)), Vector2(40, 578))

func _store_action(row: Control, text: String, why: String, act: Callable) -> void:
	var b := Button.new(); b.text = text if why == "" else "%s  (%s)" % [text, why]; b.custom_minimum_size = Vector2(300, 66)
	b.disabled = why != ""
	b.pressed.connect(func(): _store_do(act))
	row.add_child(b)

func _store_loadout(root: Control) -> void:
	_place(root, _mk_label("LOADOUT", 26, Color(1, 0.78, 0.4)), Vector2(80, 900))
	for i in 3:
		var id := str(profile.loadout[i])
		var w := Weapons.get_weapon(id)
		var r := Rect2(80 + i * 360, 936, 344, 112)
		var p := Panel.new(); p.position = r.position; p.size = r.size
		var st := StyleBoxFlat.new(); st.bg_color = Color(0.08, 0.06, 0.04, 0.9); st.border_color = Color(1, 0.7, 0.3, 0.6)
		st.set_border_width_all(2); st.set_corner_radius_all(6); p.add_theme_stylebox_override("panel", st)
		root.add_child(p)
		var tex := Hud.icon_for(id)
		if tex:
			var tr := TextureRect.new(); tr.texture = tex; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; tr.position = Vector2(10, 8); tr.size = Vector2(160, 70)
			p.add_child(tr)
		_place(p, _mk_label("%d  %s" % [i + 1, str(w.get("name", ""))], 24, Color(1, 0.9, 0.7)), Vector2(12, 76))
		var a: Dictionary = profile.ammo.get(id, {})
		var at := "∞" if Weapons.is_infinite(id) else "%d+%d" % [int(a.get("mag", 0)), int(a.get("reserve", 0))]
		var al := _mk_label(at, 24, Color(0.8, 0.9, 1)); al.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; al.size = Vector2(150, 30)
		_place(p, al, Vector2(180, 20))

func _store_do(act: Callable) -> void:
	if act.call():
		audio.play_first(["store_purchase", "pickup_power"]); store_note = "Purchased"
		_save_profile()
	else:
		audio.play_first(["store_denied", "empty_click"])
	show_store()

## QA: walks the store tabs, buys one item and captures each step, then quits.
var qa_store_step := 0
func _qa_store_tick() -> void:
	var out := str(qa.get("out", "user://qa"))
	var tag := str(qa.get("tag", "store"))
	var plan := [["pistol", "talon_50", ""], ["smg", "stinger_v", ""], ["rifle", "sentinel_m4", "buy"], ["special", "hammer_rpg", ""], ["special", "air_strike", ""]]
	if qa_phase_t < 1.2 or qa_store_step > plan.size(): return
	if qa_store_step == plan.size():
		qa_store_step += 1; get_tree().quit(); return
	var st: Array = plan[qa_store_step]
	if mode != "store" or store_cat != st[0] or store_sel != st[1]:
		store_cat = st[0]; store_sel = st[1]; store_note = ""; show_store(); qa_phase_t = 0.6; return
	if st[2] == "buy" and not profile.owned.has(st[1]):
		_store_do(func(): return Weapons.buy(profile, st[1])); qa_phase_t = 0.6; return
	_qa_capture(out.path_join("%s-%d-%s-%s.png" % [tag, qa_store_step, st[0], st[1]]))
	qa_store_step += 1; qa_phase_t = 0.0
