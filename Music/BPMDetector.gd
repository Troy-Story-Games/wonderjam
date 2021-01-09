extends Resource
class_name BPMDetector

const MIN_SAMPLE_COUNT = 20

# BPM
var beats = []
var beats_now = null

var energy_samples = []
var sample_window = 0.0
var sampling_interval = 0.0
var num_samples = 0
var total_energy = 0.0
var prev_sample_window_pos = 0.0
var prev_sample_pos = 0.0
var prev_sample_energy = 0.0
var drop_beat_threshold = 0.0
var beat_intervals_to_use = 0
var min_energy = 0.0
var min_interval = 0.0
var bpm_bottom_freq = 0
var bpm_cutoff_freq = 0
var back_spectrum = null
var analysis_thread = null
var analysis_mutex = null
var exit_thread = false


func _init(_bpm_cutoff_freq=2000, _sampling_interval=0.05, _sample_window=9.0, _min_energy=0.05, _min_interval=0.25, _drop_beat_threshold=0.05, _beat_intervals_to_use=4):
	self.bpm_cutoff_freq = _bpm_cutoff_freq
	self.sampling_interval = _sampling_interval
	self.sample_window = _sample_window
	self.min_energy = _min_energy
	self.min_interval = _min_interval
	self.drop_beat_threshold = _drop_beat_threshold
	self.beat_intervals_to_use = _beat_intervals_to_use
	self.bpm_bottom_freq = AudioPlayers.FREQ_MIN
	self.analysis_mutex = Mutex.new()
	self.analysis_thread = Thread.new()

	# Get the index for our back song
	var back_bus_idx = AudioServer.get_bus_index("BackSong")

	# Get the spectrum analysis instance from the back bus
	self.back_spectrum = AudioServer.get_bus_effect_instance(back_bus_idx, 0)


func _process_thread(userdata):
	"""
	Perform the analysis of the background song in a thread
	so we're not tied to 60FPS for BPM detection
	"""
	var prev_pos = 0.0

	while AudioPlayers.backAudioPlayer.playing:
		analysis_mutex.lock()
		var should_exit = exit_thread
		analysis_mutex.unlock()

		if should_exit:
			break

		prev_pos = analyze_background_song(prev_pos)


func get_beats_now():
	"""
	Get the identified beats for right now in the
	main song.
	
	This will return beats that should be
	displayed on this frame to sync visually.
	"""
	if beats_now != null:
		return beats_now

	var compensated_playback_time = AudioPlayers.get_adjusted_playback_time()

	analysis_mutex.lock()

	beats_now = []
	while len(beats) > 0 and compensated_playback_time >= beats[0]:
		var miss = compensated_playback_time - beats[0]
		if miss > drop_beat_threshold:
			print("DEBUG: SLOW: Missed by: ", miss, " dropping the beat!")
			beats.pop_front()
			continue  # Skip it - would be out of sync if we showed it

		beats_now.append(beats.pop_front())

	analysis_mutex.unlock()

	return beats_now


func clear_beats_now():
	if beats_now != null:
		beats_now.clear()
		beats_now = null


func stop_thread():
	# Gotta cleanup the thread
	analysis_mutex.lock()
	exit_thread = true
	analysis_mutex.unlock()
	analysis_thread.wait_to_finish()


func start_thread():
	analysis_thread.start(self, "_process_thread")


func sort_beat_intervals(a, b):
	if a[1] > b[1]:
		return true
	return false


