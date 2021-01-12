extends KinematicBody2D
class_name Enemy

const ExplodeEffect = preload("res://Effects/ExplodeEffect.tscn")

export(int) var NAV_SPEED = 400
export(int) var SPEED = 100
export(int) var NAV_POINT_TARGET_RANGE = 10
export(bool) var DROP_ITEM_ON_DEATH = true
export(float) var DROP_CHANCE = 0.05

var nav_path = PoolVector2Array()

onready var stats = $EnemyStats


func _physics_process(delta):
	if nav_path.size() == 0:
		position.x += -SPEED * delta
		return

	var move_amnt = NAV_SPEED * delta
	move_along_path(move_amnt)


func move_along_path(move_amnt):
	var start_point = position
	var dist_to_next = start_point.distance_to(nav_path[0])
	if move_amnt > dist_to_next:
		move_amnt = dist_to_next
	
	position = start_point.move_toward(nav_path[0], move_amnt)
	
	if position.distance_to(nav_path[0]) <= NAV_POINT_TARGET_RANGE:
		nav_path.remove(0)


func _on_EnemyStats_no_health():
	var instance = Utils.instance_scene_on_main(ExplodeEffect, global_position)
	instance.emitting = true
	if DROP_ITEM_ON_DEATH:
		Utils.drop_random_item(global_position, DROP_CHANCE)
	queue_free()


func _on_Hurtbox_take_damage(damage, _area):
	stats.health -= damage


func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
