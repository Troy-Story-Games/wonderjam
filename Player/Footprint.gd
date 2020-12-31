extends "res://Effects/DissolvingSprite.gd"

onready var animationPlayer = $AnimationPlayer


func _on_Timer_timeout():
	animationPlayer.play("Accumulate")
