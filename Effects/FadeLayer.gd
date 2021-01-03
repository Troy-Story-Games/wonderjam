extends CanvasLayer

signal fade_in_complete()
signal fade_out_complete()

export(float) var FADE_IN_START_DELAY = 0.5

var speed_after_delay = 2.0

onready var fadeAnimator = $FadeAnimator
onready var textureRect = $TextureRect
onready var fadeInDelay = $FadeInDelay


func _ready():
	textureRect.show()


func fade_in(speed=2.0):
	if FADE_IN_START_DELAY > 0.0:
		speed_after_delay = speed
		fadeInDelay.start(FADE_IN_START_DELAY)
	else:
		_internal_fade_in(speed)


func _internal_fade_in(speed=2.0):
	speed = 1.0 / speed
	fadeAnimator.playback_speed = speed
	fadeAnimator.play("FadeIn")


func fade_out(speed=2.0):
	speed = 1.0 / speed
	fadeAnimator.playback_speed = speed
	fadeAnimator.play("FadeOut")


func _on_FadeAnimator_animation_finished(anim_name):
	if anim_name == "FadeIn":
		emit_signal("fade_in_complete")
	else:
		emit_signal("fade_out_complete")


func _on_FadeInDelay_timeout():
	_internal_fade_in(speed_after_delay)
