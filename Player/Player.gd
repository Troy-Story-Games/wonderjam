extends KinematicBody2D

enum PlayerState {
	WALKING,
	FLYING
}

export (int) var ACCELERATION = 900
export (int) var MAX_SPEED = 200
export(int) var GRAVITY = 600
export(int) var JUMP_FORCE = 250
export (float) var FRICTION = 0.75
export (PlayerState) var STATE = PlayerState.WALKING

var PlayerStats = Utils.get_player_stats()
var MainInstances = Utils.get_main_instances()

var motion = Vector2.ZERO
var state = PlayerState.WALKING setget set_state
var just_jumped = false
var double_jump = true

onready var sprite = $Sprite
onready var snowSchloop = $SnowSchloop


func _init():
	MainInstances.player = self


func _ready():
	self.state = STATE
	PlayerStats.connect("player_died", self, "_on_died")


func _physics_process(delta):
	var input_vector = get_input_vector()
	
	match self.state:
		PlayerState.WALKING:
			"""
			When we're in the loading world we can walk around
			"""
			apply_horizontal_force(input_vector, delta)
			apply_horizontal_friction(input_vector)
			jump_check()
			apply_gravity(delta)
			move_walking()
		PlayerState.FLYING:
			"""
			This is when we're actually playing (above or below clouds)
			"""
			apply_force(input_vector, delta)
			apply_friction(input_vector)
			check_landed()
			move_flying(delta)


func set_state(value):
	state = value
	
	match state:
		PlayerState.WALKING:
			snowSchloop.visible = false
		PlayerState.FLYING:
			snowSchloop.visible = true


func get_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	return input_vector


func apply_horizontal_force(input_vector, delta):
	"""
	Used when in PlayerState.WALKING
	"""
	if input_vector.x != 0:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)


func apply_force(input_vector, delta):
	"""
	Used when in PlayerState.FLYING
	"""
	if input_vector != Vector2.ZERO:
		motion += input_vector * ACCELERATION * delta
		motion = motion.clamped(MAX_SPEED)


func apply_horizontal_friction(input_vector):
	"""
	Used when in PlayerState.WALKING
	"""
	if input_vector.x == 0 and is_on_floor():
		motion.x = lerp(motion.x, 0, FRICTION)


func apply_friction(input_vector):
	"""
	Used when in PlayerState.FLYING
	"""
	if input_vector == Vector2.ZERO:
		motion = motion.linear_interpolate(Vector2.ZERO, FRICTION)


func check_landed():
	if is_on_floor() and self.state == PlayerState.FLYING:
		self.state = PlayerState.WALKING


func jump_check():
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			jump(JUMP_FORCE)
			just_jumped = true
	else:
		if Input.is_action_just_released("jump") and motion.y < -JUMP_FORCE / 2:
			motion.y = -JUMP_FORCE / 2

		if Input.is_action_just_pressed("jump") and double_jump == true:
			# Handle double jump
			jump(JUMP_FORCE * 0.75)
			double_jump = false

	# Double jump to fly
	if motion.y > 0 and double_jump == false:
		# The player has just begun to fall after a double jump
		# Switch to flying
		self.state = PlayerState.FLYING


func jump(force):
	motion.y = -force


func apply_gravity(delta):
	if not is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE)


func move_walking():
	"""
	Used when state is PlayerState.WALKING
	"""
	# Capture properties of motion prior to moving
	# We use them after moving to fix some 
	# move_and_slide_with_snap issues
	var was_in_air = not is_on_floor()

	motion = move_and_slide(motion, Vector2.UP)

	# Happens on landing
	if was_in_air and is_on_floor():
		double_jump = true


func move_flying(delta):
	"""
	Used when state is PlayerState.FLYING 
	"""
	motion = move_and_slide(motion, Vector2.UP)
