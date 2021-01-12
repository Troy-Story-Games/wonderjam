extends Pickup

export(int) var MULTIPLIER_VALUE = 5


func _pickup():
	._pickup()
	Events.emit_signal("add_multiplier", MULTIPLIER_VALUE)
	queue_free()
