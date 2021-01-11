extends Node
class_name EnemyStats

export(int) var max_health = 1 setget set_max_health
export(int) var points = 10

var health = max_health setget set_health

signal no_health()
signal health_changed(value)
signal max_health_changed(value)


func _ready():
	self.health = self.max_health


func set_max_health(value):
	max_health = value
	self.health = min(self.health, max_health)
	emit_signal("max_health_changed", max_health)


func set_health(value):
	health = clamp(value, 0, self.max_health)
	emit_signal("health_changed", health)
	if health <= 0:
		Events.emit_signal("score_points", points)
		emit_signal("no_health")
