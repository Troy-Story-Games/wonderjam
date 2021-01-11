extends Node
class_name AboveClouds

# This is const rather than export b/c it has
# UI display implications
const MAX_SCORE = 999999999

export(int) var MULTIPLIER_EXPLODE_THRESHOLD = 10
export(int) var MAX_MULTIPLIER = 100
export(int) var STARTING_SCROLL_SPEED = 250
export(int) var MAX_SCROLL_SPEED = 3000
export(int) var SCROLL_ACCELERATION = 150
export(float) var SCROLL_FRICTION = 0.02

var PlayerStats = Utils.get_player_stats()
var boost = false
var speed = 0 setget set_speed
var score = 0 setget set_score
var multiplier_splosion_threshold = 0
var multiplier = 1 setget set_multiplier

onready var fadeLayer = $FadeLayer
onready var highBackground = $HighBackground
onready var scoreLabel = $UI/ScoreDisplay/Score
onready var multiplierLabel = $UI/ScoreDisplay/Multiplier
onready var scoreExplosion = $ForegroundLayer/ScoreExplosion
onready var animationPlayer = $AnimationPlayer
onready var deathTimeout = $DeathTimeout


func _ready():
	fadeLayer.fade_in()
	AudioPlayers.start_main_song()
	# warning-ignore:return_value_discarded
	AudioPlayers.connect("song_complete", self, "_on_AudioPlayers_song_complete")
	# warning-ignore:return_value_discarded
	Events.connect("score_points", self, "_on_Events_score_points")
	PlayerStats.connect("player_died", self, "_on_PlayerStats_player_died")
	self.speed = STARTING_SCROLL_SPEED
	self.score = 0
	self.multiplier = 1
	multiplier_splosion_threshold = MULTIPLIER_EXPLODE_THRESHOLD


func _physics_process(delta):
	var bpm_beats = BackgroundMusicAnalyzer.bpmDetector.get_beats_now()

	if len(bpm_beats) > 0:
		boost = true
		if self.multiplier == MAX_MULTIPLIER:
			# Play to the beat when they max out!
			animationPlayer.play("ScoreIncrease")

	if boost:
		self.speed = lerp(self.speed, MAX_SCROLL_SPEED, SCROLL_ACCELERATION * delta)
	else:
		self.speed = lerp(self.speed, STARTING_SCROLL_SPEED, SCROLL_FRICTION)


func set_speed(value):
	speed = clamp(value, STARTING_SCROLL_SPEED, MAX_SCROLL_SPEED)
	highBackground.SCROLL_SPEED = speed
	
	if speed >= (MAX_SCROLL_SPEED / 1.5) and boost:
		boost = false


func set_multiplier(value):
	multiplier = clamp(value, 1, MAX_MULTIPLIER)
	multiplierLabel.text = " x" + str(multiplier)
	
	if multiplier >= multiplier_splosion_threshold:
		multiplier_splosion_threshold += MULTIPLIER_EXPLODE_THRESHOLD
		scoreExplosion.emitting = true


func set_score(value):
	score = clamp(value, 0, MAX_SCORE)
	scoreLabel.text = str(score)
	if self.multiplier < MAX_MULTIPLIER:
		animationPlayer.play("ScoreIncrease")


func add_score(points):
	self.score += points * self.multiplier
	self.multiplier += 1


func get_speed_factor():
	var top_speed = MAX_SCROLL_SPEED - STARTING_SCROLL_SPEED
	return float(speed / top_speed)


func _on_AudioPlayers_song_complete(path):
	SaveAndLoad.complete_song(path, score)
	fadeLayer.fade_out()


func _on_Events_score_points(points):
	add_score(points)


func _on_FadeLayer_fade_out_complete():
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://MainGame/Home/InsideHouse.tscn")


func _on_Player_take_damage(_damage):
	self.multiplier = 1


func _on_PlayerStats_player_died():
	AudioPlayers.fade_out_song()
	deathTimeout.start()


func _on_DeathTimeout_timeout():
	fadeLayer.fade_out()
