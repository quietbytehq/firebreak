extends RefCounted
## Procedural PLACEHOLDER art for Firebreak 0.1.0. Every figure is drawn from
## simple shapes so the game is fully playable before final sprites exist.
## Final art prompts are in ART_PROMPTS.md. Feet are at the origin, +x faces
## forward, sizes are in pixels at scale 1.0. Generic uniforms, no insignia.

const OLIVE := Color(0.31, 0.34, 0.2)
const OLIVE_DARK := Color(0.2, 0.22, 0.13)
const OLIVE_LIGHT := Color(0.42, 0.44, 0.27)
const SKIN := Color(0.66, 0.5, 0.37)
const SKIN_SHADE := Color(0.5, 0.36, 0.26)
const BOOT := Color(0.12, 0.1, 0.08)
const STEEL := Color(0.13, 0.13, 0.14)
const WOOD := Color(0.42, 0.26, 0.14)
const SAND := Color(0.6, 0.5, 0.34)
const SAND_DARK := Color(0.42, 0.34, 0.22)
const STRAW := Color(0.84, 0.72, 0.46)
const RIM := Color(1.0, 0.62, 0.28, 0.55)
const CLOTH := [Color(0.86, 0.83, 0.74), Color(0.3, 0.36, 0.52), Color(0.48, 0.36, 0.26), Color(0.7, 0.66, 0.55)]

static var flash := 0.0
static var alpha := 1.0
static var silhouette := false
static var tint := Color(1, 1, 1)
static var haze_color := Color(0.8, 0.56, 0.4)
static var haze := 0.0

static func c(col: Color) -> Color:
	if silhouette:
		return Color(0.04, 0.025, 0.015, 0.75 * alpha)
	var out := Color(col.r * tint.r, col.g * tint.g, col.b * tint.b, col.a)
	out = out.lerp(Color(haze_color, col.a), haze)
	out = out.lerp(Color(1, 1, 1), flash * 0.85)
	out.a *= alpha
	return out

static func ellipse(center: Vector2, rx: float, ry: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(pts), c(col))

