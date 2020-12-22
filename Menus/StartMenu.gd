extends Control

var MainInstances = Utils.get_main_instances()

onready var fileDialog = $FileDialog


func _on_Button_pressed():
	fileDialog.popup_centered()


func _on_FileDialog_file_selected(path):
	print("You selected: ", path)
	MainInstances.songFilePath = path
	get_tree().change_scene("res://World/Home.tscn")
