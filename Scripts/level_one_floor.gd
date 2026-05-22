extends Node2D

@export var block_scene: PackedScene
@export var width := 16
@export var height := 16

const TILE_W := 96
const TILE_H := 48

var blocks := {}
var entities := {}


func _ready():
	generate_floor()
	

func generate_floor():
	for x in range(width):
		for y in range(height):
			var grid_pos := Vector2i(x, y)

			var block = block_scene.instantiate()
			add_child(block)

			block.grid_pos = grid_pos
			block.position = grid_to_iso(grid_pos)

			blocks[grid_pos] = block

func grid_to_iso(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * TILE_W / 2,
		(grid_pos.x + grid_pos.y) * TILE_H / 2
	) 

func add_entity(entity, pos: Vector2i):
	entities[pos] = entity
	
func remove_entity(pos: Vector2i):
	entities.erase(pos)


func move_entity(entity, old_pos: Vector2i, new_pos: Vector2i) -> bool:

	# off map
	if not blocks.has(new_pos):
		return false

	# collision
	if entities.has(new_pos):
		var other = entities[new_pos]
		handle_collision(entity, other)
		return false

	entities.erase(old_pos)
	entities[new_pos] = entity

	return true


func handle_collision(a, b):

	if a.is_in_group("player") and b.is_in_group("enemy"):
		print("player hit enemy")

	elif a.is_in_group("bullet") and b.is_in_group("enemy"):
		print("bullet hit enemy")