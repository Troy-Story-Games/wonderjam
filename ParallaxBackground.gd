extends Node2D

export(bool) var AUTO_SCROLL = false
export(int) var SCROLL_SPEED = 50

onready var parallaxBackground = $ParallaxBackground

func _process(delta):
	if AUTO_SCROLL:
		parallaxBackground.scroll_offset.x -= SCROLL_SPEED * delta
