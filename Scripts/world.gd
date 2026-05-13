extends Node2D

@onready var game_floor = $Floor
@onready var player = $Player

func _ready():

	player.game_floor = game_floor

	player.grid_pos = Vector2i(3, 3)

	player.position = game_floor.grid_to_iso(player.grid_pos)
