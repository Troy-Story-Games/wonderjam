extends Node

export(int) var AMOUNT_OF_SNOW = 900

onready var particles2D = $Particles2D


func _ready():
	particles2D.amount = AMOUNT_OF_SNOW
