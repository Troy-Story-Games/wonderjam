extends Node

signal preload_done()

# Number of equal frequency ranges to split the frequency range into
const FREQ_SPLIT_COUNT = 24
# Number of seconds to preload the song before it can be played
const PRELOAD_TIME = 10.0
# If a peak occurs, the next peak cannot come sooner than this
# value later (in seconds)
const MIN_TIME_BETWEEN_PEAKS = 0.05
# When calling "get_peaks_now" or any other helper to retrieve peaks,
# drop peaks that we missed by more than this threshold
const DROP_PEAK_THRESHOLD = 0.05
# Used in our background analysis. An event that scores above this
# threshold will be considered a peak. This value is based on trial
# and error. (0.5 works well too but produces more peaks)
const PEAK_SCORE_THRESHOLD = 0.6
# The max frequency for BPM detection (low pass filter defaults
# to 2000 hz so we'll use that)
const BPM_CUTOFF_FREQ = 2000

# Energy tracking
var energy_window = []

var preloaded_for = 0.0
var back_spectrum = null
var main_stream = null
var back_stream = null
var is_preload_done = false

onready var peakDetector = PeakDetector.new(FREQ_SPLIT_COUNT, DROP_PEAK_THRESHOLD, MIN_TIME_BETWEEN_PEAKS, PEAK_SCORE_THRESHOLD)
onready var bpmDetector = BPMDetector.new(BPM_CUTOFF_FREQ)
onready var preloadTimer = $PreloadTimer


func _physics_process(delta):
	if AudioPlayers.mainAudioPlayer.playing:
		# These must always be called - so we call them 
		# here in case nobody else does on this frame.
		peakDetector.get_peaks_now()
		bpmDetector.get_beats_now()

		# We schedule the "clear_peaks_now" and "clear_beats_now" functions
		# to be called at the end of the frame since they won't be valid for
		# the timing of the next frame
		peakDetector.call_deferred("clear_peaks_now")
		bpmDetector.call_deferred("clear_beats_now")


func _exit_tree():
	# Gotta cleanup the thread
	peakDetector.stop_thread()
	bpmDetector.stop_thread()


func preload_song(path):
	# Load the song
	AudioPlayers.load_song(path)

	# Start preloading the song immediately
	AudioPlayers.backAudioPlayer.play()
	preloadTimer.start(PRELOAD_TIME)
	peakDetector.start_thread()
	bpmDetector.start_thread()


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
	preloaded_for = AudioPlayers.get_background_playback_position()

	print("DEBUG: preloaded_for ", preloaded_for)
	AudioPlayers.mainAudioPlayer.play()


func _on_PreloadTimer_timeout():
	is_preload_done = true
	emit_signal("preload_done")
