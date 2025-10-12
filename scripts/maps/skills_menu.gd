extends Node2D

@onready var skill_points_label = $UI/MainPanel/VBoxContainer/Header/SkillPoints
@onready var player_profile = $PlayerProfileUI

# Compétences
@onready var damage_skill = $UI/MainPanel/VBoxContainer/SkillsContainer/DamageSkill
@onready var attack_speed_skill = $UI/MainPanel/VBoxContainer/SkillsContainer/AttackSpeedSkill
@onready var health_skill = $UI/MainPanel/VBoxContainer/SkillsContainer/HealthSkill

func _ready():
	# Connecter les boutons d'amélioration
	damage_skill.get_node("VBox/UpgradeBtn").pressed.connect(_on_upgrade_damage)
	attack_speed_skill.get_node("VBox/UpgradeBtn").pressed.connect(_on_upgrade_attack_speed)
	health_skill.get_node("VBox/UpgradeBtn").pressed.connect(_on_upgrade_health)
	
	# Connecter les boutons de navigation
	$UI/MainPanel/VBoxContainer/BottomButtons/MenuBtn.pressed.connect(_on_menu_pressed)
	$UI/MainPanel/VBoxContainer/BottomButtons/EditorBtn.pressed.connect(_on_editor_pressed)
	$UI/MainPanel/VBoxContainer/BottomButtons/BattleBtn.pressed.connect(_on_battle_pressed)
	
	# Connecter les signaux de PlayerData
	PlayerData.skill_upgraded.connect(_on_skill_upgraded)
	
	# Mettre à jour l'affichage
	update_ui()

func update_ui():
	# Mettre à jour les points de compétence
	var points = PlayerData.get_skill_points()
	skill_points_label.text = "Points de compétence disponibles: %d" % points
	
	# Mettre à jour chaque compétence
	update_skill_display("tower_damage", damage_skill)
	update_skill_display("tower_attack_speed", attack_speed_skill)
	update_skill_display("tower_health", health_skill)

func update_skill_display(skill_name: String, skill_panel: Panel):
	var level = PlayerData.get_skill_level(skill_name)
	var vbox = skill_panel.get_node("VBox")
	var level_label = vbox.get_node("Level")
	var effect_label = vbox.get_node("Effect")
	var upgrade_btn = vbox.get_node("UpgradeBtn")
	
	# Mettre à jour le niveau
	level_label.text = "Niveau: %d / 99" % level
	
	# Mettre à jour l'effet
	match skill_name:
		"tower_damage":
			var bonus = level * 5
			effect_label.text = "Bonus actuel: +%d%%" % bonus
		"tower_attack_speed":
			var bonus = level * 5
			effect_label.text = "Bonus actuel: +%d%%" % bonus
		"tower_health":
			var bonus = level * 10
			effect_label.text = "Bonus actuel: +%d HP" % bonus
	
	# Désactiver le bouton si pas de points ou niveau max
	var can_upgrade = PlayerData.get_skill_points() > 0 and level < 99
	upgrade_btn.disabled = not can_upgrade
	
	if level >= 99:
		upgrade_btn.text = "✓ MAX"
	elif PlayerData.get_skill_points() <= 0:
		upgrade_btn.text = "⬆️ AMÉLIORER (Pas de points)"
	else:
		upgrade_btn.text = "⬆️ AMÉLIORER"

# Callbacks d'amélioration
func _on_upgrade_damage():
	if PlayerData.upgrade_skill("tower_damage"):
		show_upgrade_feedback(damage_skill, "PUISSANCE")

func _on_upgrade_attack_speed():
	if PlayerData.upgrade_skill("tower_attack_speed"):
		show_upgrade_feedback(attack_speed_skill, "CADENCE")

func _on_upgrade_health():
	if PlayerData.upgrade_skill("tower_health"):
		show_upgrade_feedback(health_skill, "RÉSISTANCE")

func _on_skill_upgraded(_skill_name: String, _new_level: int):
	update_ui()
	# Mettre à jour le profil du joueur
	if player_profile:
		player_profile.update_ui()

func show_upgrade_feedback(skill_panel: Panel, skill_name: String):
	# Animation de feedback visuel
	var tween = create_tween()
	tween.tween_property(skill_panel, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(skill_panel, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Son (à ajouter plus tard)
	print("%s amélioré!" % skill_name)

# Navigation
func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_editor_pressed():
	get_tree().change_scene_to_file("res://scenes/editor/tower_editor.tscn")

func _on_battle_pressed():
	get_tree().change_scene_to_file("res://scenes/maps/battlefield.tscn")
