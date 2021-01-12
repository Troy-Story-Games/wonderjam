extends Control

var PlayerStats = Utils.get_player_stats()

var bombs = 0 setget set_bombs
var texture_width = 0

onready var bombBar = $BombBar

func _ready():
	texture_width = bombBar.texture.get_width()

	# warning-ignore:return_value_discarded
	PlayerStats.connect("player_bombs_changed", self, "set_bombs")

	self.bombs = PlayerStats.bombs


func set_bombs(value):
	bombs = clamp(value, 0, PlayerStats.max_bombs)
	if bombs > 0:
		bombBar.visible = true
		bombBar.rect_size.x = bombs * texture_width
	else:
		bombBar.visible = false
