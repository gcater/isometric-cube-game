extends Node2D

@export var block_scene: PackedScene
@export var width := 8
@export var height := 8

const TILE_W := 96
const TILE_H := 48

var blocks := {}


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
