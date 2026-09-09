extends SceneTree
## Run with: godot --headless --path . --script res://tests/systems_test.gd
## Uses its own save file and never overwrites normal player progress.
var failures: Array[String] = []
var services: Node

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run_checks() -> void:
	services = root.get_node("GameServices")
	services.save_path = "user://cube_systems_test.json"
	services.settings = services.DEFAULT_SETTINGS.duplicate()
	services.unlocked.clear()
	services.session.clear()
	services.stats = {"shots": 0, "slashes": 0, "hits": 0}
	var shell = load("res://Scenes/UI/game_shell.tscn").instantiate()
	root.add_child(shell)
	check(shell.page == "main", "Starts at main menu")
	var languages = services.LANGUAGES.keys()
	for key in services._texts:
		for locale in languages:
			check(services._texts[key].has(locale), "Missing translation: " + key + "/" + locale)
	Input.action_press("shoot")
	shell.start_game(false)
	var player = shell.world.get_node("Character")
	check(player.speed == 120 and player.scale == Vector2(4, 4), "Player configuration preserved")
	check(services.unlocked.has("welcome"), "Welcome achievement is earned")
	await process_frame
	player._physics_process(0.016)
	check(services.stats.shots == 0, "Menu click must not shoot")
	Input.action_release("shoot")
	player._physics_process(0.016)
	check(not player.require_attack_release, "Release clears combat input guard")
	player.shoot_at(player.sprite.global_position + Vector2(200, 0))
	check(services.stats.shots == 1 and services.unlocked.has("shot"), "Shooting records progress")
	var before = services.unlocked.size()
	services.record_event("shot")
	check(services.unlocked.size() == before, "Achievements unlock only once")
	Input.action_press("attack")
	player._physics_process(0.016)
	Input.action_release("attack")
	check(services.unlocked.has("slash"), "Slash records progress")
	shell.world.get_node("SolidBlock").on_projectile_hit(player)
	check(services.unlocked.has("hit"), "Impact records progress")
	player.position = Vector2(-100, 100)
	shell.pause_game()
	check(paused and shell.page == "pause", "Pause stops gameplay")
	var position_before: Vector2 = player.position
	Input.action_press("right")
	await physics_frame
	await physics_frame
	Input.action_release("right")
	check(player.position == position_before, "Player does not move while paused")
	shell.open_submenu("settings")
	check(shell.return_page == "pause", "Settings remembers paused context")
	services.set_setting("master", 0.4)
	services.set_setting("music", 0.0)
	services.set_setting("language", "ja")
	await process_frame
	check(services.text("settings") == "設定", "Japanese UI text")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music mute applied")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.4), "Master volume applied")
	shell.return_to_main()
	check(not paused and not is_instance_valid(shell.world), "Return to main frees world")
	shell.start_game(true)
	check(shell.world.get_node("Character").position == position_before, "Continue restores position")
	shell.pause_game()
	check(shell.save_game(), "Save succeeded")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(services.save_path))
	check(disk.settings.language == "ja" and disk.settings.master == 0.4, "Settings persisted")
	check(disk.unlocked.size() == 4, "Achievements persisted")
	var fresh = load("res://Scripts/Systems/game_services.gd").new()
	fresh.save_path = services.save_path
	fresh._load_save()
	check(Vector2(fresh.session.position[0], fresh.session.position[1]).is_equal_approx(position_before), "Fresh service loads player position")
	check(fresh.settings.language == "ja" and is_equal_approx(fresh.settings.master, services.settings.master), "Fresh service loads settings")
	fresh.free()
	var bad_file = FileAccess.open(services.save_path, FileAccess.WRITE)
	bad_file.store_string("not json")
	bad_file.close()
	fresh = load("res://Scripts/Systems/game_services.gd").new()
	fresh.save_path = services.save_path
	fresh._load_save()
	check(fresh.load_warning and fresh.session.is_empty(), "Corrupt save uses defaults")
	fresh.free()
	services._save_timer.stop()
	shell.free()
	paused = false
	services._music.stop()
	for voice in services._effects:
		voice.stop()
	# Let the audio mixer release stopped playback objects before exiting.
	await create_timer(0.25).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(services.save_path))
	await process_frame
	await process_frame
	await process_frame
	if failures.is_empty():
		print("PASS: menu navigation, preserved controls, pause, combat input guard, achievements, all translations, audio settings, save/reload and corrupt-save recovery")
	quit(0 if failures.is_empty() else 1)
