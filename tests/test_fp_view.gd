extends SceneTree
## First-person weapon view (0.3.7): one cut-out picture per weapon plus the
## air-strike radio, the view follows the selected weapon through the switch
## animation, kicks on every shot, sparks for guns and smoke for launchers,
## dips while reloading, hides outside play and stays below the HUD.
const Weapons := preload("res://scripts/weapons.gd")
const FpView := preload("res://scripts/fp_view.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame

func run() -> void:
	# Data and pictures.
	var data := FpView.load_data()
	check(str(data.get("version", "")) == "0.3.7", "fp_weapons.json carries version 0.3.7")
	var ids: Array = []
	for w in Weapons.all(): ids.append(str(w.id))
	check(ids.size() == 19, "19 guns and launchers in the store")
	for id in ids + ["air_strike"]:
		var info: Dictionary = data.get("views", {}).get(id, {})
		var m = info.get("muzzle")
		check(m is Array and m.size() == 2 and float(m[0]) > 0.0 and float(m[0]) < 1.0 and float(m[1]) > 0.0 and float(m[1]) < 1.0, "muzzle point inside the picture: " + id)
		var tex: Texture2D = load("res://assets/sprites/fp/%s.png" % id) if ResourceLoader.exists("res://assets/sprites/fp/%s.png" % id) else null
		check(tex != null and tex.get_width() == 640 and tex.get_height() == 640, "640x640 first-person picture: " + id)
		if tex != null:
			var img := tex.get_image()
			if img.is_compressed(): img.decompress()
			check(img.get_pixel(4, 4).a < 0.05 and img.get_pixel(635, 4).a < 0.05, "background cut away (transparent corners): " + id)
	for id in ["hammer_rpg", "tankbuster"]:
		check(data.views[id].has("rear"), "back-blast point for " + id)
	var reload_ok: Array = [
		"viper_9", "talon_50", "warden_1911", "kestrel_p9", "rook_revolver",
		"hornet_9", "buzzsaw", "stinger_v", "mamba_90", "ratchet_mac",
		"kalash_47", "sentinel_m4", "granite_g3", "longshot_700"]
	var reload_no: Array = ["thunder_m60", "hammer_rpg", "tankbuster", "thumper_gl", "frag_grenades", "air_strike"]
	var listed: Array = data.get("reload_poses", [])
	for id in reload_ok:
		check(id in listed and ResourceLoader.exists("res://assets/sprites/fp/%s_reload.png" % id), "magazine gun has a side reload pose: " + id)
	for id in reload_no:
		check(id not in listed and not ResourceLoader.exists("res://assets/sprites/fp/%s_reload.png" % id), "no side reload pose for " + id)

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	var fp = main.fp
	check(fp != null and not fp.visible, "first-person view hidden on the title screen")
	var fp_layer: CanvasLayer = fp.get_parent()
	var hud_layer: CanvasLayer = main.hud.get_parent()
	check(fp_layer.layer < hud_layer.layer, "view is drawn under the HUD layer (weapon bar and reticle on top)")
	check(fp_layer.get_children().find(fp) < fp_layer.get_children().find(main.fx_rect), "view sits under the screen effects")
	main.start_stage(1)
	await frames(30)
	var sim = main.sim
	check(fp.visible and fp.active, "view shown in play")
	check(fp.shown_id == str(sim.loadout[sim.slot].id) and fp.lower < 0.01, "view shows the selected weapon, raised")
	check(fp.texture_for(fp.shown_id) != null, "picture for the selected weapon loads")
	# Switching.
	var start_id: String = fp.shown_id
	sim.select_slot(0)
	await frames(2)
	check(fp.phase == "lower" and fp.shown_id == start_id, "a switch first lowers the old weapon")
	await frames(30)
	check(fp.shown_id == str(sim.loadout[0].id) and fp.phase == "idle" and fp.lower < 0.01, "then raises the newly selected weapon")
	for i in [2, 1, 0]:
		sim.select_slot(i); await frames(35)
		check(fp.shown_id == str(sim.loadout[i].id), "view matches slot %d (%s)" % [i, sim.loadout[i].id])
	# Recoil and sparks on a shot.
	await frames(20)
	check(fp.kick < 0.05, "no recoil when idle")
	sim.fire_cooldown = 0.0
	var shots_before: int = fp.shots
	check(sim.fire(Vector2(960, 400)), "the pistol fires")
	check(fp.shots == shots_before + 1 and fp.kick > 0.9, "the view kicks back on the shot")
	check(fp.sparks.size() >= 6 and fp.flash > 0.0 and fp.flash_kind == "gun", "guns show a muzzle flash and sparks")
	var spark_start: Vector2 = fp.sparks[0].p
	check(spark_start.distance_to(fp.muzzle_screen()) < 2.0, "sparks start at the muzzle")
	check(fp.puffs.size() >= 3, "guns throw a puff of smoke from the barrel")
	check(fp.puffs[0].p.distance_to(fp.muzzle_screen()) < 16.0, "barrel smoke starts at the muzzle")
	check(fp.flash_scale > 0.8 and fp.FLASH_TIME >= 0.1, "the muzzle flash is larger and lasts a moment")
	await frames(30)
	check(fp.kick < 0.2 and fp.sparks.is_empty(), "recoil settles and the sparks die out")
	# Launcher: smoke and back-blast, no gun sparks.
	sim.loadout[2].id = "hammer_rpg"; sim.loadout[2].mag = 1; sim.loadout[2].reserve = 3
	sim.select_slot(2); await frames(35)
	check(fp.shown_id == "hammer_rpg", "launcher view selected")
	sim.special_cooldown = 0.0; sim.special_reload = 0.0
	var n_sparks: int = fp.sparks.size()
	check(sim.fire(Vector2(960, 420)), "the launcher fires")
	check(fp.kick > 0.9 and fp.flash_kind == "launch" and fp.puffs.size() >= 10 and fp.sparks.size() == n_sparks, "launchers get a launch puff and back-blast instead of sparks")
	check(fp.kick_scale > 1.2, "launchers kick harder than guns")
	await frames(3)
	check(fp.dip > 0.0, "the view dips while the launcher reloads")
	# Special used from another slot shows it briefly, then the selected weapon again.
	sim.select_slot(1); await frames(35)
	sim.loadout[2].id = "frag_grenades"; sim.loadout[2].mag = 3; sim.loadout[2].reserve = 0
	sim.special_cooldown = 0.0; sim.special_reload = 0.0
	sim.throw_grenade(Vector2(900, 500)); await frames(20)
	check(fp.shown_id == "frag_grenades", "a grenade thrown from the rifle slot briefly shows the grenade hand")
	await frames(70)
	check(fp.shown_id == str(sim.loadout[1].id), "then the rifle comes back")
	# Air strike shows the radio.
	sim.airstrikes = 1
	sim.call_airstrike(); await frames(20)
	check(fp.shown_id == "air_strike", "calling the air strike shows the radio hand")
	# Reload dip on a gun.
	await frames(90)
	sim.loadout[1].mag = 0
	sim.reload(); await frames(8)
	check(sim.reload_timer > 0.0 and fp.dip > 0.2, "the view dips during a reload")
	var rid: String = str(sim.loadout[1].id)
	check(fp.has_reload_art(rid) and fp.draw_id() == rid + "_reload", "a magazine rifle shows its side reload pose")
	# Belt-fed MG: dip only, no pose change.
	sim.loadout[1].id = "thunder_m60"; sim.loadout[1].mag = 0; sim.loadout[1].reserve = 200
	sim.select_slot(1); await frames(35)
	sim.reload(); await frames(8)
	check(sim.reload_timer > 0.0 and fp.dip > 0.2, "the Thunder M60 still dips while reloading")
	check(not fp.has_reload_art("thunder_m60") and fp.draw_id() == "thunder_m60", "the Thunder M60 keeps its rear view during reload")
	# Launchers also dip without a side pose.
	check(not fp.has_reload_art("hammer_rpg") and not fp.has_reload_art("tankbuster") and not fp.has_reload_art("thumper_gl"), "launchers have no side reload pose")
	# Pause freezes the view; menus hide it.
	main.pause_game(); await frames(2)
	var k0: float = fp.kick; var lw: float = fp.lower
	await frames(10)
	check(fp.visible and fp.kick == k0 and fp.lower == lw, "the view stays put while paused")
	main.show_title(true); await frames(3)
	check(not fp.visible, "first-person view hidden after quitting to the title")
	print("First-person view: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
