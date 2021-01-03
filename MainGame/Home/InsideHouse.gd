extends Node

var player = null
var preload_done = false

onready var fadeLayer = $FadeLayer
onready var fileDialog = $UI/FileDialog

func _ready():
	fadeLayer.fade_in()
	preload_done = BeatDetector.is_preload_done
	BeatDetector.connect("preload_done", self, "_on_BeatDetector_preload_done")


func _input(event):
	if event.is_action_pressed("ui_up") and player != null:
		fileDialog.popup_centered()


func _on_BeatDetector_preload_done():
	preload_done = true


func _on_FadeLayer_fade_out_complete():
	if preload_done:
		get_tree().change_scene("res://MainGame/PlaySong/AboveClouds.tscn")
	else:
		get_tree().change_scene("res://MainGame/Home/Home.tscn")


func _on_ExitArea_body_entered(body):
	if body is Player:
		fadeLayer.fade_out()


func _on_Area2D_body_entered(body):
	if body is Player:
		player = body


func _on_Area2D_body_exited(body):
	if body is Player:
		player = null


func _on_FileDialog_file_selected(path):
	BeatDetector.preload_song(path)
