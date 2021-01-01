extends Node

enum FrequencyRange {
	LOW,
	MID,
	HIGH
}

const MAX_DB = 0
const MIN_DB = -40
const COMPENSATE_FRAMES = 2
const COMPENSATE_HZ = 60.0
const FREQ_MAX = 11050.0
const FREQ_MIN = 20

var max_db = MAX_DB
var min_db = MIN_DB

onready var mainAudioPlayer = $MainAudioPlayer
onready var backAudioPlayer = $BackAudioPlayer


func _ready():
	# Get the index for our back song
	var back_bus_idx = AudioServer.get_bus_index("BackSong")

	# Mute the background song
	AudioServer.set_bus_mute(back_bus_idx, true)
	
	min_db = MIN_DB + mainAudioPlayer.volume_db
	max_db = MAX_DB + mainAudioPlayer.volume_db


func get_adjusted_playback_time():
	# Get the playback time that it really is for this frame (e.g slightly
	# in the future but that's fine b/c we preload the song and do preprocessing)
	return mainAudioPlayer.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() + (1 / COMPENSATE_HZ) * COMPENSATE_FRAMES


func get_background_playback_position():
	return backAudioPlayer.get_playback_position() + AudioServer.get_time_since_last_mix()


func get_energy_for_frequency_range(spectrum, freq_low, freq_high):
	var mag = spectrum.get_magnitude_for_frequency_range(freq_low, freq_high)
	mag = linear2db(mag.length())
	mag = (mag - min_db) / (max_db - min_db)
	mag += 0.3 * (freq_low - FREQ_MIN) / (FREQ_MAX - FREQ_MIN)
	return clamp(mag, 0.05, 1)


func get_min_db():
	return min_db


func get_max_db():
	return max_db


func load_song(path):
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_buffer(file.get_len())
	file.close()
	load_streams(path, content)


func load_streams(song_file_path, file_bytes):
	"""
	Load the streams (both foreground and background)
	
	:param path: The file path for the song so we can check file extension
	:param file_bytes: The content of the file as bytes
	"""
	var back_stream = null
	var main_stream = null
	
	# Create the appropriate stream
	if song_file_path.ends_with(".mp3"):
		print("DEBUG: Load MP3: ", song_file_path)
		main_stream = AudioStreamMP3.new()
		back_stream = AudioStreamMP3.new()
		main_stream.data = file_bytes
		back_stream.data = file_bytes
	elif song_file_path.ends_with(".ogg"):
		print("DEBUG: Load OGG: ", song_file_path)
		main_stream = AudioStreamOGGVorbis.new()
		back_stream = AudioStreamOGGVorbis.new()
		main_stream.data = file_bytes
		back_stream.data = file_bytes
	else:
		print("DEBUG: Load WAV: ", song_file_path)
		main_stream = AudioStreamSample.new()
		back_stream = AudioStreamSample.new()
		main_stream.data = file_bytes
		back_stream.data = file_bytes

	backAudioPlayer.stream = back_stream
	backAudioPlayer.set_bus("BackSong")
	
	mainAudioPlayer.stream = main_stream
	mainAudioPlayer.set_bus("MainSong")


func split_freq_range(low, high, split):
	"""
	Given a low and a high value, split it evenly
	a number of times.
	
	:param low: The low value (in hz)
	:param high: The high value (in hz)
	:param split: The number of times to split
	"""
	var freq_range = FrequencyRange.LOW
	var range_cutoff = int(floor(split / 3))
	var result = []
	var prev_hz = low
	var j = range_cutoff
	for i in range(split):
		var low_hz = prev_hz
		var high_hz = low + (i * (high / split))

		if i >= j:
			j += range_cutoff
			freq_range += 1

		result.append({
			"freq_range": freq_range,
			"low": low_hz,
			"high": high_hz,
		})

		prev_hz = high_hz

	return result
