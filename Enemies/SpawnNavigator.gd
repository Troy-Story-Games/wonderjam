extends Position2D

onready var navigation2D = $Navigation2D
onready var endPoint = $EndPoint


func spawn_enemy(PackedEnemyScene):
	var instance = PackedEnemyScene.instance()
	navigation2D.add_child(instance)
	instance.global_position = global_position
	instance.nav_path = navigation2D.get_simple_path(instance.position, endPoint.position)
