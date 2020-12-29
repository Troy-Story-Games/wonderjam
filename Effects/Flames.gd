extends Sprite

var time = 0
var noise_texture = null

onready var light2D = $Light2D


func _ready():
	# This way the noise texture isn't the same for all flames
	noise_texture = Utils.new_noise_texture() as NoiseTexture
	noise_texture.seamless = true
	get_material().set_shader_param("noise", noise_texture)


func _process(delta):
	"""
	Handles the flickering of the fire
	"""
	if light2D.visible:
		time += delta * 75
		var offset = noise_texture.noise.get_noise_1d(time)
		light2D.scale = Vector2(1.5 + offset / 3, 1.5 + offset / 3)
