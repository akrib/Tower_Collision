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

func _ready():
	# Créer les styles pour la barre XP
	create_xp_styles()
	
	# Connecter les signaux de PlayerData
	PlayerData.level_up.connect(_on_level_up)
	PlayerData.xp_gained.connect(_on_xp_gained)
	
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

func update_ui():
	var data = PlayerData.player_data
	
	# Mettre à jour le nom
	player_name_label.text = data.name
	
	# Mettre à jour le niveau
	level_value_label.text = str(data.level)
	
	# Vérifier si niveau max
	if data.level >= 99:
		# Niveau max
		xp_progress_bar.add_theme_stylebox_override("fill", max_xp_style)
		xp_progress_bar.value = xp_progress_bar.max_value
		xp_text_label.text = "MAX"
		xp_text_label.add_theme_font_size_override("font_size", 18)
		xp_text_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	else:
		# Niveau normal
		xp_progress_bar.add_theme_stylebox_override("fill", normal_xp_style)
		xp_progress_bar.max_value = data.xp_to_next_level
		xp_progress_bar.value = data.current_xp
		xp_text_label.text = "%d / %d" % [data.current_xp, data.xp_to_next_level]
		xp_text_label.add_theme_font_size_override("font_size", 14)
		xp_text_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	# Mettre à jour l'avatar
	update_avatar()

func update_avatar():
	var avatar_path = PlayerData.player_data.avatar_path
	if avatar_path != "" and FileAccess.file_exists(avatar_path):
		var image = Image.load_from_file(avatar_path)
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

# Fonction pour ajouter de l'XP (raccourci vers PlayerData)
func add_xp(amount: int):
	PlayerData.add_xp(amount)

# Callbacks des signaux
func _on_level_up(new_level: int):
	update_ui()
	show_level_up_notification(new_level)

func _on_xp_gained(_amount: int):
	update_ui()

func show_level_up_notification(new_level: int):
	print("🎉 LEVEL UP! Nouveau niveau: %d" % new_level)
	# TODO: Ajouter une animation/particules/son plus tard

# Fonction pour changer le nom du joueur
func set_player_name(new_name: String):
	PlayerData.player_data.name = new_name
	PlayerData.save_data()
	update_ui()

# Fonction pour changer l'avatar
func set_avatar(image_path: String):
	PlayerData.player_data.avatar_path = image_path
	PlayerData.save_data()
	update_ui()
