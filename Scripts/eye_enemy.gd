extends Node2D

@onready var sprite = $AnimatedSprite2D

@export var move_interval := 0.25
@export var bullet_scene: PackedScene
@export var shoot_interval := 1.0

var game_floor
var grid_pos := Vector2i(0, 0)
var move_timer := 0.0
var facing_dir := Vector2i(0, 1)

var shoot_timer := 0.0

func _ready():
	sprite.position = Vector2(0, -48)

func setup(floor_ref, start_pos: Vector2i):
	game_floor = floor_ref
	grid_pos = start_pos

	game_floor.add_entity(self, grid_pos)

	snap_to_grid()


func _process(delta):
	
	move_timer += delta

	shoot_timer += delta

	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot()
	
	if move_timer >= move_interval:
		move_timer = 0.0
		#move_one_tile()

func shoot():
	var bullet = bullet_scene.instantiate()
	print("there is a bullet", bullet)

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

