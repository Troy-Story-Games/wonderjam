extends KinematicBody2D
class_name Player

enum PlayerState {
	WALKING,
	FLYING
}

export (int) var ACCELERATION = 900
export (int) var MAX_SPEED = 200
export(int) var GRAVITY = 600
export(int) var FOOTPRINT_WIDTH = 60
export (float) var FRICTION = 0.75
export (PlayerState) var STATE = PlayerState.WALKING

var PlayerStats = Utils.get_player_stats()

var motion = Vector2.ZERO
var state = PlayerState.WALKING setget set_state
var place_right_foot = true
var distance_since_last_footprint = 0.0

onready var flyingSprite = $FlyingSprite
onready var walkingSprite = $WalkingSprite
onready var snowSchloop = $SnowSchloop
onready var animationPlayer = $AnimationPlayer
onready var iceBeam = $IceBeam
onready var rightFootPosition = $RightFootPosition
onready var leftFootPosition = $LeftFootPosition
onready var snowJetParticles = $SnowJetParticles
onready var snowParticles = $SnowParticles


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
			apply_gravity(delta)
			update_animations(input_vector)
			move()
			place_footprint(delta)
		PlayerState.FLYING:
			"""
			This is when we're actually playing (above or below clouds)
			"""
			apply_force(input_vector, delta)
			apply_friction(input_vector)
			move()


func set_state(value):
	state = value
	
	match state:
		PlayerState.WALKING:
			snowSchloop.visible = false
			flyingSprite.visible = false
			walkingSprite.visible = true
			iceBeam.visible = false
			snowParticles.emitting = false
			snowJetParticles.emitting = false
			snowJetParticles.visible = false
			snowParticles.visible = false
		PlayerState.FLYING:
			snowSchloop.visible = true
			walkingSprite.visible = false
			flyingSprite.visible = true
			iceBeam.visible = true
			snowJetParticles.emitting = true
			snowParticles.emitting = true
			snowJetParticles.visible = true
			snowParticles.visible = true


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


func apply_gravity(delta):
	"""
	This is just used to plop the player to the ground from where they spawn
	"""
	if not is_on_floor():
		motion.y += GRAVITY * delta


func place_footprint(delta):
	"""
	Place the footprints
	"""
	var pos = Vector2.ZERO
	var scale = Vector2.ONE
	distance_since_last_footprint += abs(motion.x) * delta
	if distance_since_last_footprint >= FOOTPRINT_WIDTH:
		distance_since_last_footprint = 0.0
		scale.x = walkingSprite.scale.x

		if place_right_foot:
			Events.emit_signal("footprint", rightFootPosition.global_position, scale)
			place_right_foot = false
		else:
			scale.y = -1
			Events.emit_signal("footprint", leftFootPosition.global_position, scale)
			place_right_foot = true


func update_animations(input_vector):
	match self.state:
		PlayerState.WALKING:
			if input_vector.x != 0:
				walkingSprite.scale.x = sign(input_vector.x)
				animationPlayer.play("Walking")
			else:
				animationPlayer.play("Idle")
		PlayerState.FLYING:
			pass  # TODO


func move():
	motion = move_and_slide(motion, Vector2.UP)
