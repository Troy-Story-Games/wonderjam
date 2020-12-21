extends Node2D

enum BurnableState {
	UNMODIFIED,
	MELTED,
	BURNED
}

export(BurnableState) var state = BurnableState.UNMODIFIED

onready var leaves = $Leaves
onready var snow = $Snow
onready var animationPlayer = $AnimationPlayer


func _ready():
	match state:
		BurnableState.UNMODIFIED:
			pass # Default is unburned and unmelted
		BurnableState.MELTED:
			snow.burn_pos = 1
		BurnableState.BURNED:
			snow.burn_pos = 1
			leaves.burn_pos = 1


func melt():
	if state == BurnableState.UNMODIFIED:
		animationPlayer.play("Melt")


func burn():
	if state == BurnableState.MELTED:
		animationPlayer.play("Burn")


func unmelt():
	if state == BurnableState.MELTED:
		animationPlayer.play("Unmelt")


func unburn():
	if state == BurnableState.BURNED:
		animationPlayer.play("Unburn")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Melt":
		state = BurnableState.MELTED
	if anim_name == "Burn":
		state = BurnableState.BURNED
	if anim_name == "Unburn":
		state = BurnableState.MELTED
	if anim_name == "Unmelt":
		state = BurnableState.UNMODIFIED
