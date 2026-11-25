extends RefCounted
## Per-stage ground and road polylines in panorama (world) pixels.
## A point is [x, y]; a span is [x0, x1]. Y is the feet / wheel contact line.

static func _section(stage: Dictionary, group: String, name: String) -> Dictionary:
	var g: Dictionary = stage.get(group, {})
	var d = g.get(name, {})
	return d if d is Dictionary else {}

static func _points(d: Dictionary) -> Array:
	var pts: Array = d.get("points", [])
	return pts if pts is Array else []

static func _spans(d: Dictionary) -> Array:
	var s: Array = d.get("spans", [])
	return s if s is Array else []

static func interp_y(points: Array, x: float) -> float:
	if points.is_empty():
		return -1.0
	if x <= float(points[0][0]):
		return float(points[0][1])
	for i in range(1, points.size()):
		var a = points[i - 1]
		var b = points[i]
		var bx := float(b[0])
		if x <= bx:
			var ax := float(a[0])
			var t := (x - ax) / maxf(0.0001, bx - ax)
			return lerpf(float(a[1]), float(b[1]), t)
	return float(points[points.size() - 1][1])

static func in_spans(spans: Array, x: float) -> bool:
	if spans.is_empty():
		return true
	for s in spans:
		if x >= float(s[0]) and x <= float(s[1]):
			return true
	return false

static func ground_section(stage: Dictionary, band: String) -> Dictionary:
	return _section(stage, "ground", band)

static func ground_points(stage: Dictionary, band: String) -> Array:
	return _points(ground_section(stage, band))

static func ground_spans(stage: Dictionary, band: String) -> Array:
	var d := ground_section(stage, band)
	var spans := _spans(d)
	if not spans.is_empty():
		return spans
	# Fall back to the older zone x-ranges if a stage has no ground map yet.
	var out: Array = []
	for z in stage.get("bands", {}).get(band, {}).get("zones", []):
		out.append([float(z[0]), float(z[1])])
	return out

static func ground_y(stage: Dictionary, band: String, x: float) -> float:
	var pts := ground_points(stage, band)
	if not pts.is_empty():
		return interp_y(pts, x)
	# Zone fallback: constant y on the matching span.
	for z in stage.get("bands", {}).get(band, {}).get("zones", []):
		if x >= float(z[0]) and x <= float(z[1]):
			return float(z[2])
	var zones: Array = stage.get("bands", {}).get(band, {}).get("zones", [])
	if not zones.is_empty():
		return float(zones[0][2])
	return -1.0

static func on_ground(stage: Dictionary, band: String, x: float) -> bool:
	return in_spans(ground_spans(stage, band), x)

static func road_section(stage: Dictionary, name: String) -> Dictionary:
	return _section(stage, "roads", name)

static func road_points(stage: Dictionary, name: String) -> Array:
	return _points(road_section(stage, name))

static func road_y(stage: Dictionary, name: String, x: float) -> float:
	return interp_y(road_points(stage, name), x)

static func road_bounds(stage: Dictionary, name: String) -> Vector2:
	var pts := road_points(stage, name)
	if pts.is_empty():
		return Vector2(-1, -1)
	return Vector2(float(pts[0][0]), float(pts[pts.size() - 1][0]))

static func on_road(stage: Dictionary, name: String, x: float, slack: float = 8.0) -> bool:
	var b := road_bounds(stage, name)
	if b.x < 0.0:
		return false
	return x >= b.x - slack and x <= b.y + slack

static func dist_to_road(stage: Dictionary, name: String, x: float, y: float) -> float:
	if not on_road(stage, name, x, 80.0):
		return 9999.0
	return absf(y - road_y(stage, name, x))

## Default road used by a moving type, or "" if none.
static func road_for(type: String, band: String = "mid") -> String:
	if type in ["truck", "technical", "convoy", "jeep"]:
		return "track"
	if type == "camel":
		return "sand_far" if band == "far" else "sand"
	if type in ["speedboat", "gunboat"]:
		return "water_far" if band == "far" else "water"
	return ""

