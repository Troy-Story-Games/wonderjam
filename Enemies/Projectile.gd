extends Node2D

# TODO: HitEffect

var velocity = Vector2.ZERO


func _process(delta):
	position += velocity * delta


func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()


func _on_Hitbox_body_entered(_body):
	# TODO: HitEffect
	queue_free()  # Destroy projectile when it hits a wall


func _on_Hitbox_area_entered(_area):
	# TODO: HitEffect
	queue_free()  # When a projectile hits a hurtbox it will destroy itself
