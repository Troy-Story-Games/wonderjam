extends Node

signal preload_done()

# Number of equal frequency ranges to split the frequency range into
const FREQ_SPLIT_COUNT = 24
# Number of seconds to preload the song before it can be played
const PRELOAD_TIME = 10.0
# The window to analyze in. Can be anything up to a max of PRELOAD_TIME
const ANALYSIS_WINDOW = 9.0
# If a beat occurs, the next beat cannot come sooner than this
# value later (in seconds)
const MIN_TIME_BETWEEN_BEATS = 0.15
# When calling "get_beats_now" or any other helper to retrieve beats,
# drop beats that we missed by more than this threshold
const DROP_BEAT_THRESHOLD = 0.05
# Used in our background analysis. An event that scores above this
# threshold will be considered a beat. This value is based on trial
# and error. (0.5 works well too but produces more beats)
const BEAT_SCORE_THRESHOLD = 0.6

# Beat tracking
var beats = []
var beats_now = []
var beats_now_by_range = {"low": [], "mid": [], "high": []}

# Energy tracking
var energy_window = []

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
var is_preload_done = false

onready var preloadTimer = $PreloadTimer


func _init():
	freq_ranges.append_array(AudioPlayers.split_freq_range(AudioPlayers.FREQ_MIN, AudioPlayers.FREQ_MAX, FREQ_SPLIT_COUNT))
	for rng in freq_ranges:
		# Add our custom values to the dict
		rng.left = 0.0
		rng.middle = 0.0
		rng.prev_beat_pos = 0.0
	
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


func _physics_process(delta):
	if AudioPlayers.mainAudioPlayer.playing:
		# This must always be called - so we call it here just in case nobody
		# else does on this frame. This populates the beats_now instance
		# variable with beats valid for this frame.
		get_beats_now()
		
		# We schedule the "clear_beats_now" function to be called
		# at the end of the frame since they won't be valid for
		# the timing of the next frame
		call_deferred("clear_beats_now")


func _process_thread(userdata):
	"""
	Perform the analysis of the background song in a thread
	so we're not tied to 60FPS for beat detection
	"""
	var prev_pos = 0.0

	while AudioPlayers.backAudioPlayer.playing:
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


func get_back_playback_position():
	return AudioPlayers.get_background_playback_position()


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
	preloaded_for = get_back_playback_position()

	print("DEBUG: preloaded_for ", preloaded_for)
	AudioPlayers.mainAudioPlayer.play()


func get_beats_now():
	"""
	Get the identified beats across the spectrum for right now in the
	main song.
	
	This will return beats that should be
	displayed on this frame to sync visually.
	"""
	if len(beats_now) > 0:
		return beats_now

	var compensated_playback_time = AudioPlayers.get_adjusted_playback_time()

	analysis_mutex.lock()

	while len(beats) > 0 and compensated_playback_time >= beats[0].pos:
		var miss = compensated_playback_time - beats[0].pos
		if miss > DROP_BEAT_THRESHOLD:
			print("DEBUG: SLOW: Missed by: ", miss, " dropping the beat!")
			beats.pop_front()
			continue  # Skip it - would be out of sync if we showed it

		var beat = beats.pop_front()

		if beat.freq_range == AudioPlayers.FrequencyRange.LOW:
			beats_now_by_range.low.append(beat)
		elif beat.freq_range == AudioPlayers.FrequencyRange.MID:
			beats_now_by_range.mid.append(beat)
		elif beat.freq_range == AudioPlayers.FrequencyRange.HIGH:
			beats_now_by_range.high.append(beat)

		beats_now.append(beat)

	analysis_mutex.unlock()

	return beats_now


func get_low_beats_now():
	"""
	Same as get_beats_now but only return the list of beats in the
	low frequency ranges
	"""
	get_beats_now()
	return beats_now_by_range.low


func get_mid_beats_now():
	"""
	Same as get_beats_now but only return the list of beats in the
	middle frequency ranges
	"""
	get_beats_now()
	return beats_now_by_range.mid


func get_high_beats_now():
	"""
	Same as get_beats_now but only return the list of beats in the
	high frequency ranges
	"""
	get_beats_now()
	return beats_now_by_range.high


func clear_beats_now():
	beats_now.clear()
	beats_now_by_range.low.clear()
	beats_now_by_range.mid.clear()
	beats_now_by_range.high.clear()


