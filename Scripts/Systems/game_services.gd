extends Node
## Persistent settings, progress, localized UI text and audio for the game shell.

signal language_changed
signal achievement_unlocked(id: String)
signal save_failed
signal game_event(kind: String)

const SAVE_PATH := "user://cube_save.json"
const LANGUAGES := {"en": "English", "es": "Español", "fr": "Français", "de": "Deutsch", "it": "Italiano", "ja": "日本語"}
const ACHIEVEMENTS := ["welcome", "shot", "slash", "hit"]
const DEFAULT_SETTINGS := {"master": 0.8, "music": 0.25, "sfx": 0.65, "fullscreen": false, "language": "en"}

var save_path := SAVE_PATH
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var unlocked: Array = []
var session: Dictionary = {}
var stats := {"shots": 0, "slashes": 0, "hits": 0}
var rng := RandomNumberGenerator.new()
var load_warning := false
var _texts: Dictionary = {}
var _save_timer: Timer
var _music: AudioStreamPlayer
var _effects: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}
var _voice := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_texts = JSON.parse_string(FileAccess.get_file_as_string("res://Localization/ui.json"))
	_load_save()
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.5
	_save_timer.timeout.connect(save_now)
	add_child(_save_timer)
	for sound in ["click", "shoot", "slash", "hit", "achievement"]:
		_sounds[sound] = load("res://assets/audio/%s.wav" % sound)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_effects.append(voice)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.stream = load("res://assets/audio/music.mp3")
	add_child(_music)
	_music.finished.connect(_music.play)
	apply_settings()
	_music.play()


func text(key: String) -> String:
	var entries: Dictionary = _texts.get(key, {})
	return str(entries.get(settings.language, entries.get("en", key)))


func set_setting(key: String, value: Variant) -> void:
	if not DEFAULT_SETTINGS.has(key):
		return
	if key in ["master", "music", "sfx"]:
		settings[key] = clampf(float(value), 0.0, 1.0)
	elif key == "language":
		if not LANGUAGES.has(value):
			return
		settings[key] = value
	else:
		settings[key] = bool(value)
	apply_settings()
	_save_timer.start()
	if key == "language":
		language_changed.emit()


func apply_settings() -> void:
	for key in ["master", "music", "sfx"]:
		var bus := AudioServer.get_bus_index({"master": "Master", "music": "Music", "sfx": "SFX"}[key])
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(float(settings[key]), 0.0001)))
		AudioServer.set_bus_mute(bus, float(settings[key]) == 0.0)
	TranslationServer.set_locale(settings.language)
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


func play_sound(sound: String) -> void:
	if not _sounds.has(sound) or _effects.is_empty():
		return
	var voice := _effects[_voice]
	_voice = (_voice + 1) % _effects.size()
	voice.stream = _sounds[sound]
	voice.pitch_scale = rng.randf_range(0.96, 1.04) if sound in ["shoot", "hit"] else 1.0
	voice.play()


func record_event(kind: String) -> void:
	game_event.emit(kind)
	var stat: String = {"shot": "shots", "slash": "slashes", "hit": "hits"}.get(kind, "")
	if not stat.is_empty():
		stats[stat] += 1
	# Don't restart this timer on rapid fire; still persist during long sessions.
	if _save_timer.is_stopped():
		_save_timer.start()
	if kind in ACHIEVEMENTS and not unlocked.has(kind):
		unlocked.append(kind)
		achievement_unlocked.emit(kind)
		play_sound("achievement")


func capture_player(player: Node2D) -> void:
	session = {"position": [player.position.x, player.position.y], "aim": [player.aim_direction.x, player.aim_direction.y]}


func save_now() -> bool:
	var data := {"version": 1, "settings": settings, "unlocked": unlocked, "session": session, "stats": stats}
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_failed.emit()
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".tmp"), ProjectSettings.globalize_path(save_path)) != OK:
		save_failed.emit()
		return false
	return true


func _load_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(save_path)) != OK:
		load_warning = true
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("version") != 1:
		load_warning = true
		return
	var saved_settings: Variant = parsed.get("settings", {})
	if saved_settings is Dictionary:
		for key in ["master", "music", "sfx"]:
			var value: Variant = saved_settings.get(key)
			if (value is float or value is int) and is_finite(float(value)):
				settings[key] = clampf(float(value), 0, 1)
		if saved_settings.get("fullscreen") is bool:
			settings.fullscreen = saved_settings.fullscreen
		if LANGUAGES.has(saved_settings.get("language")):
			settings.language = saved_settings.language
	var saved_unlocks: Variant = parsed.get("unlocked", [])
	if saved_unlocks is Array:
		for id in ACHIEVEMENTS:
			if id in saved_unlocks:
				unlocked.append(id)
	var saved_stats: Variant = parsed.get("stats", {})
	if saved_stats is Dictionary:
		for key in stats:
			var value: Variant = saved_stats.get(key, 0)
			if (value is int or value is float) and is_finite(float(value)):
				stats[key] = clampi(int(value), 0, 2147483647)
	var saved_session: Variant = parsed.get("session", {})
	if saved_session is Dictionary and _valid_pair(saved_session.get("position")) and _valid_pair(saved_session.get("aim")):
		session = saved_session


func _valid_pair(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	for number in value:
		if not (number is int or number is float) or not is_finite(float(number)) or absf(float(number)) > 1000000:
			return false
	return true
