extends Node2D

const Splode = preload("res://Effects/Splode.tscn")

enum GameState {
	LOADING,
	PLAYING
}

var state = GameState.LOADING

onready var progressBar = $CanvasLayer/ProgressBar
onready var beatDetector = $BeatDetector


func _process(delta):
	match state:
		GameState.LOADING:
			progressBar.value = beatDetector.get_preload_progress()
		GameState.PLAYING:
			var beats = beatDetector.get_beats_now()
			if beats:
				for beat in beats:
					var w = int(1280 / 6)
					var splode = Utils.instance_scene_on_main(Splode, Vector2(w * beat.idx + w / 2, 500 + 150))
					splode.emitting = true
					splode.lifetime = 0.15
					splode.get_child(0).wait_time = 0.16


func _on_BeatDetector_preload_done():
	beatDetector.start_main_song()
	state = GameState.PLAYING