static func limb(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var d := (b - a).normalized().orthogonal() * w * 0.5
	ci.draw_colored_polygon(PackedVector2Array([a + d, b + d * 0.85, b - d * 0.85, a - d]), c(col))
	ci.draw_circle(b, w * 0.42, c(col))

static func shadow(ci: CanvasItem, w: float) -> void:
	if silhouette: return
	ci.draw_colored_polygon(ellipse(Vector2.ZERO, w, w * 0.16), Color(0, 0, 0, 0.32 * alpha))

static func begin(ci: CanvasItem, pos: Vector2, s: float, facing: float, rot: float = 0.0, fl: float = 0.0, al: float = 1.0) -> void:
	flash = fl; alpha = al
	ci.draw_set_transform(pos, rot, Vector2(s * facing, s))

static func end(ci: CanvasItem) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	flash = 0.0; alpha = 1.0; silhouette = false

static func muzzle_flash(ci: CanvasItem, at: Vector2, size: float) -> void:
	if silhouette: return
	ci.draw_circle(at, size * 1.3, Color(1, 0.75, 0.3, 0.35 * alpha))
	var pts := []
	for i in 10:
		var a := TAU * i / 10.0
		var r := size if i % 2 == 0 else size * 0.4
		pts.append(at + Vector2(cos(a) * r * 1.5, sin(a) * r))
	ci.draw_colored_polygon(PackedVector2Array(pts), Color(1, 0.9, 0.55, alpha))
	ci.draw_circle(at, size * 0.35, Color(1, 1, 0.9, alpha))

static func warn_ring(ci: CanvasItem, at: Vector2, amount: float, t: float) -> void:
	if amount <= 0.0 or silhouette: return
	var pulse := 0.5 + 0.5 * sin(t * 30.0)
	ci.draw_arc(at, 46.0 + 8.0 * pulse, 0, TAU, 32, Color(1, 0.15, 0.08, (0.45 + 0.5 * pulse) * amount * alpha), 6.0)
	ci.draw_circle(at, 7.0, Color(1, 0.95, 0.7, amount * pulse * alpha))

static func head(ci: CanvasItem, at: Vector2, variant: int) -> void:
	ci.draw_rect(Rect2(at.x - 10, at.y + 14, 20, 22), c(SKIN_SHADE))
	ci.draw_circle(at, 25.0, c(SKIN))
	ci.draw_circle(at + Vector2(9, 4), 13.0, c(SKIN_SHADE.lerp(SKIN, 0.5)))
	ci.draw_circle(at + Vector2(12, -2), 3.0, c(Color(0.1, 0.07, 0.05)))
	if variant % 2 == 0:
		# Steel helmet with plain cloth cover (no markings).
		var dome := []
		for i in 13:
			var a := PI + PI * i / 12.0
			dome.append(at + Vector2(cos(a) * 36.0, sin(a) * 34.0 - 4.0))
		poly(ci, dome, OLIVE_DARK)
		poly(ci, [at + Vector2(-42, -4), at + Vector2(42, -4), at + Vector2(38, 4), at + Vector2(-38, 4)], OLIVE_DARK.darkened(0.2))
		ci.draw_line(at + Vector2(-30, -20), at + Vector2(28, -24), c(OLIVE.darkened(0.1)), 3.0)
	else:
		# Soft bush hat.
		poly(ci, [at + Vector2(-48, -6), at + Vector2(48, -6), at + Vector2(40, 2), at + Vector2(-40, 2)], OLIVE_LIGHT.darkened(0.25))
		poly(ci, [at + Vector2(-27, -6), at + Vector2(-22, -34), at + Vector2(22, -34), at + Vector2(27, -6)], OLIVE_LIGHT.darkened(0.15))

static func rifle(ci: CanvasItem, grip: Vector2, angle: float, length: float = 170.0) -> Vector2:
	var dir := Vector2.from_angle(angle)
	var n := dir.orthogonal()
	var muzzle := grip + dir * length * 0.75
	var butt := grip - dir * length * 0.25
	ci.draw_colored_polygon(PackedVector2Array([butt + n * 9, grip + n * 6, grip - n * 6, butt - n * 12]), c(WOOD))
	ci.draw_colored_polygon(PackedVector2Array([grip + n * 6, muzzle + n * 3, muzzle - n * 3, grip - n * 7]), c(STEEL))
	ci.draw_colored_polygon(PackedVector2Array([grip + dir * 20 - n * 6, grip + dir * 34 - n * 6, grip + dir * 30 - n * 26, grip + dir * 18 - n * 26]), c(STEEL))
	ci.draw_colored_polygon(PackedVector2Array([grip + dir * 46 + n * 5, grip + dir * 96 + n * 4, grip + dir * 96 - n * 6, grip + dir * 46 - n * 7]), c(WOOD.darkened(0.15)))
	return muzzle

## Standing soldier. pose: "aim" (rifle at shoulder) or "ready" (held across).
static func soldier(ci: CanvasItem, pose: String, variant: int, t: float, muzzle: float, warn: float, legs: bool = true) -> Vector2:
	if legs:
		shadow(ci, 70)
		limb(ci, Vector2(-22, -180), Vector2(-30, -20), 34, OLIVE_DARK)
		limb(ci, Vector2(22, -180), Vector2(30, -20), 34, OLIVE_DARK.darkened(0.1))
		ci.draw_rect(Rect2(-54, -24, 44, 24), c(BOOT)); ci.draw_rect(Rect2(12, -24, 44, 24), c(BOOT))
	poly(ci, [Vector2(-46, -298), Vector2(44, -298), Vector2(40, -172), Vector2(-42, -172)], OLIVE)
	poly(ci, [Vector2(14, -298), Vector2(44, -298), Vector2(40, -172), Vector2(18, -172)], OLIVE.darkened(0.15))
	ci.draw_rect(Rect2(-44, -192, 86, 16), c(OLIVE_DARK.darkened(0.3)))
	ci.draw_rect(Rect2(-30, -205, 18, 22), c(OLIVE_DARK)); ci.draw_rect(Rect2(12, -205, 18, 22), c(OLIVE_DARK))
	ci.draw_line(Vector2(-34, -296), Vector2(-24, -192), c(OLIVE_DARK), 6.0)
	ci.draw_line(Vector2(30, -296), Vector2(22, -192), c(OLIVE_DARK), 6.0)
	if not silhouette:
		ci.draw_line(Vector2(-46, -296), Vector2(-42, -174), Color(RIM, RIM.a * alpha * (1.0 - haze)), 4.0)
		ci.draw_line(Vector2(-46, -298), Vector2(14, -298), Color(RIM, RIM.a * alpha * (1.0 - haze)), 3.0)
	var bob := sin(t * 2.0) * 2.0
	var hd := Vector2(4, -326 + bob)
	var muz: Vector2
	if pose == "aim":
		limb(ci, Vector2(-36, -286), Vector2(30, -262), 24, OLIVE)
		head(ci, hd, variant)
		muz = rifle(ci, Vector2(20, -258), -0.05, 220.0)
		limb(ci, Vector2(36, -286), Vector2(70, -250), 24, OLIVE.darkened(0.1))
		limb(ci, Vector2(70, -250), Vector2(96, -262), 20, OLIVE.darkened(0.1))
		ci.draw_circle(Vector2(98, -262), 10, c(SKIN))
	else:
		head(ci, hd, variant)
		limb(ci, Vector2(-38, -286), Vector2(-30, -205), 24, OLIVE)
		muz = rifle(ci, Vector2(-10, -215), -0.75, 190.0)
		limb(ci, Vector2(38, -286), Vector2(30, -250), 24, OLIVE.darkened(0.1))
		ci.draw_circle(Vector2(30, -250), 10, c(SKIN))
	if muzzle > 0.0: muzzle_flash(ci, muz + Vector2(14, 0), 26.0)
	warn_ring(ci, muz, warn, t)
	return muz

static func parachute(ci: CanvasItem, top: Vector2, sway: float, collapse: float = 0.0) -> void:
	var r := 150.0
	var pts := []
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(top + Vector2(cos(a) * r, sin(a) * r * (0.62 - collapse * 0.4) + collapse * 120.0))
	var shade := Color(0.55, 0.53, 0.4)
	ci.draw_colored_polygon(PackedVector2Array(pts), c(shade))
	for i in range(0, 16, 2):
		var seg := [top, pts[i], pts[i + 1]]
		ci.draw_colored_polygon(PackedVector2Array(seg), c(shade.darkened(0.18)))
	for i in [0, 4, 8, 12, 16]:
		ci.draw_line(pts[i], Vector2(-26 + i * 3.2, -300) + Vector2(sway, 0), c(Color(0.85, 0.82, 0.7, 0.8)), 2.0)

static func paratrooper(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var warn := 0.0
	if e.state == "descend":
		var sway: float = sin(t * 1.4 + e.id) * 8.0
		parachute(ci, Vector2(sway, -560), sway)
		limb(ci, Vector2(-20, -180), Vector2(-24, -40), 30, OLIVE_DARK)
		limb(ci, Vector2(20, -180), Vector2(18, -30), 30, OLIVE_DARK.darkened(0.1))
		ci.draw_rect(Rect2(-40, -46, 34, 22), c(BOOT)); ci.draw_rect(Rect2(4, -36, 34, 22), c(BOOT))
		soldier(ci, "aim" if e.muzzle > 0.0 or e.timer < 0.6 else "ready", e.variant, t, e.muzzle, clampf(1.0 - e.timer / 0.6, 0.0, 1.0) if e.timer < 0.6 else 0.0, false)
	else:
		var since: float = e.age - e.get("landed_at", e.age)
		if e.age < 9999.0 and e.get("landed", false):
			var col := clampf(1.0 - since / 2.0, 0.0, 1.0)
			if col > 0.0:
				var keep := alpha; alpha = keep * col
				parachute(ci, Vector2(-150, -120), 0.0, 1.0)
				alpha = keep
		rifleman(ci, e, t)

static func rifleman(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var warn := 0.0
	if e.state == "aim" and e.timer < 0.6:
		warn = clampf(1.0 - e.timer / 0.6, 0.0, 1.0)
	var pose := "aim" if e.state in ["aim", "recover"] else "ready"
	soldier(ci, pose, e.variant, t + e.id, e.muzzle, warn)

static func mg_nest(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var warn := 0.0
	if e.state == "aim" and e.timer < 0.7: warn = clampf(1.0 - e.timer / 0.7, 0.0, 1.0)
	shadow(ci, 130)
	# Seated gunner behind the gun.
	poly(ci, [Vector2(-70, -205), Vector2(0, -205), Vector2(4, -110), Vector2(-74, -110)], OLIVE)
	head(ci, Vector2(-30, -232), e.variant)
	limb(ci, Vector2(-20, -190), Vector2(40, -150), 22, OLIVE.darkened(0.1))
	# Machine gun on a low tripod, barrel over the sandbags.
	var recoil := 4.0 * sin(t * 70.0) if e.state == "burst" else 0.0
	ci.draw_rect(Rect2(-6 + recoil, -170, 90, 26), c(STEEL))
	ci.draw_rect(Rect2(80 + recoil, -164, 110, 10), c(STEEL.lightened(0.05)))
	ci.draw_rect(Rect2(150 + recoil, -170, 18, 22), c(STEEL))
	ci.draw_line(Vector2(40, -146), Vector2(10, -105), c(STEEL), 6.0)
	ci.draw_line(Vector2(40, -146), Vector2(80, -105), c(STEEL), 6.0)
	for i in 6:
		ci.draw_circle(Vector2(10 + i * 9, -140 + i * 7), 4.0, c(Color(0.75, 0.6, 0.25)))
	if e.muzzle > 0.0: muzzle_flash(ci, Vector2(200 + recoil, -159), 30.0)
	warn_ring(ci, Vector2(196, -159), warn, t)
	sandbags(ci, 230.0, 3)

static func sandbags(ci: CanvasItem, width: float, rows: int) -> void:
	for r in rows:
		var y := -18.0 - r * 30.0
		var n := int(width / 56.0) - r
		var start := -width * 0.5 + r * 26.0
		for i in n:
			var cx := start + 28.0 + i * 56.0
			ci.draw_colored_polygon(ellipse(Vector2(cx, y), 31.0, 17.0), c(SAND_DARK))
			ci.draw_colored_polygon(ellipse(Vector2(cx - 2, y - 3), 27.0, 13.0), c(SAND))
			ci.draw_line(Vector2(cx - 18, y - 10), Vector2(cx + 14, y - 12), c(SAND.lightened(0.15)), 2.0)

static func villager(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var cloth: Color = CLOTH[e.variant % CLOTH.size()]
	var trousers := Color(0.22, 0.2, 0.18) if e.variant % 2 == 0 else Color(0.78, 0.75, 0.66)
	var swing := sin(t * 6.5 + e.id) * 0.35
	shadow(ci, 60)
	limb(ci, Vector2(-10, -170), Vector2(-10, -170) + Vector2(sin(swing), cos(swing)) * 160, 26, trousers)
	limb(ci, Vector2(10, -170), Vector2(10, -170) + Vector2(sin(-swing), cos(-swing)) * 160, 26, trousers.darkened(0.1))
	ci.draw_circle(Vector2(-10, -170) + Vector2(sin(swing), cos(swing)) * 166, 10, c(SKIN_SHADE))
	ci.draw_circle(Vector2(10, -170) + Vector2(sin(-swing), cos(-swing)) * 166, 10, c(SKIN_SHADE))
	poly(ci, [Vector2(-40, -290), Vector2(40, -290), Vector2(46, -150), Vector2(-46, -150)], cloth)
	poly(ci, [Vector2(12, -290), Vector2(40, -290), Vector2(46, -150), Vector2(16, -150)], cloth.darkened(0.12))
	ci.draw_rect(Rect2(-8, -310, 16, 24), c(SKIN_SHADE))
	ci.draw_circle(Vector2(2, -322), 22, c(SKIN))
	# Woven conical straw hat.
	poly(ci, [Vector2(-74, -318), Vector2(74, -318), Vector2(0, -372)], STRAW)
	poly(ci, [Vector2(0, -372), Vector2(74, -318), Vector2(20, -318)], STRAW.darkened(0.12))
	ci.draw_line(Vector2(-60, -324), Vector2(60, -324), c(STRAW.darkened(0.25)), 2.0)
	if e.variant % 2 == 0:
		# Shoulder pole with two baskets.
		ci.draw_line(Vector2(-110, -292), Vector2(110, -300), c(WOOD), 7.0)
		for sx in [-100.0, 100.0]:
			ci.draw_line(Vector2(sx, -296), Vector2(sx - 22, -200), c(Color(0.6, 0.5, 0.3)), 2.0)
			ci.draw_line(Vector2(sx, -296), Vector2(sx + 22, -200), c(Color(0.6, 0.5, 0.3)), 2.0)
			poly(ci, [Vector2(sx - 34, -200), Vector2(sx + 34, -200), Vector2(sx + 26, -150), Vector2(sx - 26, -150)], Color(0.58, 0.44, 0.24))
			ci.draw_circle(Vector2(sx, -205), 16, c(Color(0.36, 0.55, 0.2)))
		limb(ci, Vector2(30, -280), Vector2(60, -296), 18, cloth)
	else:
		limb(ci, Vector2(-34, -280), Vector2(-40, -190), 18, cloth)
		limb(ci, Vector2(34, -280), Vector2(44, -195), 18, cloth.darkened(0.1))
		poly(ci, [Vector2(-60, -300), Vector2(-28, -300), Vector2(-24, -200), Vector2(-66, -210)], Color(0.55, 0.45, 0.3))

static func truck(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var warn := 0.0
	if e.state == "aim" and e.timer < 0.7: warn = clampf(1.0 - e.timer / 0.7, 0.0, 1.0)
	var bounce := sin(t * 14.0) * 2.0 if e.state == "drive" else 0.0
	shadow(ci, 300)
	var col := Color(0.3, 0.33, 0.21)
	poly(ci, [Vector2(-280, -70 + bounce), Vector2(120, -70 + bounce), Vector2(120, -110 + bounce), Vector2(-280, -110 + bounce)], col.darkened(0.25))
	poly(ci, [Vector2(-280, -110 + bounce), Vector2(100, -110 + bounce), Vector2(90, -250 + bounce), Vector2(-270, -250 + bounce)], Color(0.38, 0.37, 0.25))
	for i in 5:
		ci.draw_line(Vector2(-250 + i * 80, -250 + bounce), Vector2(-250 + i * 80, -112 + bounce), c(Color(0.3, 0.29, 0.19)), 4.0)
	poly(ci, [Vector2(110, -70 + bounce), Vector2(275, -70 + bounce), Vector2(275, -140 + bounce), Vector2(200, -150 + bounce), Vector2(190, -235 + bounce), Vector2(110, -235 + bounce)], col)
	poly(ci, [Vector2(125, -215 + bounce), Vector2(182, -215 + bounce), Vector2(190, -160 + bounce), Vector2(125, -160 + bounce)], Color(0.12, 0.15, 0.16))
	ci.draw_rect(Rect2(262, -128 + bounce, 14, 16), c(Color(0.95, 0.85, 0.55)))
	for wx in [-200.0, -110.0, 200.0]:
		ci.draw_circle(Vector2(wx, -44), 44, c(Color(0.08, 0.08, 0.08)))
		ci.draw_circle(Vector2(wx, -44), 20, c(Color(0.3, 0.3, 0.28)))
		ci.draw_line(Vector2(wx, -44), Vector2(wx, -44) + Vector2.from_angle(t * 6.0 * (1.0 if e.state == "drive" else 0.0)) * 18, c(Color(0.15, 0.15, 0.15)), 4.0)
	var muz := Vector2(200, -186 + bounce)
	if e.muzzle > 0.0: muzzle_flash(ci, muz + Vector2(10, 0), 28.0)
	warn_ring(ci, muz, warn, t)

static func label(ci: CanvasItem, text: String, at: Vector2, size: int, col: Color) -> void:
	if silhouette: return
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string_outline(font, at - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0, 0, 0, 0.85 * alpha))
	ci.draw_string(font, at - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col, col.a * alpha))

## Food and power-up drops, centred on the origin.
static func pickup(ci: CanvasItem, e: Dictionary, t: float) -> void:
	var is_food: bool = e.type == "food"
	var glow := Color(0.4, 1.0, 0.45) if is_food else Color(1.0, 0.82, 0.25)
	var pulse := 0.5 + 0.5 * sin(t * 6.0 + e.id)
	if e.state == "fall":
		var sway := sin(t * 1.3 + e.id) * 6.0
		var top := Vector2(sway, -112)
		var dome := []
		for i in 13:
			var a := PI + PI * i / 12.0
			dome.append(top + Vector2(cos(a) * 58, sin(a) * 34))
		poly(ci, dome, Color(0.93, 0.9, 0.82))
		for i in [0, 6, 12]:
			ci.draw_line(dome[i], Vector2(-20 + i * 3.3, -40), c(Color(0.9, 0.88, 0.8, 0.8)), 2.0)
	if silhouette: return
	ci.draw_arc(Vector2.ZERO, 58 + pulse * 6, 0, TAU, 32, Color(glow, (0.35 + 0.4 * pulse) * alpha), 5.0)
	var txt := ""
	match e.kind:
		"rice":
			poly(ci, [Vector2(-30, -38), Vector2(30, -38), Vector2(40, 36), Vector2(-40, 36)], Color(0.86, 0.79, 0.6))
			ci.draw_rect(Rect2(-36, -4, 72, 14), c(Color(0.25, 0.5, 0.28)))
			poly(ci, [Vector2(-30, -38), Vector2(30, -38), Vector2(16, -50), Vector2(-16, -50)], Color(0.76, 0.69, 0.5))
			txt = "RICE"
		"fruit":
			poly(ci, [Vector2(-44, -6), Vector2(44, -6), Vector2(34, 36), Vector2(-34, 36)], Color(0.52, 0.36, 0.18))
			ci.draw_circle(Vector2(-18, -14), 16, c(Color(0.95, 0.55, 0.12)))
			ci.draw_circle(Vector2(14, -16), 15, c(Color(0.85, 0.2, 0.15)))
			poly(ci, [Vector2(-10, -30), Vector2(30, -46), Vector2(40, -36), Vector2(0, -20)], Color(0.98, 0.85, 0.25))
			txt = "FRUIT"
		"canteen":
			ci.draw_colored_polygon(ellipse(Vector2(0, 6), 30, 36), c(OLIVE))
			ci.draw_rect(Rect2(-9, -44, 18, 16), c(STEEL))
			ci.draw_line(Vector2(-30, -10), Vector2(30, -10), c(OLIVE_DARK), 4.0)
			txt = "WATER"
		"ration":
			ci.draw_rect(Rect2(-32, -34, 64, 70), c(Color(0.6, 0.62, 0.6)))
			ci.draw_rect(Rect2(-32, -12, 64, 26), c(Color(0.85, 0.5, 0.18)))
			ci.draw_rect(Rect2(-34, -38, 68, 8), c(Color(0.45, 0.46, 0.45)))
			txt = "RATION"
		"ammo":
			ci.draw_rect(Rect2(-46, -30, 92, 62), c(OLIVE))
			ci.draw_rect(Rect2(-46, -30, 92, 10), c(OLIVE_DARK))
			ci.draw_rect(Rect2(-20, -40, 40, 10), c(STEEL))
			txt = "AMMO"
		"grenade":
			ci.draw_colored_polygon(ellipse(Vector2(0, 6), 26, 34), c(OLIVE_DARK))
			for i in 3: ci.draw_line(Vector2(-24, -8 + i * 14), Vector2(24, -8 + i * 14), c(OLIVE_DARK.darkened(0.3)), 2.0)
			ci.draw_rect(Rect2(-10, -40, 20, 14), c(STEEL))
			ci.draw_line(Vector2(8, -36), Vector2(26, -6), c(STEEL), 5.0)
			txt = "GRENADES"
		"rapid":
			poly(ci, [Vector2(-10, -44), Vector2(22, -44), Vector2(6, -6), Vector2(28, -6), Vector2(-16, 44), Vector2(-4, 4), Vector2(-26, 4)], Color(1.0, 0.6, 0.15))
			txt = "RAPID"
		"spread":
			for a in [-0.45, 0.0, 0.45]:
				var d := Vector2.from_angle(-PI / 2 + a)
				ci.draw_line(Vector2(0, 34), Vector2(0, 34) + d * 70, c(Color(1.0, 0.85, 0.3)), 9.0)
			txt = "SPREAD"
		"power":
			var star := []
			for i in 10:
				var a := -PI / 2 + TAU * i / 10.0
				star.append(Vector2(cos(a), sin(a)) * (44.0 if i % 2 == 0 else 19.0))
			poly(ci, star, Color(1.0, 0.85, 0.2))
			txt = "POWER"
	label(ci, txt, Vector2(0, 70), 26, Color(1, 1, 1))
