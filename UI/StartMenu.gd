extends Node

onready var animationPlayer = $AnimationPlayer
onready var camera2D = $Camera2D
onready var fadeLayer = $FadeLayer


func _ready():
	fadeLayer.fade_in()
	camera2D.zoom = Vector2.ONE


func _input(event):
	if event.is_action("ui_accept"):
		animationPlayer.play("Zoom")


func _on_FadeLayer_fade_out_complete():
	get_tree().change_scene("res://MainGame/Home/InsideHouse.tscn")
