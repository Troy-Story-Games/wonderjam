extends ParallaxBackground

export(bool) var AUTO_SCROLL = false
export(int) var SCROLL_SPEED = 50


func _process(delta):
	if AUTO_SCROLL:
		scroll_offset.x -= SCROLL_SPEED * delta
