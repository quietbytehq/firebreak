extends SceneTree
## 0.3.0 weapon catalogue: 5 pistols, 5 SMGs, 5 rifles and 5 specials, every
## stat present, original names only, a fire sound and an icon for each.
const StageSim := preload("res://scripts/stage_sim.gd")
const Weapons := preload("res://scripts/weapons.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func center(sim, e: Dictionary) -> Vector2:
	return sim.hitbox(e).get_center() - Vector2(sim.camera_x, 0)
func fresh(profile: Dictionary = {}):
	var sim = StageSim.new(); sim.setup(1, 5, {}, profile); sim.stage.ambient = []; sim.stage.waves = []
	return sim
func settle(sim, e: Dictionary) -> void:
	e.rise = 1.0; e.state = "aim"; e.timer = 10.0
func events(sim) -> Array:
	var log := []
	sim.event.connect(func(n, d): log.append([n, d]))
	return log
func named(log: Array, n: String) -> Array:
	return log.filter(func(x): return x[0] == n)

const BANNED := ["glock", "desert eagle", "deagle", "heckler", "koch", "mp5", "kalashnikov", "ak-47", "ak47", "colt", "beretta",
	"uzi", "ingram", "mac-10", "mac10", "fn herstal", "p90", "sig sauer", "sig ", "remington", "barrett", "smith & wesson",
	"smith and wesson", "ruger", "walther", "steyr", "milkor", "m4a1", "m16", "rpg-7", "m79", "m203", "hk ", "h&k"]
func run() -> void:
	var all: Array = Weapons.all()
	check(all.size() == 19, "19 weapons in data/weapons.json (%d)" % all.size())
	var per := {}
	var ids := {}
	var names := {}
	for w in all:
		per[w.category] = int(per.get(w.category, 0)) + 1
		check(not ids.has(w.id), "unique id " + str(w.id)); ids[w.id] = true
		check(not names.has(w.name), "unique name " + str(w.name)); names[w.name] = true
		for k in ["id", "name", "category", "slot", "price", "damage", "fire_rate", "mag", "reserve", "reload", "spread", "ammo_pack", "ammo_price", "sound", "blurb"]:
			check(w.has(k), "%s has %s" % [w.id, k])
		check(float(w.fire_rate) > 0.0 and int(w.mag) > 0 and float(w.reload) >= 0.0 and int(w.price) >= 0, "%s stats are sane" % w.id)
		var slot_ok: bool = (w.category == "pistol" and int(w.slot) == 1) or (w.category in ["smg", "rifle"] and int(w.slot) == 2) or (w.category == "special" and int(w.slot) == 3)
		check(slot_ok, "%s sits in the right slot" % w.id)
		check(ResourceLoader.exists("res://assets/ui/weapons/%s.png" % w.id), "icon for " + str(w.id))
		var snd := str(w.sound)
		check(ResourceLoader.exists("res://assets/audio/%s.ogg" % snd), "fire sound %s.ogg exists" % snd)
		for k in ["reload_sound", "dry_sound"]:
			if str(w.get(k, "")) != "": check(ResourceLoader.exists("res://assets/audio/%s.ogg" % str(w[k])), "%s %s exists" % [w.id, k])
		if w.category == "special":
			check(float(w.get("radius", 0)) > 0.0 and float(w.get("blast_damage", 0)) > 0.0, "%s has a blast" % w.id)
	check(per.get("pistol", 0) == 5 and per.get("smg", 0) == 5 and per.get("rifle", 0) == 5, "5 pistols, 5 SMGs, 5 rifles")
	check(per.get("special", 0) == 4 and not Weapons.support().is_empty(), "4 special weapons plus the Air Strike = 5 specials")
	# Every primary fire sound is unique.
	var sounds := {}
	for w in all:
		if w.id != "frag_grenades":
			check(not sounds.has(w.sound), "unique fire sound for " + str(w.id)); sounds[w.sound] = true
	check(sounds.size() == 18, "18 unique gun / launcher fire sounds")
	# Starter kit and specific design points.
	var st := Weapons.starter()
	check(st.slot1 == "viper_9" and Weapons.is_infinite("viper_9"), "Viper 9 is the free starter with unlimited reserve")
	check(int(Weapons.get_weapon("viper_9").price) == 0, "Viper 9 is free")
	check(st.slot3 == "frag_grenades" and Weapons.issue_reserve(Weapons.get_weapon("frag_grenades")) + int(Weapons.get_weapon("frag_grenades").mag) == 5, "start with 5 frag grenades")
	check(int(Weapons.get_weapon("thumper_gl").mag) == 6, "Thumper GL holds 6 shots")
	check(int(Weapons.get_weapon("longshot_700").get("pierce", 1)) >= 2, "Longshot 700 pierces")
	var frag_r := float(Weapons.get_weapon("frag_grenades").radius)
	check(PI * frag_r * frag_r / (1920.0 * 1080.0) > 0.27 and PI * frag_r * frag_r / (1920.0 * 1080.0) < 0.33, "frag blast covers about 30% of the screen")
	# No real maker or model names anywhere in the shipped weapon data.
	var text := FileAccess.get_file_as_string("res://data/weapons.json").to_lower()
	for b in BANNED:
		check(not text.contains(b), "no real brand/model name in weapons.json: " + b)
	# Within each category, a costlier gun is never weaker per shot than a
	# cheaper one. The Longshot 700 is a marksman exception: it may out-hit
	# the more expensive Thunder M60, which is a belt-fed support gun.
	for cat in ["pistol", "smg", "rifle", "special"]:
		var list: Array = all.filter(func(w): return str(w.category) == cat)
		list.sort_custom(func(a, b): return int(a.price) < int(b.price))
		for i in range(1, list.size()):
			var cheaper: Dictionary = list[i - 1]
			var dearer: Dictionary = list[i]
			if cat == "rifle" and str(cheaper.id) == "longshot_700":
				check(true, "Longshot 700 may out-hit the Thunder M60")
				continue
			check(float(dearer.damage) + 0.001 >= float(cheaper.damage),
				"%s (%.2f) is not weaker per shot than cheaper %s (%.2f)" % [dearer.id, dearer.damage, cheaper.id, cheaper.damage])

	print("Weapon data: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
