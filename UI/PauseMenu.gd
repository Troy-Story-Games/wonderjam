extends ColorRect

var playerStats : PlayerStats = Utils.get_player_stats()
var paused = false setget set_paused


func _ready():
	# We don't start out paused
	visible = false


func set_paused(value):
	paused = value
	get_tree().paused = paused
	visible = paused
	if paused:
		AudioPlayers.pause_song()
	else:
		AudioPlayers.resume_song()


func _process(_delta):
	var player_alive = get_tree().get_nodes_in_group("Player").size() > 0
	if Input.is_action_just_pressed("ui_cancel") and player_alive:
		self.paused = !paused


func _on_Giveup_pressed():
	SoundFx.play("Click")
	self.paused = false
	playerStats.call_deferred("emit_signal", "player_died")


func _on_Continue_pressed():
	SoundFx.play("Click")
	self.paused = false
