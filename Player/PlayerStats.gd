extends Resource
class_name PlayerStats

var max_health = 4
var max_bombs = 3
var health = max_health setget set_health
var bombs = max_bombs setget set_bombs

signal player_died()
signal player_health_changed(value)
signal player_bombs_changed(value)


func set_health(value):
	health = clamp(value, 0, max_health)

	emit_signal("player_health_changed", health)

	if health == 0:
		emit_signal("player_died")


func set_bombs(value):
	bombs = clamp(value, 0, max_bombs)
	emit_signal("player_bombs_changed", bombs)


func refill_stats():
	self.health = max_health
	self.bombs = max_bombs
