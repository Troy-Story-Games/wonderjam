extends Enemy

onready var animationPlayer = $AnimationPlayer


func _on_EnemyStats_health_changed(value):
	if not animationPlayer.is_playing():
		animationPlayer.play("Rage")
