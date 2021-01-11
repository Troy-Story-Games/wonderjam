extends Particles2D

export(bool) var AUTO_FREE = true


func _on_Timer_timeout():
	if AUTO_FREE:
		queue_free()
