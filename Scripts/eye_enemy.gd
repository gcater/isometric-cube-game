extends Node2D

@onready var sprite = $AnimatedSprite2D

@export var move_interval := 1.0
@export var bullet_scene: PackedScene
@export var shoot_interval := 1.0

const DIRS_8: Array[Vector2i] = [
	Vector2i(0, -1),   # up
	Vector2i(1, -1),   # up-right
	Vector2i(1, 0),    # right
	Vector2i(1, 1),    # down-right
	Vector2i(0, 1),    # down
	Vector2i(-1, 1),   # down-left
	Vector2i(-1, 0),   # left
	Vector2i(-1, -1),  # up-left
]


var game_floor
var grid_pos := Vector2i(0, 0)
var move_timer := 0.0
var facing_index := 0
var facing_dir: Vector2i = DIRS_8[facing_index]

var shoot_timer := 0.0


func _ready():
	sprite.position = Vector2(0, -48)

func setup(floor_ref, start_pos: Vector2i):
	game_floor = floor_ref
	grid_pos = start_pos

	game_floor.add_entity(self, grid_pos)

	snap_to_grid()
	update_animation()


func _process(delta):
	
	move_timer += delta

	shoot_timer += delta

	# if shoot_timer >= shoot_interval:
	# 	shoot_timer = 0.0
		
		
	
	if move_timer >= move_interval:
		move_timer = 0.0
		#move_one_tile()
		rotate_clockwise()
		shoot()
		

func shoot():
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)

	var start_pos := grid_pos
	bullet.setup(game_floor, start_pos, facing_dir)

func move_one_tile():
	if game_floor == null:
		return

	var next_pos := grid_pos + facing_dir

	if game_floor.move_entity(self, grid_pos, next_pos):
		grid_pos = next_pos
		snap_to_grid()



func snap_to_grid():
	position = game_floor.position + game_floor.grid_to_iso(grid_pos)

func rotate_clockwise():
	facing_index = (facing_index + 1) % DIRS_8.size()
	facing_dir = DIRS_8[facing_index]
	update_animation()

func rotate_counterclockwise():
	facing_index = (facing_index - 1 + DIRS_8.size()) % DIRS_8.size()
	facing_dir = DIRS_8[facing_index]
	update_animation()

func update_animation():

	match facing_dir:
		Vector2i(0, -1):
			sprite.play("up")

		Vector2i(1, -1):
			sprite.play("up_right")

		Vector2i(1, 0):
			sprite.play("right")

		Vector2i(1, 1):
			sprite.play("down_right")

		Vector2i(0, 1):
			sprite.play("down")

		Vector2i(-1, 1):
			sprite.play("down_left")

		Vector2i(-1, 0):
			sprite.play("left")

		Vector2i(-1, -1):
			sprite.play("up_left")