extends Node2D

enum GameState {
	LOADING,
	PLAYING
}

var state = GameState.LOADING

onready var progressBar = $ProgressBar
onready var beatDetector = $BeatDetector


func _process(delta):
	match state:
		GameState.LOADING:
			progressBar.value = beatDetector.get_preload_progress()


func _on_BeatDetector_preload_done():
	beatDetector.start_main_song()
	state = GameState.PLAYING
