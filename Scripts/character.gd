extends CharacterBody2D

@export var speed: float = 120.0
@export var shot_interval: float = 0.18

const PROJECTILE_SCENE = preload("res://Scenes/projectile.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash: Node2D = $SlashAttack

# Facing directions clockwise from east, independent of movement input.
const FACING_ANIMATIONS = [
	&"walk_e", &"walk_se", &"walk_s", &"walk_sw",
	&"walk_w", &"walk_nw", &"walk_n", &"walk_ne",
]

var aim_direction := Vector2(1, 1).normalized()
var shot_cooldown := 0.0
var require_attack_release := false


func _ready() -> void:
	sprite.animation = &"walk_se"
	sprite.pause()


func update_aim(mouse_world_position: Vector2) -> void:
	var mouse_offset := to_local(mouse_world_position) - sprite.position
	# Keep the previous facing when the cursor is directly over the player.
	if mouse_offset.length_squared() < 1.0:
		return
	# Choose the sprite from the actual cursor angle, in eight equal sectors.
	var facing_index := wrapi(roundi(mouse_offset.angle() / (PI / 4.0)), 0, 8)
	sprite.animation = FACING_ANIMATIONS[facing_index]
	# Only the slash needs its 2:1 projection undone to aim at the cursor.
	aim_direction = Vector2(mouse_offset.x, mouse_offset.y * 2.0).normalized()


func shoot_at(mouse_world_position: Vector2) -> bool:
	if shot_cooldown > 0.0:
		return false
	var direction := mouse_world_position - sprite.global_position
	if direction.length_squared() < 1.0:
		direction = global_transform.basis_xform(Vector2(aim_direction.x, aim_direction.y * 0.5))
	var projectile = PROJECTILE_SCENE.instantiate()
	# Keep projectiles separate from the player so movement and scale aren't inherited.
	get_parent().add_child(projectile)
	projectile.launch(self, direction, sprite.global_position - global_position)
	shot_cooldown = shot_interval
	GameServices.play_sound("shoot")
	GameServices.record_event("shot")
	return true


func _physics_process(delta: float) -> void:
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
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

	update_aim(get_global_mouse_position())
	if move_direction.length_squared() > 0.0:
		sprite.play()
	else:
		sprite.pause()

	# Menu clicks and held buttons must not fire a weapon when play resumes.
	if require_attack_release:
		if not Input.is_action_pressed("shoot") and not Input.is_action_pressed("attack"):
			require_attack_release = false
		return
	if Input.is_action_just_pressed("attack") and slash.start(aim_direction):
		GameServices.play_sound("slash")
		GameServices.record_event("slash")
	if Input.is_action_pressed("shoot"):
		shoot_at(get_global_mouse_position())
