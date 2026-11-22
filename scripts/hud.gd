extends Node2D
## Heads-up display and crosshair, drawn in screen space (1920x1080).

var sim
var crosshair := Vector2(960, 540)
var stage_name := ""
var run_base := 0   # campaign total from earlier stages in this run
var show_crosshair := true
var t := 0.0
var font: Font
var portrait: Texture2D
var hit_flash := 0.0
var icons := {}
var cash_flash := 0.0
var cash_shown := -1.0
var cash_pops: Array = []   # [{"text", "pos", "t", "good"}]

const Weapons := preload("res://scripts/weapons.gd")
const ICON_DIR := "res://assets/ui/weapons/"
## Bottom weapon bar: three clickable slots (pistol, primary, special).
const SLOT_X := [688.0, 998.0, 1308.0]
const SLOT_Y := 940.0
const SLOT_W := 298.0
const SLOT_H := 122.0
const SLOT_KEYS := ["1", "2", "3"]

static func slot_rect(i: int) -> Rect2:
	return Rect2(SLOT_X[i], SLOT_Y, SLOT_W, SLOT_H)

## Slot under a screen point (0..2), or -1. Clicks there select, never fire.
static func slot_at(pos: Vector2) -> int:
	for i in 3:
		if slot_rect(i).has_point(pos): return i
	return -1

static func icon_for(id: String) -> Texture2D:
	var path := ICON_DIR + id + ".png"
	return load(path) if ResourceLoader.exists(path) else null

func icon(id: String) -> Texture2D:
	if not icons.has(id): icons[id] = icon_for(id)
	return icons[id]

func pop_cash(amount: int, pos: Vector2, good: bool) -> void:
	cash_pops.append({"text": ("+$%d" if good else "-$%d") % amount, "pos": pos, "t": 0.0, "good": good})
	cash_flash = 1.0 if good else -1.0

