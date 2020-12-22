extends Node

signal preload_done()

export(int) var FREQ_SPLIT_COUNT = 20
export(int) var FREQ_MAX = 20000
export(int) var FREQ_MIN = 20
export(int) var MAX_DB = 0
export(int) var MIN_DB = -40
export(int) var COMPENSATE_FRAMES = 2
export(float) var COMPENSATE_HZ = 60.0
export(float) var PRELOAD_TIME = 10.0

var MainInstances = Utils.get_main_instances()

var beats = []
var freq_ranges = []
var min_db = 0
var max_db = 0
var preloaded_for = 0.0
var back_spectrum = null
var main_stream = null
var back_stream = null
var analysis_thread = null
var analysis_mutex = null
var exit_thread = false

onready var mainPlayer = $MainPlayer
onready var backPlayer = $BackPlayer
onready var preloadTimer = $PreloadTimer


func _init():
	freq_ranges.append_array(split_freq_range(FREQ_MIN, FREQ_MAX, FREQ_SPLIT_COUNT))
	MainInstances.beatDetector = self
	analysis_mutex = Mutex.new()
	analysis_thread = Thread.new()


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
	analysis_thread.start(self, "_process_thread")


func _process(delta):
	if mainPlayer.playing:
		# call 'get_beats_now' at the end of this frame
		# If somebody already called it, it will return
		# an empty list. If it wasn't called on this frame
		# it will discard all the beats that are no longer
		# possible to display
		call_deferred("get_beats_now")


func _process_thread(userdata):
	"""
	Perform the analysis of the background song in a thread
	so we're not tied to 60FPS for beat detection
	"""
	while true:
		analysis_mutex.lock()
		var should_exit = exit_thread
		analysis_mutex.unlock()

		if should_exit:
			break

		analyze_background_song()


func _exit_tree():
	# Gotta cleanup the thread
	analysis_mutex.lock()
	exit_thread = true
	analysis_mutex.unlock()
	analysis_thread.wait_to_finish()


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
	analysis_mutex.lock()
	preloaded_for = backPlayer.get_playback_position()
	analysis_mutex.unlock()

	print("DEBUG: preloaded_for ", preloaded_for)
	mainPlayer.play()


func get_beats_now():
	"""
	Get the identified beats across the spectrum for right now in the
	main song.
	
	This will return beats that should be
	displayed on this frame to sync visually.
	"""
	# Get the playback time that it really is for this frame (e.g slightly
	# in the future but that's fine b/c we preload the song and do preprocessing)
	var compensated_playback_time = mainPlayer.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() + (1 / COMPENSATE_HZ) * COMPENSATE_FRAMES
	var result = []

	analysis_mutex.lock()
	if len(beats) == 0:  # No beats
		analysis_mutex.unlock()
		return result

	while len(beats) > 0 and compensated_playback_time >= beats[0].pos:
		var miss = compensated_playback_time - beats[0].pos
		if miss > 0.05:
			print("SLOW: Missed by: ", miss)
		result.append(beats.pop_front())
	analysis_mutex.unlock()

	return result


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


func analyze_background_song():
	"""
	Called by _process while the song
	is pre-playing (to identify beats ahead of time)
	"""
	analysis_mutex.lock()
	var pos = backPlayer.get_playback_position()
	analysis_mutex.unlock()

	for i in range(FREQ_SPLIT_COUNT):
		analysis_mutex.lock()
		var rng = freq_ranges[i]
		var mag = back_spectrum.get_magnitude_for_frequency_range(rng.low, rng.high)
		analysis_mutex.unlock()

		mag = linear2db(mag.length())
		mag = (mag - min_db) / (max_db - min_db)
		mag += 0.3 * (rng.low - FREQ_MIN) / (FREQ_MAX - FREQ_MIN)
		var energy = clamp(mag, 0.05, 1)

		var left = rng.left
		var middle = rng.middle
		var right = energy
		var score = 0
		
		if 1.5 * left < middle:
			score += 2 * middle
		if 1.5 * right < middle:
			score += 2 * middle
		score += middle
		
		if score > 0.5:
			print("Beat @", pos)
			analysis_mutex.lock()
			beats.append({
				"pos": pos,
				"low": rng.low,
				"high": rng.high,
				"idx": i
			})
			analysis_mutex.unlock()
		
		rng.left = middle
		rng.middle = energy


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
			"left": 0.0,
			"middle": 0.0,
		})

		prev_hz = high_hz

	return result


func _on_PreloadTimer_timeout():
	emit_signal("preload_done")
