extends KinematicBody2D

export (int) var ACCELERATION = 512
export (int) var MAX_SPEED = 64
export (float) var FRICTION = 0.25

var motion = Vector2.ZERO

onready var sprite = $Sprite

func _physics_process(delta):
	var input_vector = get_input_vector()
	apply_force(input_vector, delta)
	apply_friction(input_vector)
	move()
		
func get_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	return input_vector	
		
func apply_force(input_vector, delta):	
	if input_vector != Vector2.ZERO:
		motion += input_vector * ACCELERATION * delta	
		motion = motion.clamped(MAX_SPEED)
		
func apply_friction(input_vector):
	if input_vector == Vector2.ZERO:
		motion = motion.linear_interpolate(Vector2.ZERO, FRICTION)
	
func move():
	#motion = move_and_slide(motion)
	var size = Vector2(27,31)
	position.x = clamp(position.x + motion.x, size.x/2, get_viewport_rect().size.x - size.x/2)
	position.y = clamp(position.y + motion.y, size.y/2, get_viewport_rect().size.y - size.y/2)
		
		
		
		
