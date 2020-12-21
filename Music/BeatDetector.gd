extends Node

signal preload_done()

export(int) var FREQ_SPLIT_COUNT = 20
export(int) var FREQ_MAX = 20000
export(int) var FREQ_MIN = 20
export(int) var MAX_DB = 0
export(int) var MIN_DB = -40
export(float) var BEAT_WINDOW_PERIOD = 0.4
export(float) var PRELOAD_TIME = 10.0

var MainInstances = Utils.get_main_instances()

var freq_ranges = []
var beats = []
var min_db = 0
var max_db = 0
var window_samples = 0
var window_start_time = 0.0
var window_time = 0.0
var preloaded_for = 0.0
var reset = false
var back_spectrum = null
var main_stream = null
var back_stream = null

onready var mainPlayer = $MainPlayer
onready var backPlayer = $BackPlayer
onready var preloadTimer = $PreloadTimer


func _init():
	freq_ranges.append_array(split_freq_range(FREQ_MIN, FREQ_MAX, FREQ_SPLIT_COUNT))
	MainInstances.beatDetector = self


func _ready():
	# Get the min and max DBs
	min_db = MIN_DB + mainPlayer.volume_db
	max_db = MAX_DB + mainPlayer.volume_db
	
	# Get the index for our back song
	var back_bus_idx = AudioServer.get_bus_index("BackSong")

	# Mute the background song
	AudioServer.set_bus_mute(back_bus_idx, true)

	# Get the spectrum analysis instance from the back bus
	back_spectrum = AudioServer.get_bus_effect_instance(back_bus_idx, 0)

	# Read the song contents
	var file_bytes = load_song(MainInstances.songFilePath)
	load_streams(MainInstances.songFilePath, file_bytes)

	# Start preloading the song immediately
	backPlayer.play()
	preloadTimer.start(PRELOAD_TIME)


func get_preload_progress():
	"""
	This is called to get a progress percentage
	for preloading
	"""
	if preloadTimer.time_left < 0.5:
		return 100.0
	
	var time_passed = preloadTimer.wait_time - preloadTimer.time_left
	return (time_passed / PRELOAD_TIME) * 100.0


func start_main_song():
	"""
	This is called when the player is ready to play
	This will start playing the main song
	"""

	# This allows preload to be longer than PRELOAD_TIME
	# PRELOAD_TIME is intended to be a minimum. The game
	# is designed to allow the player to do things while
	# the song loads. If they want to play immediately
	# the minimum wait time will be PRELOAD_TIME otherwise
	# they could wait longer and we track that here.
	preloaded_for = backPlayer.get_playback_position()
	mainPlayer.play()


func _process(delta):
	analyze_background_song()


func load_streams(path, file_bytes):
	"""
	Load the streams (both foreground and background)
	
	:param path: The file path for the song so we can check file extension
	:param file_bytes: The content of the file as bytes
	"""
	# Create the appropriate stream
	if MainInstances.songFilePath.ends_with(".mp3"):
		print("Load MP3: ", path)
		main_stream = AudioStreamMP3.new()
		back_stream = AudioStreamMP3.new()
		main_stream.data = file_bytes
		back_stream.data = file_bytes
	elif MainInstances.songFilePath.ends_with(".ogg"):
		print("Load OGG: ", path)
		main_stream = AudioStreamOGGVorbis.new()
		back_stream = AudioStreamOGGVorbis.new()
		main_stream.data = file_bytes
		back_stream.data = file_bytes
	else:
		print("Load WAV: ", path)
		main_stream = AudioStreamSample.new()
		back_stream = AudioStreamSample.new()
		main_stream.data = file_bytes
		back_stream.data = file_bytes

	backPlayer.stream = back_stream
	backPlayer.set_bus("BackSong")
	
	mainPlayer.stream = main_stream
	mainPlayer.set_bus("MainSong")


func load_song(path):
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_buffer(file.get_len())
	file.close()
	return content


func analyze_audio(player, spectrum):
	"""
	Analyze the currently playing audio given
	the player and the spectrum analyzer
	
	:param player: The player to analyze (main or back)
	:param spectrum: The spectrum instance for the associated player
	"""
	var pos = player.get_playback_position()

	for i in range(len(freq_ranges)):
		var rng = freq_ranges[i]
		var mag = spectrum.get_magnitude_for_frequency_range(rng.low, rng.high)
		
		mag = linear2db(mag.length())
		mag = (mag - min_db) / (max_db - min_db)
		
		mag += 0.3 * (rng.low - FREQ_MIN) / (FREQ_MAX - FREQ_MIN)
		mag = clamp(mag, 0.05, 1)
		
		#var energy = clamp((min_db + linear2db(mag)) / min_db, 0, 1)
		var energy = mag
		var diff = energy - rng.prev

		if diff > 0 and not rng.attack:
			# Starting an attack
			rng.attack = true
			rng.attack_val = rng.prev
			rng.attack_pos = rng.prev_pos
		elif rng.attack and diff < 0:
			# We hit the peak and are heading down
			rng.attack = false
			diff = rng.prev - rng.attack_val

			if reset:
				rng.total_diff = diff
			elif diff > 0:
				rng.total_diff += diff
				rng.mean_diff = rng.total_diff / window_samples

			if diff > rng.mean_diff :
				beats.append({
					"pos": rng.attack_pos,
					"low": rng.low,
					"high": rng.high,
					"idx": i,
					"duration": rng.prev_pos - rng.attack_pos
				})

			rng.attack_pos = 0.0
			rng.attack_val = 0.0

		rng.prev = energy
		rng.prev_pos = pos


func analyze_background_song():
	"""
	Called by _process while the song
	is pre-playing (to identify beats ahead of time)
	"""
	var pos = backPlayer.get_playback_position()
	
	if window_time > BEAT_WINDOW_PERIOD:
		window_samples = 0
		window_start_time = pos
		window_time = 0.0
		reset = true
	else:
		reset = false
		window_time = pos - window_start_time

	window_samples += 1

	analyze_audio(backPlayer, back_spectrum)


func split_freq_range(low, high, split):
	"""
	Given a low and a high value, split it evenly
	a number of times.
	
	:param low: The low value (in hz)
	:param high: The high value (in hz)
	:param split: The number of times to split
	"""
	var result = []
	var prev_hz = low
	for i in range(split):
		var low_hz = prev_hz
		var high_hz = low + (i * (high / split))

		result.append({
			"low": low_hz,
			"high": high_hz,
			"prev": 0.0,
			"total_diff": 0.0,
			"mean_diff": 0.0,
			"prev_pos": 0.0,
			"attack_pos": 0.0,
			"attack": false,
			"attack_val": 0.0
		})

		prev_hz = high_hz

	return result


func _on_PreloadTimer_timeout():
	emit_signal("preload_done")
