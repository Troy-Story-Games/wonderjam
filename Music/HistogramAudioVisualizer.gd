tool
extends Node2D

export(Vector2) var EXTENTS = Vector2(200, 100)
export(Color) var BAR_COLOR = Color.crimson
export(float) var BAR_WIDTH = 4.0

export(int) var ACCELERATION = 20
export(int) var NUM_BARS = 24 setget set_num_bars

var histogram = []
var freq_ranges = []
var min_db = 0
var max_db = 0
var spectrum = null


func _init():
	set_num_bars(self.NUM_BARS)


func _ready():
	min_db = AudioPlayers.get_min_db()
	max_db = AudioPlayers.get_max_db()

	# Get the index for the main song
	var main_bus_idx = AudioServer.get_bus_index("MainSong")
	
	# Get the spectrum analysis instance from the main bus
	spectrum = AudioServer.get_bus_effect_instance(main_bus_idx, 0)


func _draw():
	if Engine.editor_hint:
		tool_draw()

	var w_interval = EXTENTS.x / self.NUM_BARS
	var draw_pos = Vector2(w_interval / 2.0, EXTENTS.y)

	draw_line(Vector2(0, EXTENTS.y), Vector2(EXTENTS.x, EXTENTS.y), BAR_COLOR, 2.0, true)
	
	for i in range(self.NUM_BARS):
		draw_line(draw_pos, draw_pos + Vector2(0, -histogram[i] * EXTENTS.y), BAR_COLOR, BAR_WIDTH, true)
		draw_pos.x += w_interval


func _process(delta):
	if not Engine.editor_hint:
		# Code to execute in game.
		populate_histogram(delta)
	else:
		for i in range(self.NUM_BARS):
			histogram[i] = lerp(histogram[i], rand_range(0.05, 1.0), ACCELERATION * delta)

	update()


func set_num_bars(value):
	NUM_BARS = value
	histogram.clear()
	for _idx in range(NUM_BARS):
		histogram.append(0.0)

	freq_ranges.clear()
	freq_ranges.append_array(AudioPlayers.split_freq_range(AudioPlayers.FREQ_MIN, AudioPlayers.FREQ_MAX, NUM_BARS))


func populate_histogram(delta):
	for i in range(self.NUM_BARS):
		var rng = freq_ranges[i]
		var energy = AudioPlayers.get_energy_for_frequency_range(spectrum, rng.low, rng.high)
		histogram[i] = lerp(histogram[i], energy, ACCELERATION * delta)


func tool_draw():
	"""
	Draw function for in-editor
	"""
	var rect = Rect2(Vector2.ZERO, EXTENTS)
	draw_rect(rect, Color.blue, false, 1.0, true)
