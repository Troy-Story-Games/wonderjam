extends KinematicBody2D
class_name Enemy

const ExplodeEffect = preload("res://Effects/ExplodeEffect.tscn")

onready var stats = $EnemyStats


func _on_EnemyStats_no_health():
	var instance = Utils.instance_scene_on_main(ExplodeEffect, global_position)
	instance.emitting = true
	queue_free()


func _on_Hurtbox_take_damage(damage, area):
	stats.health -= damage
