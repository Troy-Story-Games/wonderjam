extends Node

const Footprint = preload("res://Player/Footprint.tscn")

onready var progressBar = $UI/ProgressBar


func _ready():
	BeatDetector.connect("preload_done", self, "_on_BeatDetector_preload_done")
	Events.connect("footprint", self, "_on_footprint")


func _process(delta):
	progressBar.value = BeatDetector.get_preload_progress()


func _on_BeatDetector_preload_done():
	get_tree().change_scene("res://MainGame/PlaySong/AboveClouds.tscn")


func _on_footprint(pos, scale):
	var snow_path = find_node("SnowPath", false)
	var instance = Footprint.instance()
	instance.scale = scale
	snow_path.add_child(instance)
	instance.global_position = pos
