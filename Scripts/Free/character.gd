extends CharacterBody2D

@export var speed: float = 120.0


func _physics_process(_delta: float) -> void:
	var move_direction := Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)



	if move_direction.length_squared() > 0.0:
		move_direction = move_direction.normalized()

	velocity = move_direction * speed
	move_and_slide()