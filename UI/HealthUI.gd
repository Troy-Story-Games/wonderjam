extends Control

var PlayerStats = Utils.get_player_stats()

var flakes = 0 setget set_flakes
var texture_width = 0

onready var healthBar = $HealthBar

func _ready():
	texture_width = healthBar.texture.get_width()

	# warning-ignore:return_value_discarded
	PlayerStats.connect("player_health_changed", self, "set_flakes")

	self.flakes = PlayerStats.health


func set_flakes(value):
	flakes = clamp(value, 0, PlayerStats.max_health)
	if flakes > 0:
		healthBar.rect_size.x = flakes * texture_width
	else:
		healthBar.visible = false