func _ready() -> void:
	font = ThemeDB.fallback_font
	portrait = load("res://assets/ui/rayan_portrait.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _process(delta: float) -> void:
	t += delta
	hit_flash = maxf(0.0, hit_flash - delta * 3.0)
	cash_flash = move_toward(cash_flash, 0.0, delta * 2.0)
	for p in cash_pops.duplicate():
		p.t += delta
		if p.t > 1.2: cash_pops.erase(p)
	if sim != null:
		cash_shown = float(sim.cash) if cash_shown < 0.0 else move_toward(cash_shown, float(sim.cash), maxf(40.0, absf(float(sim.cash) - cash_shown) * 6.0) * delta)
	queue_redraw()

func text(s: String, pos: Vector2, size: int, col: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string_outline(font, pos, s, align, width, size, 7, Color(0, 0, 0, 0.85))
	draw_string(font, pos, s, align, width, size, col)

func panel(r: Rect2) -> void:
	draw_rect(r, Color(0.04, 0.035, 0.03, 0.62))
	draw_rect(r, Color(1, 0.75, 0.4, 0.25), false, 2.0)

func _draw() -> void:
	if sim == null: return
	# Top bar: score, stage and timer, enemies remaining.
	panel(Rect2(20, 16, 420, 74))
	text("SCORE", Vector2(38, 46), 22, Color(1, 0.8, 0.5))
	text("%07d" % (run_base + sim.score), Vector2(38, 82), 38, Color(1, 1, 1))
	text("CASH", Vector2(250, 46), 22, Color(0.55, 1, 0.55))
	var ccol := Color(0.6, 1, 0.55).lerp(Color(1, 1, 0.6), maxf(0.0, cash_flash)).lerp(Color(1, 0.35, 0.3), maxf(0.0, -cash_flash))
	text(money(int(round(cash_shown))), Vector2(250, 82), 34, ccol)
	panel(Rect2(700, 16, 520, 74))
	text("STAGE %d · %s" % [sim.stage_number, stage_name.to_upper()], Vector2(700, 46), 22, Color(1, 0.8, 0.5), HORIZONTAL_ALIGNMENT_CENTER, 520)
	var left: float = sim.time_left()
	var tcol := Color(1, 1, 1) if left > 20.0 else Color(1, 0.4 + 0.3 * sin(t * 8.0), 0.3)
	text("%d:%02d" % [int(left) / 60, int(left) % 60], Vector2(700, 84), 38, tcol, HORIZONTAL_ALIGNMENT_CENTER, 520)
	panel(Rect2(1480, 16, 420, 74))
	var rem: int = sim.enemies_remaining()
	text("ENEMIES  %d" % rem, Vector2(1498, 46), 22, Color(1, 0.8, 0.5))
	var frac := float(rem) / maxf(1.0, float(sim.quota))
	draw_rect(Rect2(1498, 58, 384, 20), Color(0.15, 0.12, 0.1, 0.9))
	draw_rect(Rect2(1498, 58, 384 * frac, 20), Color(0.85, 0.25, 0.15))
	for i in range(1, 11):
		draw_line(Vector2(1498 + 38.4 * i, 58), Vector2(1498 + 38.4 * i, 78), Color(0, 0, 0, 0.5), 2.0)
	# Bottom left: Rayan's portrait, health and active weapon effects.
	panel(Rect2(20, 940, 640, 122))
	if portrait:
		var pr := Rect2(30, 948, 106, 106)
		var low: float = clampf(1.0 - sim.health / (sim.max_health * 0.3), 0.0, 1.0)
		var red := maxf(hit_flash, low * (0.5 + 0.5 * sin(t * 6.0)) * 0.6)
		draw_texture_rect(portrait, pr, false, Color(1, 1.0 - red * 0.6, 1.0 - red * 0.6))
		draw_rect(pr, Color(1, 0.75, 0.4, 0.8), false, 3.0)
	text("RAYAN", Vector2(152, 978), 24, Color(1, 0.8, 0.5))
	text("HEALTH", Vector2(250, 978), 20, Color(1, 0.8, 0.5))
	var hp: float = sim.health / sim.max_health
	draw_rect(Rect2(152, 994, 490, 32), Color(0.15, 0.12, 0.1, 0.9))
	var hcol := Color(0.35, 0.85, 0.35).lerp(Color(0.95, 0.2, 0.15), 1.0 - hp)
	draw_rect(Rect2(152, 994, 490 * hp, 32), hcol)
	text("%d" % int(ceil(sim.health)), Vector2(152, 1022), 26, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER, 490)
	var fx := []
	if sim.rapid_timer > 0.0: fx.append("RAPID %ds" % int(ceil(sim.rapid_timer)))
	if sim.spread_timer > 0.0: fx.append("SPREAD %ds" % int(ceil(sim.spread_timer)))
	if sim.weapon_level > 1: fx.append("POWER %d" % sim.weapon_level)
	if not fx.is_empty():
		text("  ".join(fx), Vector2(152, 1054), 24, Color(1, 0.85, 0.3))
	draw_weapon_bar()
	if sim.ammo == 0 and sim.slot_empty(1) and sim.slot < 2 and sim.reload_timer <= 0.0 and sim.slot == 1:
		text("PRIMARY EMPTY - PRESS 1 FOR THE PISTOL OR SHOOT AMMO DROPS", Vector2(960, 900), 30, Color(1, 0.4, 0.3), HORIZONTAL_ALIGNMENT_CENTER, 0)
	if show_crosshair:
		draw_crosshair()

func draw_crosshair() -> void:
	var c := crosshair
	var target: Dictionary = sim.entity_at(c) if sim.state == "playing" else {}
	var col := Color(1, 1, 1, 0.95)
	if not target.is_empty():
		col = Color(1, 0.25, 0.2) if target.type in ["rifleman", "mg", "paratrooper", "truck", "heli"] else (Color(0.4, 1, 0.4) if target.type in ["food", "powerup"] else Color(0.4, 0.75, 1))
	var r := 34.0
	draw_arc(c, r, 0, TAU, 40, Color(0, 0, 0, 0.6), 7.0)
	draw_arc(c, r, 0, TAU, 40, col, 3.0)
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(c + d * 14, c + d * 50, Color(0, 0, 0, 0.6), 6.0)
		draw_line(c + d * 14, c + d * 50, col, 2.5)
	draw_circle(c, 3.0, col)
	if sim.reload_timer > 0.0:
		var f: float = 1.0 - sim.reload_timer / maxf(0.05, sim.reload_duration)
		draw_arc(c, r + 10, -PI / 2, -PI / 2 + TAU * f, 40, Color(1, 0.7, 0.3), 5.0)

static func money(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out; s = s.substr(0, s.length() - 3)
	return ("-$" if v < 0 else "$") + s + out

func ammo_text(i: int) -> String:
	var e: Dictionary = sim.loadout[i]
	if i == 2: return "×%d" % sim.special_total()
	return "%d / %s" % [int(e.mag), "∞" if int(e.reserve) < 0 else str(int(e.reserve))]

func draw_weapon_bar() -> void:
	for i in 3:
		var r := slot_rect(i)
		var sel: bool = sim.slot == i
		var e: Dictionary = sim.loadout[i]
		var w: Dictionary = sim.weapon_in(i)
		var empty: bool = sim.slot_empty(i)
		draw_rect(r, Color(0.05, 0.04, 0.03, 0.78 if sel else 0.6))
		if sel:
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			draw_rect(r.grow(3.0), Color(1, 0.72, 0.3, 0.55 + 0.3 * pulse), false, 4.0)
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 5), Color(1, 0.7, 0.25, 0.95))
		else:
			draw_rect(r, Color(1, 0.75, 0.4, 0.25), false, 2.0)
		# Key badge
		draw_rect(Rect2(r.position + Vector2(8, 8), Vector2(28, 28)), Color(1, 0.7, 0.3, 0.9) if sel else Color(0.3, 0.25, 0.2, 0.9))
		text(SLOT_KEYS[i], r.position + Vector2(8, 31), 22, Color(0.1, 0.06, 0.02) if sel else Color(1, 0.9, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 28)
		var ic := icon(str(e.id))
		var area := Rect2(r.position + Vector2(44, 10), Vector2(r.size.x - 54, 62))
		var mod := Color(1, 1, 1, 1.0 if sel else 0.72)
		if empty: mod = Color(0.55, 0.45, 0.4, 0.7)
		if ic:
			var sz := ic.get_size()
			var k := minf(area.size.x / sz.x, area.size.y / sz.y)
			var dsz := sz * k
			draw_texture_rect(ic, Rect2(area.position + (area.size - dsz) * 0.5, dsz), false, mod)
		else:
			draw_rect(Rect2(area.position + Vector2(10, 22), Vector2(area.size.x - 20, 18)), Color(0.5, 0.45, 0.4, mod.a))
		text(str(w.get("name", "")).to_upper(), r.position + Vector2(10, 98), 20, Color(1, 0.85, 0.55) if sel else Color(0.9, 0.8, 0.65))
		var acol := Color(1, 1, 1) if not empty else Color(1, 0.4, 0.3)
		text(ammo_text(i), r.position + Vector2(10, 98), 22, acol, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 20)
		# Magazine strip
		var mag := int(w.get("mag", 1))
		var frac := float(e.mag) / maxf(1.0, float(mag))
		var bar := Rect2(r.position + Vector2(10, 106), Vector2(r.size.x - 20, 8))
		draw_rect(bar, Color(0.2, 0.16, 0.12, 0.9))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(0.95, 0.75, 0.3) if frac > 0.25 else Color(1, 0.4, 0.25))
		if (i < 2 and sel and sim.reload_timer > 0.0) or (i == 2 and sim.special_reload > 0.0):
			var rf: float = (1.0 - sim.reload_timer / maxf(0.05, sim.reload_duration)) if i < 2 else (1.0 - sim.special_reload / maxf(0.05, float(w.get("reload", 1.0))))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * rf, bar.size.y)), Color(0.4, 0.8, 1.0))
			text("RELOADING", r.position + Vector2(0, 60), 26, Color(0.5, 0.85, 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	# Right: air strikes and power effects.
	var rp := Rect2(1618, 940, 282, 122)
	panel(rp)
	var strike_ready: bool = sim.airstrikes > 0 and sim.strike.is_empty()
	var scol := Color(1, 0.55 + 0.25 * sin(t * 5.0), 0.3) if strike_ready else Color(0.75, 0.7, 0.65)
	text("AIR STRIKE ×%d" % sim.airstrikes, Vector2(1632, 978), 26, scol)
	text("E / middle click", Vector2(1632, 1004), 18, Color(0.85, 0.75, 0.6))
	text("SPECIAL: SPACE / RIGHT CLICK", Vector2(1632, 1040), 16, Color(0.85, 0.75, 0.6))
	for p in cash_pops:
		var a: float = clampf(1.4 - p.t, 0.0, 1.0)
		var pos: Vector2 = p.pos + Vector2(0, -60.0 * p.t - 40.0)
		draw_string_outline(font, pos, p.text, HORIZONTAL_ALIGNMENT_CENTER, 0, 30, 6, Color(0, 0, 0, 0.8 * a))
		draw_string(font, pos, p.text, HORIZONTAL_ALIGNMENT_CENTER, 0, 30, Color(0.55, 1, 0.5, a) if p.good else Color(1, 0.35, 0.3, a))
