extends Node2D

@export var attack_tile_scene: PackedScene
@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@export var move_speed := 12.0
@export var move_delay := 0.15


# const DIRS_8 := [
# 	Vector2i(0, -1),
# 	Vector2i(1, -1),
# 	Vector2i(1, 0),
# 	Vector2i(1, 1),
# 	Vector2i(0, 1),
# 	Vector2i(-1, 1),
# 	Vector2i(-1, 0),
# 	Vector2i(-1, -1),
# ]

var game_floor
var grid_pos := Vector2i.ZERO
var move_timer := 0.0
var target_position := Vector2.ZERO
var facing_dir := Vector2i(1, 0) # Default facing right
var attack_index := 2
#var attack_dir : Vector2i  = DIRS_8[attack_index]


func _ready():
	add_to_group("player")
	sprite.position = Vector2(0, -48)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0

func setup(floor_ref, start_pos):
	game_floor = floor_ref
	grid_pos = start_pos
	sprite.play("right")

	game_floor.add_entity(self, grid_pos)
	snap_to_grid()	
	

func _process(delta):
	if Input.is_action_just_pressed("attack"):
		shoot_attack_tile()
	position = position.lerp(target_position, move_speed * delta)
	move_timer -= delta
	if move_timer > 0:
		return 
	if Input.is_action_pressed("left"):
		facing_dir = Vector2i(-1, 0)
		sprite.play("left")
		try_move(facing_dir)
		move_timer = move_delay

	elif Input.is_action_pressed("right"):
		facing_dir = Vector2i(1, 0)
		sprite.play("right")
		try_move(facing_dir)
		move_timer = move_delay

	elif Input.is_action_pressed("up"):
		facing_dir = Vector2i(0, -1)
		sprite.play("up")
		try_move(facing_dir)
		move_timer = move_delay

	elif Input.is_action_pressed("down"):
		facing_dir = Vector2i(0, 1)	
		sprite.play("down")
		try_move(facing_dir)
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

	target_position = game_floor.position + game_floor.grid_to_iso(grid_pos)

func shoot_attack_tile():
	var attack = attack_tile_scene.instantiate()
	get_parent().add_child(attack)
	var start_pos := grid_pos - facing_dir

	attack.setup(game_floor, start_pos, facing_dir)

# func update_attack_tile():
# 	attack_dir = DIRS_8[attack_index]

# 	var attack_pos = grid_pos + attack_dir

# 	attack_tile.grid_pos = attack_pos
# 	attack_tile.snap_to_grid()