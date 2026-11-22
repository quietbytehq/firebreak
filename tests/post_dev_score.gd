extends SceneTree
## Posts one campaign score to a local wrangler dev server (FIREBREAK_SCORES_URL).
## Used by leaderboard/test_local.sh; not part of the headless suite (no test_ prefix).
const Online := preload("res://scripts/online.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var url := OS.get_environment("FIREBREAK_SCORES_URL")
	if url == "":
		printerr("FIREBREAK_SCORES_URL is not set")
		quit(2)
		return
	var req := HTTPRequest.new()
	req.timeout = 8.0
	root.add_child(req)
	var err := req.request(url, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, Online.body_json("DEVBOT", 3210, 1))
	if err != OK:
		printerr("request failed to start: ", err)
		quit(1)
		return
	var result: Array = await req.request_completed
	var code: int = int(result[1])
	var text := (result[3] as PackedByteArray).get_string_from_utf8()
	print("GAME_POST ", code, " ", text)
	quit(0 if code == 200 and text.contains("\"ok\":true") else 1)
