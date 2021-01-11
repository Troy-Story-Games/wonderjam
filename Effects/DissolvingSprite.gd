extends Sprite

const BurnGradient = preload("res://Effects/BurnGradient.tres")
const MeltGradient = preload("res://Effects/MeltGradient.tres")
const SnowAccumulateGradient = preload("res://Effects/SnowAccumulateGradient.tres")

enum DissolveEffect {
	BURN,
	MELT,
	ACCUMULATE
}

export(DissolveEffect) var DISSOLVE_EFFECT = DissolveEffect.BURN
export(float) var burn_pos = 0 setget set_burn_pos

onready var mat = get_material() as ShaderMaterial


func _ready():
	if texture == null:
		return

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
	
	if mat != null:
		mat.set_shader_param("burn_position", burn_pos)
