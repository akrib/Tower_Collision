extends Node2D

# Références aux UI
@onready var fuel_bar = $UI/Control/FuelBar
@onready var speed_bar = $UI/Control/SpeedBar
@onready var speed_label = $UI/Control/SpeedLabel
@onready var swipe_indicator = $UI/Control/SwipeIndicator
@onready var boost_particles = $Particles/BoostParticles
@onready var brake_particles = $Particles/BrakeParticles

# Référence au JunkRaft (self si c'est le même script)
var raft: JunkRaft

func _ready():
	raft = self as JunkRaft
	
	# Connecter les signaux
	speed_changed.connect(_on_speed_changed)
	fuel_changed.connect(_on_fuel_changed)
	swipe_performed.connect(_on_swipe_performed)
	out_of_fuel.connect(_on_out_of_fuel)
	
	# Démarrer le combat après un délai
	await get_tree().create_timer(1.0).timeout
	start_combat()
	
	# Afficher les instructions temporairement
	show_instructions()

func show_instructions():
	"""Affiche les instructions puis les cache"""
	var instructions = $UI/Control/Instructions
	instructions.visible = true
	
	await get_tree().create_timer(5.0).timeout
	
	var tween = create_tween()
	tween.tween_property(instructions, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): instructions.visible = false)

# ============================================================================
# CALLBACKS DES SIGNAUX
# ============================================================================

func _on_speed_changed(new_speed: float):
	"""Met à jour la barre et le label de vitesse"""
	# Mettre à jour la barre (pourcentage relatif à la plage min-max)
	var speed_percentage = get_speed_percentage()
	speed_bar.value = speed_percentage
	
	# Mettre à jour le label
	speed_label.text = "Vitesse: %.1f m/s" % new_speed
	
	# Changer la couleur selon la vitesse
	var style = speed_bar.get_theme_stylebox("fill")
	if style is StyleBoxFlat:
		if is_boosting():
			style.bg_color = Color(0.2, 1, 0.3)  # Vert pour boost
		elif is_braking():
			style.bg_color = Color(1, 0.3, 0.2)  # Rouge pour freinage
		else:
			style.bg_color = Color(1, 0.5, 0.2)  # Orange pour normal

func _on_fuel_changed(new_fuel: float):
	"""Met à jour la barre de carburant"""
	fuel_bar.value = (new_fuel / max_fuel) * 100.0
	
	# Changer la couleur si faible
	var style = fuel_bar.get_theme_stylebox("fill")
	if style is StyleBoxFlat:
		if new_fuel < 20.0:
			style.bg_color = Color(1, 0.2, 0.2)  # Rouge si presque vide
		elif new_fuel < 50.0:
			style.bg_color = Color(1, 0.8, 0.2)  # Jaune si moyen
		else:
			style.bg_color = Color(0.2, 0.8, 1)  # Bleu si bon

func _on_swipe_performed(direction: Vector2, success: bool):
	"""Gère le feedback visuel du swipe"""
	if success:
		if direction.x > 0:
			# Swipe avant = boost
			boost_particles.emitting = true
			show_swipe_feedback("BOOST!", Color.GREEN)
		else:
			# Swipe arrière = frein
			brake_particles.emitting = true
			show_swipe_feedback("FREIN!", Color.YELLOW)
	else:
		show_swipe_feedback("Swipe invalide", Color.RED)

func _on_out_of_fuel():
	"""Alerte quand le carburant est vide"""
	show_swipe_feedback("CARBURANT VIDE!", Color.RED)
	
	# Faire clignoter la barre de fuel
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(fuel_bar, "modulate", Color(1, 0, 0), 0.2)
	tween.tween_property(fuel_bar, "modulate", Color(1, 1, 1), 0.2)

func show_swipe_feedback(text: String, color: Color):
	"""Affiche un texte de feedback au centre de l'écran"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", color)
	label.position = get_viewport_rect().size / 2 - Vector2(100, 50)
	$UI/Control.add_child(label)
	
	# Animation
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

# ============================================================================
# INTÉGRATION AVEC LE SYSTÈME DE COMBAT
# ============================================================================

func start_battle_with_enemy(enemy_raft: JunkRaft):
	"""Démarre une bataille contre une île ennemie"""
	start_combat()
	
	# Afficher l'indicateur de swipe
	swipe_indicator.visible = true
	await get_tree().create_timer(2.0).timeout
	swipe_indicator.visible = false

func on_collision_detected(enemy):
	"""Appelé quand l'île entre en collision avec l'ennemi"""
	var damage = on_collision_with_enemy()
	
	# Afficher les dégâts infligés
	show_damage_popup(damage)
	
	# Infliger les dégâts à l'ennemi
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

func show_damage_popup(damage: float):
	"""Affiche un popup de dégâts"""
	var label = Label.new()
	label.text = "💥 %.0f dégâts!" % damage
	label.add_theme_font_size_override("font_size", 56)
	
	# Couleur selon les dégâts
	var color = Color.WHITE
	if damage > 50:
		color = Color(1, 0.2, 0.2)  # Rouge pour gros dégâts
	elif damage > 30:
		color = Color(1, 0.6, 0)  # Orange
	else:
		color = Color(1, 1, 0.2)  # Jaune
	
	label.add_theme_color_override("font_color", color)
	label.position = get_viewport_rect().size / 2 - Vector2(150, 100)
	$UI/Control.add_child(label)
	
	# Animation d'impact
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(label, "position:y", label.position.y - 100, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

# ============================================================================
# HELPERS ET DEBUG
# ============================================================================

func _process(delta):
	# Debug: afficher les infos dans la console
	if Input.is_action_just_pressed("ui_cancel"):
		print("=== RAFT DEBUG ===")
		print("Speed: %.1f / %.1f" % [current_speed, max_speed])
		print("Fuel: %.1f / %.1f" % [fuel_level, max_fuel])
		print("Can swipe: ", can_perform_swipe())
		print("Is boosting: ", is_boosting())
		print("==================")

# ============================================================================
# TOUCHES DE DEBUG (À RETIRER EN PRODUCTION)
# ============================================================================

func _unhandled_input(event):
	# Debug: touches clavier pour tester
	if event.is_action_pressed("ui_right"):
		perform_acceleration_swipe(100.0)
		consume_fuel(fuel_cost_per_swipe)
	
	if event.is_action_pressed("ui_left"):
		perform_deceleration_swipe(100.0)
		consume_fuel(fuel_cost_per_swipe)
	
	if event.is_action_pressed("ui_up"):
		add_fuel(50.0)
		show_swipe_feedback("+50 Fuel!", Color.CYAN)
