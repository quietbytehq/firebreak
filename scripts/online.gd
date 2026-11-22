class_name Online
extends RefCounted
## Posts a qualifying campaign score to the global top 100 at firebreak.quietbytehq.uk.
## Only the typed name, the score, the mode, the game version and the last stage
## reached are sent. It never blocks the game: if there is no internet the post
## is just dropped.

const SITE := "firebreak.quietbytehq.uk"
const URL := "https://firebreak.quietbytehq.uk/api/submit"
const MODE := "campaign"
const MIN_SCORE := 2000
const MAX_STAGES := 12

static func body_json(player: String, score: int, stages: int, version: String = "") -> String:
	if version == "":
		version = str(ProjectSettings.get_setting("application/config/version", ""))
	return JSON.stringify({
		"name": player,
		"score": int(score),
		"mode": MODE,
		"version": version,
		"stages": int(stages),
	})

static func submit(host: Node, player: String, score: int, stages: int, url: String = URL) -> void:
	var req := HTTPRequest.new()
	req.timeout = 8.0
	host.add_child(req)
	req.request_completed.connect(func(_result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		req.queue_free())
	if req.request(url, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, body_json(player, score, stages)) != OK:
		req.queue_free()
