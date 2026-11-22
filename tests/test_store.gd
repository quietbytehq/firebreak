extends SceneTree
## 0.3.0 store: buying, equipping, ammo and air strike purchases, cash checks,
## and repairing a damaged or tampered profile.
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
func run() -> void:
	var p := Weapons.default_profile()
	check(int(p.cash) == 0 and p.owned.size() == 3, "a new profile owns only the starter kit")
	check(Weapons.can_buy(p, "talon_50") == "Not enough cash" and not Weapons.buy(p, "talon_50"), "cannot buy without cash")
	check(Weapons.can_buy(p, "viper_9") == "Owned", "cannot buy an owned weapon")
	p.cash = 5000
	var price := int(Weapons.get_weapon("kalash_47").price)
	check(Weapons.buy(p, "kalash_47"), "buy a rifle")
	check(int(p.cash) == 5000 - price, "price is deducted")
	check(p.owned.has("kalash_47") and p.loadout[1] == "kalash_47", "a bought weapon is equipped in its slot")
	check(p.loadout[0] == "viper_9" and p.loadout[2] == "frag_grenades", "other slots are unchanged")
	check(Weapons.equip(p, "hornet_9") and p.loadout[1] == "hornet_9", "re-equip an owned weapon")
	check(not Weapons.equip(p, "thunder_m60"), "cannot equip a weapon you do not own")
	var k := Weapons.get_weapon("kalash_47")
	var a0 := int(p.ammo.kalash_47.reserve)
	var cash0 := int(p.cash)
	check(Weapons.buy_ammo(p, "kalash_47"), "buy ammo")
	check(int(p.ammo.kalash_47.reserve) == mini(a0 + int(k.ammo_pack), int(k.max_reserve)) and int(p.cash) == cash0 - int(k.ammo_price), "ammo pack added and paid for")
	p.ammo.kalash_47.reserve = int(k.max_reserve)
	check(Weapons.can_buy_ammo(p, "kalash_47") == "Full", "cannot overfill ammo")
	check(Weapons.can_buy_ammo(p, "viper_9") == "Unlimited", "the starter pistol never needs ammo")
	check(Weapons.can_buy_ammo(p, "thunder_m60") == "Not owned", "no ammo for weapons you do not own")
	p.cash = 10
	check(Weapons.can_buy_ammo(p, "hornet_9") == "Not enough cash", "ammo needs cash")
	p.cash = 99999
	check(Weapons.buy(p, "hammer_rpg") and p.loadout[2] == "hammer_rpg", "buying a launcher equips it in slot 3")
	while Weapons.buy_airstrike(p): pass
	check(int(p.airstrikes) == int(Weapons.support().max) and Weapons.can_buy_airstrike(p) == "Full", "air strikes cap at the maximum")
	var q := Weapons.default_profile(); q.cash = 1 << 20
	var bought := 0
	for w in Weapons.all():
		if not q.owned.has(w.id) and Weapons.buy(q, w.id): bought += 1
	check(bought == 16 and q.owned.size() == 19, "all 16 non-starter weapons can be bought")
	var r := Weapons.default_profile(); r.cash = 99999
	Weapons.buy(r, "rook_revolver"); Weapons.buy(r, "granite_g3"); Weapons.buy(r, "tankbuster")
	var sim = fresh(r)
	check(sim.loadout[0].id == "rook_revolver" and sim.loadout[1].id == "granite_g3" and sim.loadout[2].id == "tankbuster", "the stage uses the store loadout")
	check(is_equal_approx(sim.shot_damage(), float(Weapons.get_weapon("granite_g3").damage)), "damage comes from the equipped weapon")
	var bad := {"cash": -50, "owned": ["viper_9", "made_up_gun", "kalash_47"], "loadout": ["kalash_47", "kalash_47", "nope"],
		"ammo": {"kalash_47": {"mag": 999, "reserve": 99999}}, "airstrikes": 42}
	var s := Weapons.sanitize(bad)
	check(int(s.cash) == 0, "negative cash repaired")
	check(not s.owned.has("made_up_gun"), "unknown weapons dropped")
	check(s.loadout[0] == "viper_9" and s.loadout[1] == "kalash_47" and s.loadout[2] == "frag_grenades", "wrong-slot loadout repaired")
	check(int(s.ammo.kalash_47.mag) == int(k.mag) and int(s.ammo.kalash_47.reserve) == int(k.max_reserve), "ammo clamped to the weapon's limits")
	check(int(s.airstrikes) == int(Weapons.support().max), "air strikes clamped")
	check(int(Weapons.load_profile("user://missing_profile.json").cash) == 0, "a missing profile gives the starter kit")
	print("Store: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
