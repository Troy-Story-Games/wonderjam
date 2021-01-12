extends Node

onready var animationPlayer = $AnimationPlayer
onready var camera2D = $Camera2D
onready var fadeLayer = $FadeLayer


func _ready():
	randomize()
	BackgroundGameMusic.fade_in()
	fadeLayer.fade_in()
	camera2D.zoom = Vector2.ONE


func _unhandled_input(event):
	if event.is_pressed():
		animationPlayer.play("Zoom")


func _on_FadeLayer_fade_out_complete():
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://MainGame/Home/InsideHouse.tscn")
