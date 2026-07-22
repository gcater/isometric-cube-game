extends Node2D

var game_floor
var grid_pos := Vector2i.ZERO
var dir := Vector2i.ZERO
var first_step := true

@export var move_interval := 0.12
var move_timer := 0.0


func setup(floor_ref, start_pos: Vector2i, direction: Vector2i):
	game_floor = floor_ref
	grid_pos = start_pos
	dir = direction
	visible = false
	snap_to_grid()


func _process(delta):
	#print("bullet at:", grid_pos)
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
	snap_to_grid()


	if first_step:
		first_step = false
		visible = true


	var block = game_floor.blocks[grid_pos]
	block.flash_red()

	if game_floor.entities.has(grid_pos):
		var other = game_floor.entities[grid_pos]
		if other.is_in_group("player"):
			print("bullet hit player")
			game_floor.handle_collision(self, other)
			queue_free()	
			return
		

		


func snap_to_grid():
	position = game_floor.position + game_floor.grid_to_iso(grid_pos)
