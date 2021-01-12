extends AudioStreamPlayer


func fade_in():
	$AnimationPlayer.play("FadeIn")


func fade_out():
	$AnimationPlayer.play("FadeOut")
