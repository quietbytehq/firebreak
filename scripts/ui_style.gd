extends RefCounted
## Shared typography for HUD, menus and story screens. Barlow Condensed is
## bundled under the SIL Open Font License (see LICENSES/OFL-BarlowCondensed.txt).

const FONTS := {
	"regular": "res://assets/fonts/BarlowCondensed-Regular.ttf",
	"medium": "res://assets/fonts/BarlowCondensed-Medium.ttf",
	"semibold": "res://assets/fonts/BarlowCondensed-SemiBold.ttf",
	"bold": "res://assets/fonts/BarlowCondensed-Bold.ttf",
}

static var _cache := {}

static func font(weight: String = "bold") -> Font:
	var key := weight if FONTS.has(weight) else "bold"
	if _cache.has(key):
		return _cache[key]
	var path: String = FONTS[key]
	var f: Font = load(path) if ResourceLoader.exists(path) else ThemeDB.fallback_font
	_cache[key] = f
	return f
