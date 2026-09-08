extends StaticBody2D

var flash_tween: Tween


func on_slash_hit(_attacker: Node2D) -> void:
	flash_hit()


func on_projectile_hit(_attacker: Node2D) -> void:
	flash_hit()


func flash_hit() -> void:
	if flash_tween:
		flash_tween.kill()
	$Sprite2D.modulate = Color(1.0, 0.55, 0.35)
	flash_tween = create_tween()
	flash_tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.2)
