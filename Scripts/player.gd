extends Node2D

@export var attack_tile_scene: PackedScene
@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@export var move_speed := 12.0
@export var move_delay := 0.15


const DIRS_8 : Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
]

#var attack_tile
var game_floor
var grid_pos := Vector2i.ZERO
var move_timer := 0.0
var target_position := Vector2.ZERO
var facing_dir := Vector2i(1, 0) # Default facing right
var attack_index := 2
var previous_attack_pos := Vector2i.ZERO



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
	previous_attack_pos = get_attack_pos()
	update_attack_selector()
	

func _process(delta):
	if Input.is_action_just_pressed("attack"):
		shoot_attack_tile()
	position = position.lerp(target_position, move_speed * delta)
	move_timer -= delta
	if Input.is_action_just_pressed("rotate_attack_cw"):
		attack_index = (attack_index - 1 + DIRS_8.size()) % DIRS_8.size()
		update_attack_selector()

	if Input.is_action_just_pressed("rotate_attack_ccw"):
			attack_index = (attack_index + 1) % DIRS_8.size()
			update_attack_selector()

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
		update_attack_selector()
		print(grid_pos)


func snap_to_grid():

	target_position = game_floor.position + game_floor.grid_to_iso(grid_pos)

func shoot_attack_tile():
	var attack_dir := get_attack_dir()
	var attack_pos := get_attack_pos()
	var attack_tile = attack_tile_scene.instantiate()
	get_parent().add_child(attack_tile)


	attack_tile.setup(game_floor, attack_pos, attack_dir)

func get_attack_dir() -> Vector2i:
	return DIRS_8[attack_index]

func get_attack_pos() -> Vector2i:
	return grid_pos + get_attack_dir()

func update_attack_selector():
	var old_block = game_floor.blocks.get(previous_attack_pos)
	if old_block:
		old_block.set_selected(false)

	var attack_pos := get_attack_pos()

	var new_block = game_floor.blocks.get(attack_pos)
	if new_block:
		new_block.set_selected(true)

	previous_attack_pos = attack_pos
	check_selected_tile_hit()

func check_selected_tile_hit():
	var attack_pos := get_attack_pos()

	if game_floor.entities.has(attack_pos):
		var other = game_floor.entities[attack_pos]

		if other.is_in_group("enemy"):
			game_floor.remove_entity(attack_pos)
			other.queue_free()
