extends Node


func _on_Area2D_body_entered(body):
	if body is Player:
		get_tree().change_scene("res://MainGame/Home/Home.tscn")
