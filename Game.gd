extends Node2D

const FREQ_RANGES = []
const FREQ_SPLIT_COUNT = 20
const FREQ_MAX = 20000
const FREQ_MIN = 20
const WIDTH = 400
const HEIGHT = 200
const COMPENSATE_FRAMES = 2
const COMPENSATE_HZ = 60.0
const WINDOW_PERIOD = 0.4
const PRELOAD_TIME = 10.0
const ACCEL = 20

var max_db = 0
var min_db = -40
var histogram = []

enum GameState {
	LOADING,
	PLAYING
}

const Splode = preload("res://Splode.tscn")

var MainInstances = Utils.get_main_instances()

var window_samples = 0
var window_start_time = 0.0
var window_time = 0.0
var reset = false
var beats = []
var state = GameState.LOADING setget set_state

var main_spectrum = null
var back_spectrum = null
var main_stream = null
var back_stream = null

onready var progressBar = $ProgressBar
onready var mainPlayer = $MainAudioPlayer
onready var backPlayer = $BackAudioPlayer


func _init():
	FREQ_RANGES.append_array(split_freq_range(FREQ_MIN, FREQ_MAX, FREQ_SPLIT_COUNT))
	
	for i in range(FREQ_SPLIT_COUNT):
		histogram.append(0)


func _ready():
	# Get the min and max DBs
	min_db += mainPlayer.volume_db
	max_db += mainPlayer.volume_db
	
	# Get the indexes for our 2 buses
	var main_bus_idx = AudioServer.get_bus_index("MainSong")
	var back_bus_idx = AudioServer.get_bus_index("BackSong")

	# Mute the background song
	AudioServer.set_bus_mute(back_bus_idx, true)

	# Get the spectrum analysis instance from both
	main_spectrum = AudioServer.get_bus_effect_instance(main_bus_idx, 0)
	back_spectrum = AudioServer.get_bus_effect_instance(back_bus_idx, 0)

	# Read the song contents
	var file_bytes = load_song(MainInstances.songFilePath)
	load_streams(MainInstances.songFilePath, file_bytes)

	# Start preloading the song
	backPlayer.play()


func _draw():
	var draw_pos = Vector2(500, 400)
	var w_interval = WIDTH / FREQ_SPLIT_COUNT

	draw_line(Vector2(0, -HEIGHT), Vector2(WIDTH, -HEIGHT), Color.crimson, 2.0, true)
	
	for i in range(FREQ_SPLIT_COUNT):
		draw_line(draw_pos, draw_pos + Vector2(0, -histogram[i] * HEIGHT), Color.crimson, 4.0, true)
		draw_pos.x += w_interval


func _process(delta):
	match self.state:
		GameState.LOADING:
			analyze_background_song()
		GameState.PLAYING:
			analyze_background_song()
			play_main()

	if mainPlayer.playing:
		populate_histogram(main_spectrum, delta)
		update()


func populate_histogram(spectrum, delta):
	"""
	Just do what we need to visualize the histogram
	"""
	var freq = FREQ_MIN
	var interval = (FREQ_MAX - FREQ_MIN) / FREQ_SPLIT_COUNT
	
	for i in range(FREQ_SPLIT_COUNT):
		var freqrange_low = float(freq - FREQ_MIN) / float(FREQ_MAX - FREQ_MIN)
		freqrange_low = freqrange_low * freqrange_low * freqrange_low * freqrange_low
		freqrange_low = lerp(FREQ_MIN, FREQ_MAX, freqrange_low)
		
		freq += interval
		
		var freqrange_high = float(freq - FREQ_MIN) / float(FREQ_MAX - FREQ_MIN)
		freqrange_high = freqrange_high * freqrange_high * freqrange_high * freqrange_high
		freqrange_high = lerp(FREQ_MIN, FREQ_MAX, freqrange_high)
		
		var mag = spectrum.get_magnitude_for_frequency_range(freqrange_low, freqrange_high)
		mag = linear2db(mag.length())
		mag = (mag - min_db) / (max_db - min_db)
		
		mag += 0.3 * (freq - FREQ_MIN) / (FREQ_MAX - FREQ_MIN)
		mag = clamp(mag, 0.05, 1)
		
		histogram[i] = lerp(histogram[i], mag, ACCEL * delta)


func analyze_audio(player, spectrum):
	"""
	Analyze the currently playing audio given
	the player and the spectrum analyzer
	
	:param player: The player to analyze (main or back)
	:param spectrum: The spectrum instance for the associated player
	"""
	var pos = player.get_playback_position()

	for i in range(len(FREQ_RANGES)):
		var rng = FREQ_RANGES[i]
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
				#rng.mean_diff = rng.total_diff / window_samples
			elif diff > 0:
				rng.total_diff += diff
				rng.mean_diff = rng.total_diff / window_samples

			if diff > rng.mean_diff :
				#print("mean_diff: ", rng.mean_diff)
				#print("Beat @", rng.attack_pos)
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
	
	if window_time > WINDOW_PERIOD:
		window_samples = 0
		window_start_time = pos
		window_time = 0.0
		reset = true
	else:
		reset = false
		window_time = pos - window_start_time

	window_samples += 1

	analyze_audio(backPlayer, back_spectrum)

	if pos >= PRELOAD_TIME and self.state == GameState.LOADING:
		self.state = GameState.PLAYING
		return

	progressBar.value = (pos / PRELOAD_TIME) * 100.0


func play_main():
	"""
	Logic used when the game starts
	after loading is complete
	"""
	# Get compensated playback time (for visuals)
	var compensated_playback_time = mainPlayer.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() + (1 / COMPENSATE_HZ) * COMPENSATE_FRAMES

	if len(beats) == 0:
		return

	while len(beats) > 0 and compensated_playback_time >= beats[0].pos:
		var miss = compensated_playback_time - beats[0].pos
		if miss > 0.09:
			print("Missed by: ", miss)

		var beat = beats.pop_front()
		var w = int(WIDTH / len(FREQ_RANGES))
		var splode = Utils.instance_scene_on_main(Splode, Vector2(w * beat.idx + w / 2, HEIGHT + 150))
		splode.emitting = true
		splode.lifetime = 0.15
		splode.get_child(0).wait_time = 0.16


func set_state(value):
	state = value
	match state:
		GameState.LOADING:
			progressBar.visible = true
		GameState.PLAYING:
			mainPlayer.play()
			progressBar.visible = false


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



