extends Node

@onready var ui = $UI
@onready var player_profile = $PlayerProfileUI as PlayerProfileUI
var xp_gain = 50

func _ready():
	# Configurer l'UI pour qu'elle continue de fonctionner en pause
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connecter les boutons
	ui.get_node("EndPanel/RetryButton").pressed.connect(_on_retry_button_pressed)
	ui.get_node("EndPanel/MenuButton").pressed.connect(_on_menu_button_pressed)
	
	# S'assurer que l'UI de fin est cachée au départ
	ui.visible = false

func _process(_delta):
	# Vérifier la condition de victoire/défaite
	var player_tiles = get_tree().get_nodes_in_group("player")
	var enemy_tiles = get_tree().get_nodes_in_group("enemy")

	if player_tiles.size() == 0 and not ui.visible:
		end_game("enemy")
	elif enemy_tiles.size() == 0 and not ui.visible:
		end_game("player")

func end_game(winner: String):
	get_tree().paused = true

	var message = ""
	if winner == "player":
		# Ajouter l'XP au profil du joueur
		if player_profile:
			player_profile.add_xp(xp_gain)
		message = "🎉 Victoire ! Vous gagnez %d XP" % xp_gain
	else:
		message = "💀 Défaite... Réessayez pour gagner de l'XP !"
	
	# Afficher le panneau de fin
	ui.visible = true
	ui.get_node("EndPanel/MessageLabel").text = message
	ui.get_node("EndPanel").visible = true

func _on_retry_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
