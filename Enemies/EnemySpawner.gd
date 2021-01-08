extends Node2D

const FlameEnemy = preload("res://Enemies/FlameEnemy.tscn")

export(int) var MAX_ENEMIES = 5
export(int) var ENEMY_CLUSTER_SIZE = 3
export(float) var SPAWN_STARTUP_DELAY = 1.5
export(float) var SPAWN_COOLDOWN = 1.5

var can_spawn = false setget set_can_spawn
var spawners = []
var high_cluster = 0
var mid_cluster = 0
var low_cluster = 0
var last_low_spawner = null
var last_mid_spawner = null
var last_high_spawner = null

onready var cooldownTimer = $CooldownTimer
onready var startupTimer = $StartupTimer
onready var spawnPositions = $SpawnPositions


func _ready():
	startupTimer.start(SPAWN_STARTUP_DELAY)


func _process(_delta):
	if len(get_tree().get_nodes_in_group("Enemy")) >= MAX_ENEMIES:
		self.can_spawn = false
		cooldownTimer.start(SPAWN_COOLDOWN)  # Don't try again for a few seconds
		return

	if high_cluster >= ENEMY_CLUSTER_SIZE:
		high_cluster = 0
		last_high_spawner = null
	if mid_cluster >= ENEMY_CLUSTER_SIZE:
		mid_cluster = 0
		last_mid_spawner = null
	if low_cluster >= ENEMY_CLUSTER_SIZE:
		low_cluster = 0
		last_low_spawner = null

	spawners = spawnPositions.get_children()

	var low_beats = BackgroundMusicAnalyzer.peakDetector.get_low_peaks_now()
	var high_beats = BackgroundMusicAnalyzer.peakDetector.get_high_peaks_now()
	var mid_beats = BackgroundMusicAnalyzer.peakDetector.get_mid_peaks_now()

	if len(low_beats) > 0:
		last_low_spawner = spawn_enemy(last_low_spawner)
		low_cluster += 1
	if len(mid_beats) > 0:
		last_mid_spawner = spawn_enemy(last_mid_spawner)
		mid_cluster += 1
	if len(high_beats) > 0:
		last_high_spawner = spawn_enemy(last_high_spawner)
		high_cluster += 1


func spawn_enemy(spawner):
	if spawner == null:
		# Randomly select a spawner
		spawners.shuffle()
		spawner = spawners.pop_front()

	spawner.spawn_enemy(FlameEnemy)
	return spawner


func set_can_spawn(value):
	can_spawn = value
	if not can_spawn:
		cooldownTimer.start(SPAWN_COOLDOWN)

	set_process(can_spawn)


func _on_CooldownTimer_timeout():
	self.can_spawn = true


func _on_StartupTimer_timeout():
	self.can_spawn = true
