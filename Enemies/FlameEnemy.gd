extends Enemy

export(int) var ACCELERATION = 100
export(int) var SPEED = 250

var flameMaterial = null

onready var flames = $Flames


func _ready():
	flameMaterial = flames.get_material()


func _physics_process(delta):
	position.x -= SPEED * delta


func _on_EnemyStats_health_changed(value):
	var remaining_health_ratio = 1.0
	if stats != null:
		remaining_health_ratio = 0.75 + ((value / float(stats.max_health)) * 0.25)

	if flameMaterial != null:
		flameMaterial.set_shader_param("scale", remaining_health_ratio)
