extends Node2D

@onready var game_floor = $Floor
@onready var player = $Player

func _ready():

	player.game_floor = game_floor

	player.grid_pos = Vector2i(3, 3)

	player.snap_to_grid()

	print("WORLD SET PLAYER TO: ", player.grid_pos)
