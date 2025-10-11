extends Node

@onready var ui = $UI  # ton interface
var xp_gain = 50  # valeur fixe ou calculée

func _ready():
	ui.get_node("EndPanel/RetryButton").pressed.connect(_on_retry_button_pressed)
	ui.get_node("EndPanel/MenuButton").pressed.connect(_on_menu_button_pressed)

func _process(_delta):
	var player_tiles = get_tree().get_nodes_in_group("player")
	var enemy_tiles = get_tree().get_nodes_in_group("enemy")

	if player_tiles.size() == 0:
		end_game("enemy")
	elif enemy_tiles.size() == 0:
		end_game("player")

func end_game(winner: String):
	get_tree().paused = true

	var message = ""
	if winner == "player":
		message = "🎉 Victoire ! Vous gagnez %d XP" % xp_gain
	else:
		message = "💀 Défaite... Réessayez pour gagner de l'XP !"
	ui.visible = true
	ui.get_node("EndPanel/MessageLabel").text = message
	ui.get_node("EndPanel").visible = true
	


func _on_retry_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
