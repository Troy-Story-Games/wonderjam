extends Pickup

export(int) var POINT_VALUE = 100  # Value if the player is at max health


func _pickup():
	._pickup()
	if PlayerStats.health == PlayerStats.max_health:
		Events.emit_signal("score_points", POINT_VALUE)
	PlayerStats.health += 1  # This is fine b/c it's clamped
	queue_free()
