extends CharacterBody2D

@export var speed: float = 120.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Animation bindings clockwise from D; this does not change movement.
const FACING_ANIMATIONS = [
	&"walk_ne", &"walk_e", &"walk_se", &"walk_s",
	&"walk_sw", &"walk_w", &"walk_nw", &"walk_n",
]


func _physics_process(_delta: float) -> void:
	var move_direction := Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)



	if move_direction.length_squared() > 0.0:
		move_direction = move_direction.normalized()
		var facing_index := wrapi(roundi(move_direction.angle() / (PI / 4.0)), 0, 8)
		sprite.play(FACING_ANIMATIONS[facing_index])
	else:
		sprite.pause()

	velocity = move_direction * speed
	move_and_slide()
