extends Node

onready var progressBar = $UI/ProgressBar


func _ready():
	BeatDetector.connect("preload_done", self, "_on_BeatDetector_preload_done")


func _process(delta):
	progressBar.value = BeatDetector.get_preload_progress()


func _on_BeatDetector_preload_done():
	get_tree().change_scene("res://MainGame/PlaySong/AboveClouds.tscn")
