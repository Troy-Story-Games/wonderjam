extends Node

const HealthPickup = preload("res://Items/HealthPickup.tscn")
# Higher chance for health than anything else
const HEALTH_CHANCE = 0.65

var pickup_items = [
	preload("res://Items/BombPickup.tscn"),
	preload("res://Items/MultiplierPickup.tscn")
]


func instance_scene_on_main(packed_scene, position=Vector2.ZERO):
	"""
	Helper method that takes a packed scene, creates an instance
	of it, then adds it as a child to the current scene, sets the
	global position and returns the instance.
	
	:param packed_scene: A packed scene usually loaded with preload()
	:param position: Vector2 to set as the new instance's global_position
	:returns: The newly created instance
	"""
	var main = get_tree().current_scene
	var instance = packed_scene.instance()
	main.add_child(instance)
	instance.global_position = position
	return instance


func drop_random_item(position, chance=0.25):
	if rand_range(0.0, 1.0) <= chance:
		if rand_range(0.0, 1.0) <= HEALTH_CHANCE:
			Utils.instance_scene_on_main(HealthPickup, position)
		else:
			pickup_items.shuffle()
			Utils.instance_scene_on_main(pickup_items[0], position)

func get_player_stats():
	"""
	Get the shared instance of PlayerStats
	"""
	return ResourceLoader.load("res://Player/PlayerStats.tres")


func new_noise_texture(width=512, height=512, octaves=3, period=64, persistence=0.5, lacunarity=2.0):
	"""
	Grab a new texture generated from OpenSimplexNoise
	with the given parameters
	
	Ref: https://github.com/splite/Godot-3.1-Dissolve-shader-with-OpenSimplexNoise 
	"""
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistence
	noise.lacunarity = lacunarity
	
	var noise_tex = NoiseTexture.new()
	noise_tex.width = width
	noise_tex.height = height
	noise_tex.noise = noise
	
	return noise_tex


func stdev(items, mean):
	"""
	Calculate the standard deviation of a list of items given the items
	and the mean
	"""
	var sum_of_squares = 0.0
	for item in items:
		sum_of_squares += pow((item - mean), 2)

	var variance = sum_of_squares / (len(items) - 1.0)

	return sqrt(variance)


func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
