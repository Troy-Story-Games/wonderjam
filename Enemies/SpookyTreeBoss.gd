extends Enemy

onready var animationPlayer = $AnimationPlayer


func _on_EnemyStats_health_changed(_value):
	if animationPlayer != null:
		if not animationPlayer.is_playing():
			animationPlayer.play("Rage")
