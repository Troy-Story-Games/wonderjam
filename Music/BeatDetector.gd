extends Node

signal preload_done()

export(int) var FREQ_SPLIT_COUNT = 20
export(int) var FREQ_MAX = 20000
export(int) var FREQ_MIN = 20
export(float) var PRELOAD_TIME = 10.0
export(float) var MIN_TIME_BETWEEN_BEATS = 0.15

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

onready var preloadTimer = $PreloadTimer


func _init():
	freq_ranges.append_array(split_freq_range(FREQ_MIN, FREQ_MAX, FREQ_SPLIT_COUNT))
	analysis_mutex = Mutex.new()
	analysis_thread = Thread.new()


func _ready():
	# Get the min and max DBs
	min_db = AudioPlayers.get_min_db()
	max_db = AudioPlayers.get_max_db()

	# Get the index for our back song
	var back_bus_idx = AudioServer.get_bus_index("BackSong")

	# Get the spectrum analysis instance from the back bus
	back_spectrum = AudioServer.get_bus_effect_instance(back_bus_idx, 0)


func _process(delta):
	if AudioPlayers.mainAudioPlayer.playing:
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
	var prev_pos = 0.0
	
	while true:
		analysis_mutex.lock()
		var should_exit = exit_thread
		analysis_mutex.unlock()

		if should_exit:
			break

		prev_pos = analyze_background_song(prev_pos)


func _exit_tree():
	# Gotta cleanup the thread
	analysis_mutex.lock()
	exit_thread = true
	analysis_mutex.unlock()
	analysis_thread.wait_to_finish()


func preload_song(path):
	# Load the song
	AudioPlayers.load_song(path)

	# Start preloading the song immediately
	AudioPlayers.backAudioPlayer.play()
	preloadTimer.start(PRELOAD_TIME)
	analysis_thread.start(self, "_process_thread")


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
	preloaded_for = AudioPlayers.backAudioPlayer.get_playback_position()

	print("DEBUG: preloaded_for ", preloaded_for)
	AudioPlayers.mainAudioPlayer.play()


func get_beats_now():
	"""
	Get the identified beats across the spectrum for right now in the
	main song.
	
	This will return beats that should be
	displayed on this frame to sync visually.
	"""
	var compensated_playback_time = AudioPlayers.get_adjusted_playback_time()
	var result = []

	analysis_mutex.lock()
	if len(beats) == 0:  # No beats
		analysis_mutex.unlock()
		return result

	while len(beats) > 0 and compensated_playback_time >= beats[0].pos:
		result.append(beats.pop_front())
	analysis_mutex.unlock()

	return result


func analyze_background_song(prev_pos):
	"""
	Runs in a thread to analyze the muted song for
	beats ahead of time
	"""
	var pos = AudioPlayers.backAudioPlayer.get_playback_position()

	if pos == prev_pos:
		# Don't anlayze the same point in time more than once
		return pos

	for i in range(FREQ_SPLIT_COUNT):
		var rng = freq_ranges[i]
		var mag = back_spectrum.get_magnitude_for_frequency_range(rng.low, rng.high)

		var time_since_last_beat = pos - rng.prev_beat_pos
		if rng.prev_beat_pos > 0.0 and time_since_last_beat <= MIN_TIME_BETWEEN_BEATS:
			continue  # Skip...too soon

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
			print("DEBUG: Beat @", pos)
			rng.prev_beat_pos = pos

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
		rng.prev_score = score

	return pos


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
			"prev_beat_pos": 0.0
		})

		prev_hz = high_hz

	return result


func _on_PreloadTimer_timeout():
	emit_signal("preload_done")
