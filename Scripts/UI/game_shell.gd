extends Node
## GDScript entry point. The original world stays a separate, pausable scene.

const WORLD_SCENE = preload("res://Scenes/Free_world.tscn")
var world: Node2D
var page := "main"
var return_page := "main"
var canvas: CanvasLayer
var menu: Control
var card: VBoxContainer
var hud: Control
var toasts: VBoxContainer
var autosave_elapsed := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	_build_ui()
	GameServices.language_changed.connect(_refresh_language)
	GameServices.achievement_unlocked.connect(_on_achievement)
	GameServices.save_failed.connect(func(): notify(GameServices.text("save_failed")))
	show_page("main")
	if GameServices.load_warning:
		notify(GameServices.text("save_recovered"))


func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(menu)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Avenir Next", "Hiragino Sans", "Arial"])
	font.fallbacks = [load("res://assets/fonts/NotoSansJP.ttf")]
	theme.default_font = font
	theme.default_font_size = 18
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = {"normal": Color("243449"), "hover": Color("354e68"), "pressed": Color("1b293b"), "focus": Color(0, 0, 0, 0), "disabled": Color("1c2633")}[state]
		style.set_corner_radius_all(8)
		style.set_content_margin_all(12)
		if state == "focus":
			style.set_border_width_all(2)
			style.border_color = Color("88ddcb")
		theme.set_stylebox(state, "Button", style)
		theme.set_stylebox(state, "OptionButton", style)
	menu.theme = theme
	var backdrop := ColorRect.new()
	backdrop.color = Color("111c2c")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(backdrop)
	backdrop.name = "Backdrop"
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center.add_child(scroll)
	card = VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 10)
	scroll.add_child(card)
	hud = Control.new()
	hud.theme = theme
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud)
	toasts = VBoxContainer.new()
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	toasts.position = Vector2(-360, 24)
	toasts.size = Vector2(336, 0)
	toasts.add_theme_constant_override("separation", 8)
	toasts.theme = theme
	canvas.add_child(toasts)


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _label(parent: Node, text: String, font_size: int = 18, color: Color = Color("e7edf6")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(key: String, action: Callable, parent: Node = null) -> Button:
	var button := Button.new()
	button.text = GameServices.text(key)
	button.custom_minimum_size.y = 46
	button.pressed.connect(func():
		GameServices.play_sound("click")
		action.call()
	)
	(card if parent == null else parent).add_child(button)
	return button


func show_page(next_page: String) -> void:
	page = next_page
	menu.visible = page != "game"
	hud.visible = page == "game"
	if page == "game":
		return
	_clear(card)
	var backdrop: ColorRect = menu.get_node("Backdrop")
	backdrop.color = Color(0.04, 0.08, 0.14, 0.88) if is_instance_valid(world) else Color("111c2c")
	_label(card, "◇  ISOMETRIC CUBE", 34, Color("8ee1d0"))
	_label(card, GameServices.text(page if page != "main" else "subtitle"), 19, Color("a9bace"))
	var space := Control.new()
	space.custom_minimum_size.y = 8
	card.add_child(space)
	match page:
		"main":
			if not GameServices.session.is_empty():
				_button("continue", func(): start_game(true))
			_button("new_game", _new_game)
			_button("settings", func(): open_submenu("settings"))
			_button("achievements", func(): open_submenu("achievements"))
			_button("quit", func(): show_page("quit"))
			_label(card, GameServices.text("controls"), 15, Color("a9bace"))
		"pause":
			_button("resume", resume_game)
			_button("settings", func(): open_submenu("settings"))
			_button("achievements", func(): open_submenu("achievements"))
			_button("save_menu", return_to_main)
			_button("quit", func(): show_page("quit"))
		"settings":
			_settings_ui()
			_button("back", func(): show_page(return_page))
		"achievements":
			_achievements_ui()
			_button("back", func(): show_page(return_page))
		"new_game":
			_label(card, GameServices.text("new_confirm"))
			_button("new_game", func(): start_game(false))
			_button("back", func(): show_page("main"))
		"quit":
			_label(card, GameServices.text("quit_confirm"))
			_button("quit", quit_game)
			_button("back", func(): show_page("pause" if is_instance_valid(world) else "main"))
	for child in card.get_children():
		if child is Button:
			_focus_button.call_deferred(child)
			break


func _focus_button(button: Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree() and button.is_visible_in_tree():
		button.grab_focus()


func _settings_ui() -> void:
	for key in ["master", "music", "sfx"]:
		var row := HBoxContainer.new()
		card.add_child(row)
		var caption := _label(row, GameServices.text(key))
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label := _label(row, "%d%%" % roundi(float(GameServices.settings[key]) * 100))
		value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		value_label.custom_minimum_size.x = 64
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = float(GameServices.settings[key]) * 100
		slider.custom_minimum_size.y = 24
		slider.value_changed.connect(func(value: float):
			GameServices.set_setting(key, value / 100.0)
			value_label.text = "%d%%" % roundi(value)
		)
		card.add_child(slider)
	var fullscreen := CheckButton.new()
	fullscreen.text = GameServices.text("fullscreen")
	fullscreen.button_pressed = GameServices.settings.fullscreen
	fullscreen.toggled.connect(func(value: bool): GameServices.set_setting("fullscreen", value))
	card.add_child(fullscreen)
	_label(card, GameServices.text("language"))
	var languages := OptionButton.new()
	var codes: Array = GameServices.LANGUAGES.keys()
	for code in codes:
		languages.add_item(GameServices.LANGUAGES[code])
	languages.select(codes.find(GameServices.settings.language))
	languages.item_selected.connect(func(index: int): GameServices.set_setting("language", codes[index]))
	card.add_child(languages)
	_label(card, GameServices.text("settings_saved"), 14, Color("a9bace"))


func _achievements_ui() -> void:
	_label(card, "%d / %d" % [GameServices.unlocked.size(), GameServices.ACHIEVEMENTS.size()], 24)
	for id in GameServices.ACHIEVEMENTS:
		var earned: bool = id in GameServices.unlocked
		_label(card, ("✓  " if earned else "○  ") + GameServices.text("ach_" + id), 20, Color("8ee1d0") if earned else Color("a9bace"))
		_label(card, GameServices.text("desc_" + id), 15)
	_label(card, GameServices.text("stats") % [GameServices.stats.shots, GameServices.stats.slashes, GameServices.stats.hits], 15, Color("a9bace"))


func _new_game() -> void:
	if GameServices.session.is_empty():
		start_game(false)
	else:
		show_page("new_game")


func open_submenu(target: String) -> void:
	return_page = "pause" if is_instance_valid(world) else "main"
	show_page(target)


func start_game(continue_save: bool) -> void:
	if is_instance_valid(world):
		world.free()
	world = WORLD_SCENE.instantiate()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	var player: Node2D = world.get_node("Character")
	if continue_save and not GameServices.session.is_empty():
		var saved: Dictionary = GameServices.session
		player.position = Vector2(saved.position[0], saved.position[1])
		player.aim_direction = Vector2(saved.aim[0], saved.aim[1]).normalized()
	player.require_attack_release = true
	get_tree().paused = false
	autosave_elapsed = 0
	_build_hud()
	show_page("game")
	GameServices.record_event("welcome")
	save_game()


func _build_hud() -> void:
	_clear(hud)
	var pause_button := _button("pause", pause_game, hud)
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	pause_button.position = Vector2(20, 20)
	pause_button.size = Vector2(150, 46)
	var hint := _label(hud, GameServices.text("controls"), 16)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 20
	hint.offset_top = -52
	hint.offset_right = 1100
	hint.offset_bottom = -12
	hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)


func pause_game() -> void:
	if not is_instance_valid(world):
		return
	get_tree().paused = true
	save_game()
	show_page("pause")


func resume_game() -> void:
	world.get_node("Character").require_attack_release = true
	get_tree().paused = false
	show_page("game")


func return_to_main() -> void:
	save_game()
	if is_instance_valid(world):
		world.free()
	world = null
	get_tree().paused = false
	show_page("main")


func save_game() -> bool:
	if is_instance_valid(world):
		GameServices.capture_player(world.get_node("Character"))
	return GameServices.save_now()


func quit_game() -> void:
	save_game()
	get_tree().quit()


func _process(delta: float) -> void:
	if page == "game":
		autosave_elapsed += delta
		if autosave_elapsed >= 5.0:
			autosave_elapsed = 0.0
			save_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		match page:
			"game": pause_game()
			"pause": resume_game()
			"settings", "achievements": show_page(return_page)
			"quit", "new_game": show_page("pause" if is_instance_valid(world) else "main")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and page == "game":
		pause_game()


func _refresh_language() -> void:
	_refresh_ui.call_deferred()


func _refresh_ui() -> void:
	show_page(page)
	if is_instance_valid(world):
		_build_hud()


func _on_achievement(id: String) -> void:
	notify(GameServices.text("unlocked") + "\n" + GameServices.text("ach_" + id))


func notify(message: String) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("243449")
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	toasts.add_child(panel)
	_label(panel, message, 17, Color("8ee1d0"))
	var tween := panel.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(3.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)
