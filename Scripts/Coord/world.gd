extends Node2D

@export var eye_enemy_scene: PackedScene

@onready var game_floor = $Level_One_Floor
@onready var player = $Entities/Player
@onready var entities_node = $Entities

func _ready():

	player.setup(game_floor, Vector2i(3, 3))
	# for i in range(game_floor.height):
	# 	for j in range(game_floor.width):
	# 		spawn_enemy(Vector2i(i,j))
	#spawn_enemy(Vector2i(3, 0))
	# spawn_enemy(Vector2i(3, 2))
	spawn_enemy(Vector2i(5, 5))
	# spawn_enemy(Vector2i(10, 13))
	# spawn_enemy(Vector2i(7, 15))
	# spawn_enemy(Vector2i(12, 9))
	# print("WORLD SET PLAYER TO: ", player.grid_pos)


func spawn_enemy(pos: Vector2i):

	var enemy = eye_enemy_scene.instantiate()

	entities_node.add_child(enemy)

	enemy.setup(game_floor, pos)
