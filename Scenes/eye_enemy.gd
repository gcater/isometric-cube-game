extends Node2D

@onready var sprite = $AnimatedSprite2D

@export var move_interval := 0.25

var game_floor
var grid_pos := Vector2i(3, 3)
var move_timer := 0.0
var facing_dir := Vector2i(1, 0)

func _ready():
	sprite.position = Vector2(0, -48)

func _process(delta):
	pass
	# move_timer += delta
	# if move_timer >= move_interval:
	# 	move_timer = 0.0
	# 	move_one_tile()
	

func move_one_tile():
	var next_pos := grid_pos + facing_dir

	if not game_floor.blocks.has(next_pos):
		return

	grid_pos = next_pos
	snap_to_grid()

func snap_to_grid():
	position = game_floor.position + game_floor.grid_to_iso(grid_pos)