func analyze_background_song(prev_pos):
	"""
	Runs in a thread to analyze the muted song for
	beats ahead of time
	"""
	var pos = get_back_playback_position()
	var song_energy = 0.0

	if pos <= prev_pos:
		# Don't anlayze the same point in time more than once
		return pos

	for i in range(FREQ_SPLIT_COUNT):
		var rng = freq_ranges[i]

		var time_since_last_beat = pos - rng.prev_beat_pos
		if rng.prev_beat_pos > 0.0 and time_since_last_beat <= MIN_TIME_BETWEEN_BEATS:
			continue  # Skip...too soon

		var energy = AudioPlayers.get_energy_for_frequency_range(back_spectrum, rng.low, rng.high)
		song_energy += energy

		var left = rng.left
		var middle = rng.middle
		var right = energy
		var score = 0

		if 1.5 * left < middle:
			score += 2 * middle
		if 1.5 * right < middle:
			score += 2 * middle
		score += middle

		if score > BEAT_SCORE_THRESHOLD:
			#print("DEBUG: Beat @", prev_pos)
			rng.prev_beat_pos = prev_pos

			analysis_mutex.lock()
			beats.append({
				"freq_range": rng.freq_range,
				"pos": prev_pos,
				"low": rng.low,
				"high": rng.high,
				"energy": energy,
				"idx": i
			})
			analysis_mutex.unlock()

		rng.left = middle
		rng.middle = energy

	song_energy = song_energy / FREQ_SPLIT_COUNT
	if  len(energy_window) == 0 or energy_window[-1].value != song_energy:
		energy_window.append({
			"pos": pos,
			"value": song_energy
		})

		if pos > ANALYSIS_WINDOW:
			analyze_energy()
			energy_window.pop_front()  # Remove the first item

	if pos > ANALYSIS_WINDOW:
		# Once we have enough in the buffer we can analyze
		# We keep analyzing as the song plays and update
		# the beats as we go (it's a sliding window)
		analyze_collected_beats(pos - ANALYSIS_WINDOW, pos)


	return pos


func analyze_energy():
	"""
	This processes all the energy samples in the "energies"
	from the begin to end (inclusive)
	"""
	var raw_energies = []
	var total_energy = 0.0
	var mean_energy = 0.0
	var stdev_energy = 0.0
	var max_energy = 0.0
	var energy_samples = len(energy_window)
	var energy_lull_threshold = 0.0
	var energy_extreme_threshold = 0.0

	for energy in energy_window:
		total_energy += energy.value
		if energy.value > max_energy:
			max_energy = energy.value
		raw_energies.append(energy.value)

	mean_energy = total_energy / energy_samples
	stdev_energy = Utils.stdev(raw_energies, mean_energy)
	var double_stdev = stdev_energy * 2
	energy_lull_threshold = clamp(mean_energy - double_stdev, 0.0, max_energy)
	energy_extreme_threshold = clamp(mean_energy + double_stdev, 0.0, max_energy)

	for energy in energy_window:
		if energy.value >= energy_extreme_threshold:
			#print("EXTREME! ", energy.pos)
			pass
		if energy.value <= energy_lull_threshold:
			#print("Lull ", energy.pos)
			pass

func analyze_collected_beats(begin, end):
	"""
	This processes all beats in the "beats" array from
	the begin to end (inclusive)
	"""
	# Collect all the low, mid, and high energy beats and calculate
	# the total, mean, max, and stadard deviation for the energies
	# then use a threshold of (max - stdev) to filter out weaker beats
	# We'll then use the beats we've determined are most "powerful",
	# compared to all other beats in this window, to try to estimate
	# the BPM
	var low_energies = []
	var total_low_energies = 0.0
	var low_mean = 0.0
	var low_max = 0.0
	var low_stdev = 0.0
	var low_threshold = 0.0
	
	var mid_energies = []
	var total_mid_energies = 0.0
	var mid_mean = 0.0
	var mid_max = 0.0
	var mid_stdev = 0.0
	var mid_threshold = 0.0
	
	var high_energies = []
	var total_high_energies = 0.0
	var high_mean = 0.0
	var high_max = 0.0
	var high_stdev = 0.0
	var high_threshold = 0.0

	analysis_mutex.lock()
	for beat in beats:
		if beat.pos < begin:
			continue
		if beat.pos > end:
			break  # They're in time order so we won't have any more to process
		
		# Consider each range separately
		match beat.freq_range:
			AudioPlayers.FrequencyRange.LOW:
				low_energies.append(beat.energy)
				total_low_energies += beat.energy
				if beat.energy > low_max:
					low_max = beat.energy
			AudioPlayers.FrequencyRange.MID:
				mid_energies.append(beat.energy)
				total_mid_energies += beat.energy
				if beat.energy > mid_max:
					mid_max = beat.energy
			AudioPlayers.FrequencyRange.HIGH:
				high_energies.append(beat.energy)
				total_high_energies += beat.energy
				if beat.energy > high_max:
					high_max = beat.energy

	if len(low_energies) > 1:
		low_mean = total_low_energies / len(low_energies)
		low_stdev = Utils.stdev(low_energies, low_mean)
		low_threshold = low_max - low_stdev
	if len(mid_energies) > 1:
		mid_mean = total_mid_energies / len(mid_energies)
		mid_stdev = Utils.stdev(mid_energies, mid_mean)
		mid_threshold = mid_max - mid_stdev
	if len(high_energies) > 1:
		high_mean = total_high_energies / len(high_energies)
		high_stdev = Utils.stdev(high_energies, high_mean)
		high_threshold = high_max - high_stdev

	for beat in beats:
		if beat.pos < begin:
			continue
		if beat.pos > end:
			break  # They're in time order so we won't have any more to process

		# Consider each range separately
		match beat.freq_range:
			AudioPlayers.FrequencyRange.LOW:
				if beat.energy >= low_threshold:
					pass
			AudioPlayers.FrequencyRange.MID:
				if beat.energy >= mid_threshold:
					pass
			AudioPlayers.FrequencyRange.HIGH:
				if beat.energy >= high_threshold:
					pass

	analysis_mutex.unlock()


func _on_PreloadTimer_timeout():
	is_preload_done = true
	emit_signal("preload_done")
