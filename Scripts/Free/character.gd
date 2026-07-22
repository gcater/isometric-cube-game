extends CharacterBody2D

@export var speed: float = 120.0

const ISO_X_AXIS := Vector2(0.894427, 0.447214)
const ISO_Y_AXIS := Vector2(-0.894427, 0.447214)

func _physics_process(_delta: float) -> void:
	var grid_input := Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)

	var move_direction := (
		ISO_X_AXIS * grid_input.x
		+ ISO_Y_AXIS * grid_input.y
	)

	if move_direction.length_squared() > 0.0:
		move_direction = move_direction.normalized()

	velocity = move_direction * speed
	move_and_slide()