extends Node2D


@onready var path = preload("res://stages/Stage_1.tscn")

func _on_timer_timeout():
	var tempPath = path.instantiate()
	add_child(tempPath)
