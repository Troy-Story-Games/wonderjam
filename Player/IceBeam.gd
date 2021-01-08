extends RayCast2D

export(float) var LINE_WIDTH = 10.0
export(float) var PULSE_LINE_WIDTH = 15.0
export(int) var DAMAGE = 1
export(float) var DAMAGE_INTERVAL = 0.25

var is_casting = false setget set_is_casting
var line2DMaterial = null

onready var line2D = $Line2D
onready var appearTween = $AppearTween
onready var beamSourceParticles = $BeamSourceParticles
onready var beamImpactParticles = $BeamImpactParticles
onready var beamSparkles = $BeamSparkles
onready var animationPlayer = $AnimationPlayer
onready var hitboxCollider = $Hitbox/Collider
onready var hitbox = $Hitbox
onready var damageTimer = $DamageTimer


func _ready():
	set_physics_process(false)
	line2D.points[1] = Vector2.ZERO
	line2DMaterial = line2D.get_material() as ShaderMaterial

	# We programmatically build the "Pulse" animation so
	# we can easily edit the export above without
	# also needed to update the animation player
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, "Line2D:width")
	animation.track_insert_key(track_index, 0.0, LINE_WIDTH)
	animation.track_insert_key(track_index, 0.5, PULSE_LINE_WIDTH)
	animation.track_insert_key(track_index, 1.0, LINE_WIDTH)
	animationPlayer.add_animation("Pulse", animation)

	# Set the damage on the hitbox so we don't have to come into this scene
	# and set it on the hitbox manually. Disable it by default.
	hitbox.DAMAGE = DAMAGE
	hitboxCollider.disabled = true


func _input(event):
	if event.is_action_pressed("shoot"):
		self.is_casting = true
	elif event.is_action_released("shoot"):
		self.is_casting = false


func _physics_process(delta):
	var cast_point = cast_to
	force_raycast_update()
	
	beamImpactParticles.emitting = is_colliding()
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
		beamImpactParticles.global_rotation = get_collision_normal().angle()
		beamImpactParticles.position = cast_point
		hitbox.position = cast_point
		if damageTimer.time_left == 0:
			hitboxCollider.disabled = false
			damageTimer.start(DAMAGE_INTERVAL)

	line2D.points[1] = cast_point

	beamSparkles.position = cast_point * 0.5
	beamSparkles.process_material.emission_box_extents.x = cast_point.length() * 0.5
	
	if not appearTween.is_active():
		if len(BackgroundMusicAnalyzer.bpmDetector.get_beats_now()) > 0:
			pulse()


func set_is_casting(value):
	is_casting = value

	beamSparkles.emitting = is_casting
	beamSourceParticles.emitting = is_casting

	if is_casting:
		appear()
	else:
		hitbox.position = Vector2.ZERO
		beamImpactParticles.emitting = false
		disappear()

	set_physics_process(is_casting)


func pulse(speed=0.3):
	speed = 1 / speed  # Speed needs to be greater than 1 to increase speed
	if not animationPlayer.is_playing():
		animationPlayer.playback_speed = speed
		animationPlayer.play("Pulse")
	else:
		animationPlayer.playback_speed *= 1.5


func appear():
	animationPlayer.stop()
	appearTween.remove_all()
	appearTween.interpolate_property(line2D, "width", 0, LINE_WIDTH, 0.1)
	appearTween.start()


func disappear():
	animationPlayer.stop()
	appearTween.remove_all()
	appearTween.interpolate_property(line2D, "width", LINE_WIDTH, 0, 0.1)
	appearTween.start()


func _on_DamageTimer_timeout():
	hitboxCollider.disabled = true
