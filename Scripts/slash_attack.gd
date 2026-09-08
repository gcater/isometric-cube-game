extends Node2D

signal hit(target: Node2D)

@export var damage: int = 1
@export var duration: float = 0.18
@export var cooldown: float = 0.35
@export var reach: float = 28.0

const HALF_ARC := PI / 3.0
const SEGMENTS := 16

var elapsed := 0.0
var cooldown_left := 0.0
var active := false
var facing_angle := 0.0
var hit_targets: Dictionary = {}
var hit_shape := ConvexPolygonShape2D.new()


func start(direction: Vector2) -> bool:
	if active or cooldown_left > 0.0:
		return false
	facing_angle = direction.angle()
	elapsed = 0.0
	cooldown_left = cooldown
	hit_targets.clear()
	var points := PackedVector2Array([Vector2.ZERO])
	for i in range(SEGMENTS + 1):
		var angle := facing_angle - HALF_ARC + 2.0 * HALF_ARC * i / SEGMENTS
		points.append(project_point(angle, reach))
	hit_shape.points = points
	active = true
	queue_redraw()
	return true


func _physics_process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if not active:
		return
	# Query every active tick, so bodies already touching the hitbox are included.
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hit_shape
	query.transform = global_transform
	query.collision_mask = 1
	query.exclude = [get_parent().get_rid()]
	for result in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var target: Node2D = result.collider
		var target_id := target.get_instance_id()
		if hit_targets.has(target_id):
			continue
		hit_targets[target_id] = true
		if target.has_method("take_damage"):
			target.take_damage(damage)
		if is_instance_valid(target) and target.has_method("on_slash_hit"):
			target.on_slash_hit(get_parent())
		if is_instance_valid(target):
			hit.emit(target)
	elapsed += delta
	active = elapsed < duration
	queue_redraw()


func project_point(angle: float, radius: float) -> Vector2:
	return Vector2(cos(angle) * radius, sin(angle) * radius * 0.5)


func _draw() -> void:
	if not active:
		return
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var alpha := 1.0 - progress
	var ribbon := PackedVector2Array()
	var edge := PackedVector2Array()
	# Lift the visual from the ground hitbox to the cube's midsection.
	var lift := Vector2(0, -8)
	var end_angle := facing_angle - HALF_ARC + 2.0 * HALF_ARC * progress
	var start_angle := maxf(facing_angle - HALF_ARC, end_angle - 1.3)
	for i in range(SEGMENTS + 1):
		var angle := lerpf(start_angle, end_angle, float(i) / SEGMENTS)
		var point := project_point(angle, reach) + lift
		ribbon.append(point)
		edge.append(point)
	for i in range(SEGMENTS, -1, -1):
		var angle := lerpf(start_angle, end_angle, float(i) / SEGMENTS)
		ribbon.append(project_point(angle, reach - 7.0) + lift)
	if progress > 0.0:
		draw_colored_polygon(ribbon, Color(0.7, 0.85, 1.0, alpha * 0.75))
		draw_polyline(edge, Color(1, 1, 1, alpha), 1.0, true)
