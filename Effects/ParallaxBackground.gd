extends ParallaxBackground

export(bool) var AUTO_SCROLL = false
export(int) var SCROLL_SPEED = 50
export(float) var BACKGROUND_SCALE = 0.5
export(float) var MIDGROUND_SCALE = 0.75

onready var background = $Background
onready var midground = $Midground


func _ready():
	background.motion_scale.x = BACKGROUND_SCALE
	midground.motion_scale.x = MIDGROUND_SCALE


func _process(delta):
	if AUTO_SCROLL:
		scroll_offset.x -= SCROLL_SPEED * delta
