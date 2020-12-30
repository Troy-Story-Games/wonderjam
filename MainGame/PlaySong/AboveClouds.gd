extends Node

export(int) var STARTING_SCROLL_SPEED = 250
export(int) var MAX_SCROLL_SPEED = 3000
export(int) var SCROLL_ACCELERATION = 3000
export(float) var SCROLL_FRICTION = 0.025

var boost = false
var speed = 0 setget set_speed

onready var highBackground = $HighBackground


func _ready():
	BeatDetector.start_main_song()
	self.speed = STARTING_SCROLL_SPEED


func _physics_process(delta):
	var beats = BeatDetector.get_low_beats_now()

	if len(beats) > 0:
		boost = true

	if boost:
		self.speed += SCROLL_ACCELERATION * delta
	else:
		self.speed = lerp(self.speed, STARTING_SCROLL_SPEED, SCROLL_FRICTION)


func set_speed(value):
	speed = clamp(value, STARTING_SCROLL_SPEED, MAX_SCROLL_SPEED)
	highBackground.SCROLL_SPEED = speed
	
	if speed >= (MAX_SCROLL_SPEED / 1.5) and boost:
		boost = false
