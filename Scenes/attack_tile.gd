extends Node2D

var game_floor
var grid_pos := Vector2i.ZERO
var dir := Vector2i.ZERO

@export var move_interval := 0.08
@export var max_steps := 6

var move_timer := 0.0
var steps := 0


func setup(floor_ref, start_pos: Vector2i, direction: Vector2i):
	game_floor = floor_ref
	grid_pos = start_pos
	dir = direction

	flash_current_block()
	snap_to_grid()


func _process(delta):
	move_timer += delta

	if move_timer >= move_interval:
		move_timer = 0.0
		move_one_tile()


func move_one_tile():
	var next_pos := grid_pos + dir

	if not game_floor.blocks.has(next_pos):
		queue_free()
		return

	grid_pos = next_pos
	steps += 1

	if game_floor.entities.has(next_pos):
		var other = game_floor.entities[next_pos]

		if other.is_in_group("enemy"):
			game_floor.remove_entity(next_pos)
			other.queue_free()
			queue_free()
			return

	flash_current_block()
	snap_to_grid()

	if steps >= max_steps:
		queue_free()


func flash_current_block():
	var block = game_floor.blocks.get(grid_pos)

	if block:
		block.flash_red()


func snap_to_grid():
	position = game_floor.grid_to_iso(grid_pos)