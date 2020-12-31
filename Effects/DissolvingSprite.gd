extends Sprite

const BurnGradient = preload("res://Effects/BurnGradient.tres")
const MeltGradient = preload("res://Effects/MeltGradient.tres")
const SnowAccumulateGradient = preload("res://Effects/SnowAccumulateGradient.tres")

export(int) var OCTAVES = 3
export(int) var PERIOD = 64
export(float) var PERSISTENCE = 0.5
export(float) var LACUNARITY = 2

enum DissolveEffect {
	BURN,
	MELT,
	ACCUMULATE
}

export(DissolveEffect) var DISSOLVE_EFFECT = DissolveEffect.BURN
export(float) var burn_pos = 0 setget set_burn_pos


func _ready():
	if texture == null:
		return

	var width = texture.get_width()
	var height = texture.get_height()
	var noise_texture = Utils.new_noise_texture(width, height, OCTAVES, PERIOD, PERSISTENCE, LACUNARITY)
	var mat = get_material()
	
	mat.set_shader_param("noise_tex", noise_texture)

	match DISSOLVE_EFFECT:
		DissolveEffect.BURN:
			mat.set_shader_param("burn_ramp", BurnGradient)
		DissolveEffect.MELT:
			mat.set_shader_param("burn_ramp", MeltGradient)
		DissolveEffect.ACCUMULATE:
			mat.set_shader_param("burn_ramp", SnowAccumulateGradient)


func set_burn_pos(value):
	if texture == null:
		return

	burn_pos = clamp(value, 0, 1)
	get_material().set_shader_param("burn_position", burn_pos)
