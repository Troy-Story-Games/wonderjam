extends Pickup

export(int) var POINT_VALUE = 200  # Value if the player is at max health


func _pickup():
	._pickup()
	if PlayerStats.bombs == PlayerStats.max_bombs:
		Events.emit_signal("score_points", POINT_VALUE)
	PlayerStats.bombs += 1  # This is fine b/c it's clamped
	queue_free()
