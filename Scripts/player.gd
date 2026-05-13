extends Node2D

@onready var sprite = $AnimatedSprite2D

var game_floor
var grid_pos := Vector2i.ZERO


func _process(delta):

	if Input.is_action_just_pressed("ui_left"):
		sprite.play("bottom_left")
		try_move(Vector2i(-1, 0))

	elif Input.is_action_just_pressed("ui_right"):
		sprite.play("top_right")
		try_move(Vector2i(1, 0))

	elif Input.is_action_just_pressed("ui_up"):
		sprite.play("top_left")
		try_move(Vector2i(0, -1))

	elif Input.is_action_just_pressed("ui_down"):
		sprite.play("bottom_right")
		try_move(Vector2i(0, 1))


func try_move(dir: Vector2i):

	if game_floor == null:
		return

	var next_pos = grid_pos + dir

	if !game_floor.blocks.has(next_pos):
		return

	grid_pos = next_pos

	position = game_floor.grid_to_iso(grid_pos)
