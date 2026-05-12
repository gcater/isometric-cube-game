extends Node2D

@onready var sprite = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_left"):
		sprite.play("bottom_left")

	elif Input.is_action_just_pressed("ui_right"):
		sprite.play("bottom_right")

	elif Input.is_action_just_pressed("ui_up"):
		sprite.play("top_left")

	elif Input.is_action_just_pressed("ui_down"):
		sprite.play("top_right")
