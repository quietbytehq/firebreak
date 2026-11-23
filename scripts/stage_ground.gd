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
	if type in ["truck", "technical", "convoy"]:
		return "track"
	if type == "camel":
		return "sand_far" if band == "far" else "sand"
	return ""
