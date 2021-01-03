extends Node

const Footprint = preload("res://Player/Footprint.tscn")

onready var fadeLayer = $FadeLayer

var preload_done = false
var player = null


func _ready():
	fadeLayer.fade_in()
	preload_done = BeatDetector.is_preload_done
	BeatDetector.connect("preload_done", self, "_on_BeatDetector_preload_done")
	Events.connect("footprint", self, "_on_footprint")


func _input(event):
	if event.is_action_pressed("ui_up") and player != null:
		fadeLayer.fade_out()


func _on_BeatDetector_preload_done():
	preload_done = true


func _on_footprint(pos, scale):
	"""
	Handle placing a footprint on the snow path
	"""
	var snow_path = find_node("SnowPath")
	var instance = Footprint.instance()
	instance.scale = scale
	snow_path.add_child(instance)
	instance.global_position = pos


func _on_EnterHouseArea_body_entered(body):
	if body is Player:
		player = body


func _on_EnterHouseArea_body_exited(body):
	if body is Player:
		player = null


func _on_FadeLayer_fade_out_complete():
	if preload_done:
		get_tree().change_scene("res://MainGame/PlaySong/AboveClouds.tscn")
	else:
		get_tree().change_scene("res://MainGame/Home/InsideHouse.tscn")
