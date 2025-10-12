extends CanvasLayer
class_name PlayerProfileUI

# Références aux nœuds UI
@onready var player_name_label = $Panel/HBoxContainer/InfoContainer/PlayerName
@onready var level_value_label = $Panel/HBoxContainer/InfoContainer/LevelContainer/LevelValue
@onready var xp_progress_bar = $Panel/HBoxContainer/InfoContainer/XPContainer/XPProgressBar
@onready var xp_text_label = $Panel/HBoxContainer/InfoContainer/XPContainer/XPProgressBar/XPText
@onready var avatar_texture = $Panel/HBoxContainer/AvatarContainer/AvatarPanel/AvatarRect/AvatarTexture
@onready var default_avatar_label = $Panel/HBoxContainer/AvatarContainer/AvatarPanel/AvatarRect/DefaultLabel

# Style pour la barre XP normale
var normal_xp_style: StyleBoxFlat
# Style pour la barre XP niveau max
var max_xp_style: StyleBoxFlat

# Données du joueur (à connecter avec un système de sauvegarde plus tard)
var player_data = {
	"name": "Capitaine",
	"level": 1,
	"current_xp": 0,
	"xp_to_next_level": 100,
	"avatar_path": ""
}


func _ready():
	# Créer les styles pour la barre XP
	create_xp_styles()
	
	# Charger les données du joueur (pour l'instant depuis PlayerData si disponible)
	load_player_data()
	
	# Mettre à jour l'affichage
	update_ui()


func create_xp_styles():
	# Style normal (vert)
	normal_xp_style = StyleBoxFlat.new()
	normal_xp_style.bg_color = Color(0.2, 0.8, 0.3, 1)
	normal_xp_style.border_width_left = 2
	normal_xp_style.border_width_top = 2
	normal_xp_style.border_width_right = 2
	normal_xp_style.border_width_bottom = 2
	normal_xp_style.border_color = Color(0.1, 0.6, 0.2, 1)
	normal_xp_style.corner_radius_top_left = 8
	normal_xp_style.corner_radius_top_right = 8
	normal_xp_style.corner_radius_bottom_right = 8
	normal_xp_style.corner_radius_bottom_left = 8
	
	# Style niveau max (or jaune)
	max_xp_style = StyleBoxFlat.new()
	max_xp_style.bg_color = Color(1, 0.84, 0, 1)
	max_xp_style.border_width_left = 2
	max_xp_style.border_width_top = 2
	max_xp_style.border_width_right = 2
	max_xp_style.border_width_bottom = 2
	max_xp_style.border_color = Color(0.8, 0.65, 0, 1)
	max_xp_style.corner_radius_top_left = 8
	max_xp_style.corner_radius_top_right = 8
	max_xp_style.corner_radius_bottom_right = 8
	max_xp_style.corner_radius_bottom_left = 8


func load_player_data():
	# Charger depuis un fichier de sauvegarde (à implémenter plus tard)
	# Pour l'instant, utiliser des valeurs par défaut
	if FileAccess.file_exists("user://player_profile.save"):
		var file = FileAccess.open("user://player_profile.save", FileAccess.READ)
		if file:
			var data = file.get_var()
			if data:
				player_data = data
			file.close()


func save_player_data():
	var file = FileAccess.open("user://player_profile.save", FileAccess.WRITE)
	if file:
		file.store_var(player_data)
		file.close()


func update_ui():
	# Mettre à jour le nom
	player_name_label.text = player_data.name
	
	# Mettre à jour le niveau
	level_value_label.text = str(player_data.level)
	
	# Vérifier si niveau max
	if player_data.level >= 99:
		# Niveau max
		xp_progress_bar.add_theme_stylebox_override("fill", max_xp_style)
		xp_progress_bar.value = xp_progress_bar.max_value
		xp_text_label.text = "MAX"
		xp_text_label.add_theme_font_size_override("font_size", 18)
		xp_text_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	else:
		# Niveau normal
		xp_progress_bar.add_theme_stylebox_override("fill", normal_xp_style)
		xp_progress_bar.max_value = player_data.xp_to_next_level
		xp_progress_bar.value = player_data.current_xp
		xp_text_label.text = "%d / %d" % [player_data.current_xp, player_data.xp_to_next_level]
		xp_text_label.add_theme_font_size_override("font_size", 14)
		xp_text_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	# Mettre à jour l'avatar
	update_avatar()


func update_avatar():
	if player_data.avatar_path != "" and FileAccess.file_exists(player_data.avatar_path):
		var image = Image.load_from_file(player_data.avatar_path)
		if image:
			var texture = ImageTexture.create_from_image(image)
			avatar_texture.texture = texture
			default_avatar_label.visible = false
		else:
			show_default_avatar()
	else:
		show_default_avatar()


func show_default_avatar():
	avatar_texture.texture = null
	default_avatar_label.visible = true


# Fonction pour ajouter de l'XP
func add_xp(amount: int):
	if player_data.level >= 99:
		return  # Niveau max atteint
	
	player_data.current_xp += amount
	
	# Vérifier si on passe au niveau suivant
	while player_data.current_xp >= player_data.xp_to_next_level and player_data.level < 99:
		level_up()
	
	update_ui()
	save_player_data()


func level_up():
	player_data.current_xp -= player_data.xp_to_next_level
	player_data.level += 1
	
	# Calculer l'XP nécessaire pour le prochain niveau (formule exponentielle)
	player_data.xp_to_next_level = int(100 * pow(1.15, player_data.level - 1))
	
	# Animation de level up (à implémenter)
	show_level_up_notification()


func show_level_up_notification():
	# Créer une notification visuelle de level up
	print("LEVEL UP! Nouveau niveau: ", player_data.level)
	# TODO: Ajouter une animation/particules/son


# Fonction pour changer le nom du joueur
func set_player_name(new_name: String):
	player_data.name = new_name
	update_ui()
	save_player_data()


# Fonction pour changer l'avatar
func set_avatar(image_path: String):
	player_data.avatar_path = image_path
	update_ui()
	save_player_data()


# Fonction pour charger une image depuis le système de fichiers
func load_avatar_from_file():
	# Cette fonction sera appelée par un bouton de sélection de fichier
	# Pour l'instant, juste un placeholder
	pass


# Fonction pour réinitialiser le profil (debug)
func reset_profile():
	player_data = {
		"name": "Capitaine",
		"level": 1,
		"current_xp": 0,
		"xp_to_next_level": 100,
		"avatar_path": ""
	}
	update_ui()
	save_player_data()


# Getters pour accéder aux données depuis d'autres scripts
func get_level() -> int:
	return player_data.level


func get_xp() -> int:
	return player_data.current_xp


func get_player_name() -> String:
	return player_data.name
