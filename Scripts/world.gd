extends Node2D

@onready var game_floor = $Floor
@onready var player = $Entities/Player
@onready var eye_enemy = $Entities/EyeEnemy

func _ready():

	player.game_floor = game_floor
	eye_enemy.game_floor = game_floor
	player.grid_pos = Vector2i(3, 3)
	eye_enemy.grid_pos = Vector2i(5, 5)
	player.snap_to_grid()
	eye_enemy.snap_to_grid()

	# print("WORLD SET PLAYER TO: ", player.grid_pos)
