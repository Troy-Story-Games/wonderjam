extends RayCast2D

var is_casting = false setget set_is_casting

onready var line2D = $Line2D
onready var tween = $Tween
onready var beamSourceParticles = $BeamSourceParticles
onready var beamImpactParticles = $BeamImpactParticles
onready var beamSparkles = $BeamSparkles


func _ready():
	set_physics_process(false)
	line2D.points[1] = Vector2.ZERO


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

	line2D.points[1] = cast_point

	beamSparkles.position = cast_point * 0.5
	beamSparkles.process_material.emission_box_extents.x = cast_point.length() * 0.5


func set_is_casting(value):
	is_casting = value

	beamSparkles.emitting = is_casting
	beamSourceParticles.emitting = is_casting
	if is_casting:
		appear()
	else:
		beamImpactParticles.emitting = false
		disappear()

	set_physics_process(is_casting)


func appear():
	tween.stop_all()
	tween.interpolate_property(line2D, "width", 0, 10.0, 0.2)
	tween.start()
	

func disappear():
	tween.stop_all()
	tween.interpolate_property(line2D, "width", 10.0, 0, 0.1)
	tween.start()
