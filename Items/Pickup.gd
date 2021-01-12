extends Area2D
class_name Pickup

export(int) var SPEED = 100
export(int) var ROTATION_SPEED_MIN = -5
export(int) var ROTATION_SPEED_MAX = 5

# warning-ignore:unused_class_variable
var PlayerStats = Utils.get_player_stats()  # Used in inherited instances
var rotation_speed = ROTATION_SPEED_MIN


func _ready():
	rotation_speed = rand_range(ROTATION_SPEED_MIN, ROTATION_SPEED_MAX)


func _physics_process(delta):
	rotation += rotation_speed * delta
	position.x += -SPEED * delta


func _pickup():
	SoundFx.play("Pickup", 2, -10)
