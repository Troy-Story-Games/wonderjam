extends Particles2D

var velocity = 0

onready var collider = $Hitbox/Collider


func _ready():
	# This is instantiated by code and then auto-freed after a few seconds
	# We want to auto-toggle emitting to true when ready
	emitting = true
	collider.disabled = false
	collider.shape.radius = 0
	velocity = process_material.initial_velocity


func _physics_process(delta):
	collider.shape.radius += velocity * delta


func _on_Timer_timeout():
	queue_free()
