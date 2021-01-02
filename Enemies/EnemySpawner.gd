extends Node2D

const FlameEnemy = preload("res://Enemies/FlameEnemy.tscn")

export(int) var MAX_ENEMIES = 75
export(float) var MAX_ENEMY_GROUP = 10
export(float) var SPAWN_COOLDOWN = 1.0

var can_spawn = true setget set_can_spawn
var low_spawners = null
var mid_spawners = null
var high_spawners = null

onready var lowGroup = $LowGroup
onready var midGroup = $MidGroup
onready var highGroup = $HighGroup
onready var cooldownTimer = $CooldownTimer
onready var startupTimer = $StartupTimer


func _ready():
	set_process(false)
	low_spawners = lowGroup.get_children()
	mid_spawners = midGroup.get_children()
	high_spawners = highGroup.get_children()
	startupTimer.start(SPAWN_COOLDOWN)


func _process(_delta):
	if not self.can_spawn:
		return  # Don't bother
	
	if len(get_tree().get_nodes_in_group("Enemy")) >= MAX_ENEMIES:
		print("DEBUG: Max enemies reached!")
		return
	
	var group_size = 0
	var beats = BeatDetector.get_beats_now()
	for beat in beats:
		if group_size >= MAX_ENEMY_GROUP:
			print("DEBUG: Max enemy group reached!")
			break

		spawn_enemy(beat)
		group_size += 1
	
	if group_size > 0:
		self.can_spawn = false


func spawn_enemy(beat):
	var spawners = null
	if beat.freq_range == AudioPlayers.FrequencyRange.LOW:
		spawners = low_spawners
	elif beat.freq_range == AudioPlayers.FrequencyRange.MID:
		spawners = mid_spawners
	else:
		spawners = high_spawners

	spawners.shuffle()
	Utils.instance_scene_on_main(FlameEnemy, spawners[0].global_position)


func set_can_spawn(value):
	can_spawn = value
	if not can_spawn:
		cooldownTimer.start(SPAWN_COOLDOWN)


func _on_CooldownTimer_timeout():
	self.can_spawn = true


func _on_StartupTimer_timeout():
	set_process(true)
