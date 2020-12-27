extends Area2D
class_name Hurtbox

signal take_damage(damage, area)


func _on_Hurtbox_area_entered(area):
	if area is Hitbox:
		print("DEBUG: Hurtbox area entered! Damage: ", area.DAMAGE)
		emit_signal("take_damage", area.DAMAGE, area)
