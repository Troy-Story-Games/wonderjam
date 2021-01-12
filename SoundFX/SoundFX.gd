extends Node

var sounds_path = "res://SoundFX/"
var sounds = {
	"Pickup": load(sounds_path + "phaserUp7.ogg"),
}

onready var sound_players = get_children()


func play(sound_string, pitch_scale=1, volume_db=0):
	for player in sound_players:
		if not player.playing:
			player.pitch_scale = pitch_scale
			player.volume_db = volume_db
			player.stream = sounds[sound_string]
			player.play()
			return
	print("WARN: Too many sounds playing at once!")
