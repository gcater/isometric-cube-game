extends Node2D

@onready var sprite = $AnimatedSprite2D
@export var move_delay := 0.15

var game_floor
var grid_pos := Vector2i.ZERO
var move_timer := 0.0

func _ready():
	add_to_group("player")
	sprite.position = Vector2(0, -48)

func setup(floor_ref, start_pos):
	game_floor = floor_ref
	grid_pos = start_pos

	game_floor.add_entity(self, grid_pos)

	snap_to_grid()

func _process(delta):
	move_timer -= delta
	if move_timer > 0:
		return 
	if Input.is_action_pressed("left"):
		sprite.play("left")
		try_move(Vector2i(-1, 0))
		move_timer = move_delay

	elif Input.is_action_pressed("right"):
		sprite.play("right")
		try_move(Vector2i(1, 0))
		move_timer = move_delay

	elif Input.is_action_pressed("up"):
		sprite.play("up")
		try_move(Vector2i(0, -1))
		move_timer = move_delay

	elif Input.is_action_pressed("down"):
		sprite.play("down")
		try_move(Vector2i(0, 1))
		move_timer = move_delay


func try_move(dir: Vector2i):


	if game_floor == null:
		return

	var next_pos := grid_pos + dir

	if game_floor.move_entity(self, grid_pos, next_pos):
		grid_pos = next_pos
		snap_to_grid()
		print(grid_pos)


func snap_to_grid():

	position = game_floor.position + game_floor.grid_to_iso(grid_pos)
