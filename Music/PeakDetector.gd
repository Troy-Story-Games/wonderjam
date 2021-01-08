extends Resource
class_name PeakDetector

# Peak tracking
var peaks = []
var peaks_now = []
var peaks_now_by_range = {"low": [], "mid": [], "high": []}

var freq_ranges = []
var freq_split_count = 0
var drop_peak_threshold = 0.0
var min_time_bw_peaks = 0.0
var peak_score_threshold = 0.0
var back_spectrum = null
var analysis_thread = null
var analysis_mutex = null
var exit_thread = false


func _init(_freq_split_count=24, _drop_peak_threshold=0.05, _min_time_bw_peaks=0.15, _peak_score_threshold=0.5):
	self.freq_split_count = _freq_split_count
	self.drop_peak_threshold = _drop_peak_threshold
	self.min_time_bw_peaks = _min_time_bw_peaks
	self.peak_score_threshold = _peak_score_threshold

	self.freq_ranges.append_array(AudioPlayers.split_freq_range(AudioPlayers.FREQ_MIN, AudioPlayers.FREQ_MAX, self.freq_split_count))
	for rng in freq_ranges:
		# Add our custom values to the dict
		rng.left = 0.0
		rng.middle = 0.0
		rng.prev_peak_pos = 0.0
	
	self.analysis_mutex = Mutex.new()
	self.analysis_thread = Thread.new()

	# Get the index for our back song
	var back_bus_idx = AudioServer.get_bus_index("BackSong")

	# Get the spectrum analysis instance from the back bus
	self.back_spectrum = AudioServer.get_bus_effect_instance(back_bus_idx, 0)


func _process_thread(userdata):
	"""
	Perform the analysis of the background song in a thread
	so we're not tied to 60FPS for peak detection
	"""
	var prev_pos = 0.0

	while AudioPlayers.backAudioPlayer.playing:
		analysis_mutex.lock()
		var should_exit = exit_thread
		analysis_mutex.unlock()

		if should_exit:
			break

		prev_pos = analyze_background_song(prev_pos)


func stop_thread():
	# Gotta cleanup the thread
	analysis_mutex.lock()
	exit_thread = true
	analysis_mutex.unlock()
	analysis_thread.wait_to_finish()


func start_thread():
	analysis_thread.start(self, "_process_thread")


func get_peaks_now():
	"""
	Get the identified peaks across the spectrum for right now in the
	main song.
	
	This will return peaks that should be
	displayed on this frame to sync visually.
	"""
	if len(peaks_now) > 0:
		return peaks_now

	var compensated_playback_time = AudioPlayers.get_adjusted_playback_time()

	analysis_mutex.lock()

	while len(peaks) > 0 and compensated_playback_time >= peaks[0].pos:
		var miss = compensated_playback_time - peaks[0].pos
		if miss > drop_peak_threshold:
			print("DEBUG: SLOW: Missed by: ", miss, " dropping the peak!")
			peaks.pop_front()
			continue  # Skip it - would be out of sync if we showed it

		var peak = peaks.pop_front()

		if peak.freq_range == AudioPlayers.FrequencyRange.LOW:
			peaks_now_by_range.low.append(peak)
		elif peak.freq_range == AudioPlayers.FrequencyRange.MID:
			peaks_now_by_range.mid.append(peak)
		elif peak.freq_range == AudioPlayers.FrequencyRange.HIGH:
			peaks_now_by_range.high.append(peak)

		peaks_now.append(peak)

	analysis_mutex.unlock()

	return peaks_now


func get_low_peaks_now():
	"""
	Same as get_peaks_now but only return the list of peaks in the
	low frequency ranges
	"""
	get_peaks_now()
	return peaks_now_by_range.low


func get_mid_peaks_now():
	"""
	Same as get_peaks_now but only return the list of peaks in the
	middle frequency ranges
	"""
	get_peaks_now()
	return peaks_now_by_range.mid


func get_high_peaks_now():
	"""
	Same as get_peaks_now but only return the list of peaks in the
	high frequency ranges
	"""
	get_peaks_now()
	return peaks_now_by_range.high


func clear_peaks_now():
	peaks_now.clear()
	peaks_now_by_range.low.clear()
	peaks_now_by_range.mid.clear()
	peaks_now_by_range.high.clear()


func analyze_background_song(prev_pos):
	"""
	Runs in a thread to analyze the muted song for
	peaks ahead of time
	"""
	var pos = AudioPlayers.get_background_playback_position()

	if pos <= prev_pos:
		# Don't anlayze the same point in time more than once
		return pos

	for i in range(freq_split_count):
		var rng = freq_ranges[i]
		var energy = AudioPlayers.get_energy_for_frequency_range(back_spectrum, rng.low, rng.high)
		var left = rng.left
		var middle = rng.middle
		var right = energy
		var score = 0

		var time_since_last_peak = pos - rng.prev_peak_pos
		if rng.prev_peak_pos > 0.0 and time_since_last_peak <= min_time_bw_peaks:
			rng.left = middle
			rng.middle = energy
			continue  # Skip...too soon

		if 1.5 * left < middle:
			score += 2 * middle
		if 1.5 * right < middle:
			score += 2 * middle
		score += middle

		if score > peak_score_threshold:
			#print("DEBUG: Peak @", prev_pos)
			rng.prev_peak_pos = prev_pos

			analysis_mutex.lock()
			peaks.append({
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

	return pos
