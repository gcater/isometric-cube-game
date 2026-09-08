extends CharacterBody2D

signal hit(target: Node2D)

@export var speed: float = 600.0
@export var damage: int = 1
@export var lifetime: float = 2.0

var shooter: PhysicsBody2D


func launch(source: PhysicsBody2D, direction: Vector2, visual_offset: Vector2) -> void:
	shooter = source
	global_position = source.global_position
	add_collision_exception_with(source)
	velocity = direction.normalized() * speed
	# The body travels on the ground plane; the image travels at firing height.
	$Sprite2D.position = visual_offset


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	# Swept movement catches thin obstacles even between rendered frames.
	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return
	var target := collision.get_collider()
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if is_instance_valid(target) and target.has_method("on_projectile_hit"):
		target.on_projectile_hit(shooter if is_instance_valid(shooter) else null)
	if is_instance_valid(target) and target is Node2D:
		hit.emit(target)
	set_physics_process(false)
	hide()
	queue_free()
