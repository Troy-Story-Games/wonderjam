extends Enemy

const FlameBullet = preload("res://Enemies/FlameBullet.tscn")

export(int) var BULLET_SPEED = 250
export(float) var SPREAD = 100
export(float) var BULLET_FIRE_MIN_WAIT = 0.25
export(float) var BULLET_FIRE_MAX_WAIT = 0.5
export(float) var BULLET_FIRE_CHANCE = 0.5
export(int) var BULLET_FIRE_MAX = 6

var PlayerStats = Utils.get_player_stats()
var flameMaterial = null
var player = null

onready var flames = $Sprite/Flames
onready var fireDirection = $FireDirection
onready var bulletSpawnPoint = $BulletSpawnPoint
onready var bulletTimer = $BulletTimer


func _ready():
	PlayerStats.connect("player_died", self, "_on_PlayerStats_player_died")
	flameMaterial = flames.get_material()
	player = get_tree().current_scene.find_node("Player")
	if rand_range(0.0, 1.0) <= BULLET_FIRE_CHANCE:
		var wait = rand_range(BULLET_FIRE_MIN_WAIT, BULLET_FIRE_MAX_WAIT)
		bulletTimer.start(wait)


func _on_EnemyStats_health_changed(value):
	var remaining_health_ratio = 1.0
	if stats != null:
		remaining_health_ratio = 0.75 + ((value / float(stats.max_health)) * 0.25)

	if flameMaterial != null:
		flameMaterial.set_shader_param("scale", remaining_health_ratio)


func fire_bullet():
	var bullet = Utils.instance_scene_on_main(FlameBullet, bulletSpawnPoint.global_position)
	var velocity = bullet.global_position.direction_to(fireDirection.global_position) * BULLET_SPEED
	
	if player != null:
		velocity = bullet.global_position.direction_to(player.global_position) * BULLET_SPEED

	velocity = velocity.rotated(deg2rad(rand_range(-SPREAD / 2, SPREAD / 2)))
	bullet.velocity = velocity


func _on_BulletTimer_timeout():
	var num = randi() % BULLET_FIRE_MAX + 1
	for _idx in range(num):
		fire_bullet()


func _on_PlayerStats_player_died():
	player = null
