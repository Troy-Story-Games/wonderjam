extends Node2D

export(int) var WIDTH = 1280
export(int) var HEIGHT = 400
export(int) var NUM_BARS = 20
export(int) var FREQ_MAX = 20000
export(int) var FREQ_MIN = 20
export(int) var MAX_DB = 0
export(int) var MIN_DB = -40
export(int) var ACCEL = 20

var histogram = []
var min_db = 0
var max_db = 0
var spectrum = null


func _ready():
	min_db = AudioPlayers.get_min_db()
	max_db = AudioPlayers.get_max_db()
	
	for i in range(NUM_BARS):
		histogram.append(0.0)

	# Get the index for the main song
	var main_bus_idx = AudioServer.get_bus_index("MainSong")
	
	# Get the spectrum analysis instance from the main bus
	spectrum = AudioServer.get_bus_effect_instance(main_bus_idx, 0)


func _draw():
	var draw_pos = Vector2(global_position.x, global_position.y)  # Make a copy so we don't alter our own position
	var w_interval = WIDTH / NUM_BARS

	draw_line(Vector2(0, -HEIGHT), Vector2(WIDTH, -HEIGHT), Color.crimson, 2.0, true)
	
	for i in range(NUM_BARS):
		draw_line(draw_pos, draw_pos + Vector2(0, -histogram[i] * HEIGHT), Color.crimson, 4.0, true)
		draw_pos.x += w_interval


func _process(delta):
	populate_histogram(delta)
	update()


func populate_histogram(delta):
	"""
	Just do what we need to visualize the histogram
	"""
	var freq = FREQ_MIN
	var interval = (FREQ_MAX - FREQ_MIN) / NUM_BARS
	
	for i in range(NUM_BARS):
		var freqrange_low = float(freq - FREQ_MIN) / float(FREQ_MAX - FREQ_MIN)
		freqrange_low = freqrange_low * freqrange_low * freqrange_low * freqrange_low
		freqrange_low = lerp(FREQ_MIN, FREQ_MAX, freqrange_low)
		
		freq += interval
		
		var freqrange_high = float(freq - FREQ_MIN) / float(FREQ_MAX - FREQ_MIN)
		freqrange_high = freqrange_high * freqrange_high * freqrange_high * freqrange_high
		freqrange_high = lerp(FREQ_MIN, FREQ_MAX, freqrange_high)
		
		var energy = AudioPlayers.get_energy_for_frequency_range(spectrum, freqrange_low, freqrange_high)
		histogram[i] = lerp(histogram[i], energy, ACCEL * delta)
