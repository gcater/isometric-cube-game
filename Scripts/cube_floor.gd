extends Node2D
var grid_pos := Vector2i.ZERO

@onready var sprite = $Sprite2D

var timer := 0.0
var active := false
var is_selected := false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if active:
		timer -= delta

		if timer <= 0:
			if is_selected:
				sprite.modulate = Color.RED
			else:
				sprite.modulate = Color.WHITE

			active = false

func flash_red():
	
	sprite.modulate = Color.RED

	timer = 0.5
	active = true

func set_selected(selected: bool):
	is_selected = selected

	if selected:
		sprite.modulate = Color.RED
	else:
		sprite.modulate = Color.WHITE