## Vertical error between this entity's feet and their contact line, or -1
## if the entity is airborne (heli, falling pickup, descending paratrooper,
## mid-air death) and should not be tested against the ground map.
static func feet_off(stage: Dictionary, e: Dictionary) -> float:
	var tname := str(e.get("type", ""))
	if tname in ["heli", "food", "powerup"]:
		return -1.0
	if tname == "paratrooper" and not e.get("landed", false):
		return -1.0
	var y := float(e.get("y", 0.0))
	var path := str(e.get("path", ""))
	if path != "":
		var ry := road_y(stage, path, float(e.x))
		if ry < 0.0:
			return -1.0
		return absf(y - ry)
	if e.get("wading", false):
		var wy := water_y(stage, float(e.x), str(e.get("band", "mid")))
		if wy < 0.0:
			return -1.0
		return absf(y - wy)
	if e.get("planted", false):
		return absf(y - float(e.get("ground_y", y)))
	var gy := ground_y(stage, str(e.get("band", "mid")), float(e.x))
	if gy < 0.0:
		return -1.0
	return absf(y - gy)

## Allowed feet error in pixels. Camels bob a few pixels on their stride.
static func feet_slack(e: Dictionary) -> float:
	var tname := str(e.get("type", ""))
	if tname == "camel":
		return 3.0 * float(e.get("scale", 1.0)) + 2.0
	if tname in ["speedboat", "gunboat"]:
		return 16.0
	if e.get("wading", false):
		return 10.0
	return 5.0

## Optional water body. A ground figure is in the water when its x is inside
## a water span for its band and not on that band's land.
static func water_section(stage: Dictionary) -> Dictionary:
	var d = stage.get("water", {})
	return d if d is Dictionary else {}

static func water_band_section(stage: Dictionary, band: String) -> Dictionary:
	var bands = water_section(stage).get("bands", {})
	if bands is Dictionary:
		var d = bands.get(band, {})
		return d if d is Dictionary else {}
	return {}

static func water_spans(stage: Dictionary, band: String = "") -> Array:
	if band != "":
		var local := _spans(water_band_section(stage, band))
		if not local.is_empty():
			return local
	return _spans(water_section(stage))

static func water_y(stage: Dictionary, x: float, band: String = "mid") -> float:
	var local_pts := _points(water_band_section(stage, band))
	if not local_pts.is_empty():
		return interp_y(local_pts, x)
	var pts := _points(water_section(stage))
	if pts.is_empty():
		return -1.0
	return interp_y(pts, x)

static func has_water(stage: Dictionary) -> bool:
	return not water_spans(stage).is_empty() or not _points(water_section(stage)).is_empty()

## Boats, vehicles, pickups and pier crews are never "wading" infantry.
const DRY_TYPES := ["speedboat", "gunboat", "heli", "food", "powerup", "truck", "technical", "convoy", "jeep", "camel", "pier_gunner", "grenadier"]

static func in_water(stage: Dictionary, band: String, x: float, type: String = "") -> bool:
	if type in DRY_TYPES:
		return false
	if not in_spans(water_spans(stage, band), x):
		return false
	if on_ground(stage, band, x):
		return false
	return water_y(stage, x, band) > 0.0

## True when a civilian may stand or walk here: on land, never in water.
static func on_land(stage: Dictionary, band: String, x: float) -> bool:
	return on_ground(stage, band, x) and not in_water(stage, band, x, "villager")

## True when a ground figure at (band, x) has water under its feet, or
## immediately behind them (a near parapet with only sea behind, for
## example). Boat crews and other DRY_TYPES always return false.
##
## A farther water body does not count by itself: Dune Sea's oasis sits
## behind a near sand bank, so near figures there stay dry. A per-band
## water map (water.bands.near / mid) is the shore for that band.
static func water_under_or_behind(stage: Dictionary, band: String, x: float, type: String = "") -> bool:
	if type in DRY_TYPES:
		return false
	if in_water(stage, band, x, type):
		return true
	var local := _spans(water_band_section(stage, band))
	if local.is_empty():
		return false
	return in_spans(local, x) and water_y(stage, x, band) > 0.0