func analyze_background_song(prev_pos):
	var pos = AudioPlayers.get_background_playback_position()

	if pos <= prev_pos:
		# Don't anlayze the same point in time more than once
		return pos

	var time_since_last_sample = pos - prev_sample_pos
	if time_since_last_sample <= sampling_interval:
		return pos  # Too soon

	# Get the average energy for 20 to 2000Hz
	var energy = AudioPlayers.get_energy_for_frequency_range(
		back_spectrum, bpm_bottom_freq, bpm_cutoff_freq,
		AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)

	if energy <= min_energy:
		prev_sample_energy = energy
		return pos  # Too weak

	var energy_diff = energy - prev_sample_energy
	if energy_diff <= 0.0:
		prev_sample_energy = energy
		return pos  # Needs to be increasing

	# Got a sample worth looking at
	energy_samples.append({
		"pos": pos,
		"energy": energy
	})
	num_samples += 1
	total_energy += energy
	prev_sample_energy = energy
	prev_sample_pos = pos

	# Once we've passed our window interval and we have a minumum of 20 samples
	# we can analyze...
	if (pos - prev_sample_window_pos) < sample_window or num_samples < MIN_SAMPLE_COUNT:
		return pos  # Either not enough samples or we haven't cleared the window

	# Shift the window up by half the window width
	prev_sample_window_pos = pos - (sample_window / 2)
	
	# Calculate the mean energy for the window
	var mean_window_energy = total_energy / num_samples

	var slice_end = 0
	var interval_idxs = {}
	var intervals = []
	var first_significant_sample_pos = 0.0

	for i in range(num_samples):
		var sample = energy_samples[i]
		
		if sample.pos <= prev_sample_window_pos:
			slice_end += 1  # Need to increment an index counter for the samples to lop off the front

		if sample.energy <= mean_window_energy:
			continue  # Only care if the energy exceeds the mean

		if first_significant_sample_pos == 0.0:
			# This is where our beats will start
			first_significant_sample_pos = sample.pos

		for j in range(1, 20):
			# Look at the 20 nearest neighbors
			var idx = i + j
			if idx >= num_samples:
				break

			var interval = energy_samples[idx].pos - sample.pos
			interval = Utils.round_to_dec(interval, 2)
			if interval <= min_interval:
				continue  # To quick - Default min of 0.25 (240 BPM)

			# Create a count of unique intervals
			if interval_idxs.has(interval):
				intervals[interval_idxs[interval]][1] += 1
			else:
				interval_idxs[interval] = len(intervals)
				intervals.append([interval, 1])

	# Go through the samples up to slice_end and remove them (they are
	# outside the analysis window now)
	for _idx in range(slice_end):
		var sample = energy_samples.pop_front()
		total_energy -= sample.energy  # Adjust the total energy
	num_samples = len(energy_samples)  # Adjust the number of samples

	if len(intervals) == 0:
		return pos  # No significant intervals to add to the beats

	# Sort so the most common intervals first
	intervals.sort_custom(self, "sort_beat_intervals")

	# Grab the top X intervals to use (if there are X)
	if len(intervals) > beat_intervals_to_use:
		intervals.resize(beat_intervals_to_use)

	var main_interval = intervals[0][0]
	var current_bpm = int(60.0 / main_interval)
	if current_bpm < 100:
		current_bpm *= 2
		main_interval /= 2
	elif current_bpm > 220:
		current_bpm /= 2
		main_interval *= 2

	#print("Probably: ", current_bpm, " BPM")
	#print("Interval: ", main_interval, "s")
	#for interval in intervals:
	#	var time_bw_beats = interval[0]
	#	var approx_bpm = int(60.0 / time_bw_beats)
	#	print(interval[0], ": ", interval[1], " ~ ", approx_bpm, " BPM")
	#print("==========")

	analysis_mutex.lock()

	# It's a sliding window, so now we have to find the starting
	# position in the beats array
	var found_idx = 0
	for i in range(len(beats)):
		var beat_pos = beats[i]
		if beat_pos >= first_significant_sample_pos:
			found_idx = i
			break

	# Shrink to remove beats that we're going to replace
	# with presumably more accurate beats
	beats.resize(found_idx)

	var current_pos = first_significant_sample_pos
	var next_pos = current_pos + main_interval
	while current_pos <= pos:
		beats.append(current_pos)
		
		for idx in range(1, len(intervals)):
			var sub_interval = intervals[idx][0]
			assert(sub_interval > 0.0)
			var alt_bpm = int(60.0 / sub_interval)
			if alt_bpm < 100:
				alt_bpm *= 2
				sub_interval /= 2
			elif alt_bpm > 220:
				alt_bpm /= 2
				sub_interval *= 2

			if current_pos + sub_interval < next_pos:
				beats.append(current_pos + sub_interval)

		current_pos += main_interval
		next_pos = current_pos + main_interval

	analysis_mutex.unlock()

	return pos
