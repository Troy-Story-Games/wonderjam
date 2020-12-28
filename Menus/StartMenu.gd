extends Control

export(String, FILE, "*.tscn") var HOME_WORLD_SCENE = "res://MainGame/Home/Home.tscn"

onready var fileDialog = $FileDialog


func _on_PlayButton_pressed():
	fileDialog.popup_centered()


func _on_FileDialog_file_selected(path):
	BeatDetector.preload_song(path)
	get_tree().change_scene(HOME_WORLD_SCENE)
