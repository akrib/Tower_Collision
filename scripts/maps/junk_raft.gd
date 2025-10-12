extends Node2D
class_name JunkRaft

# ============================================================================
# VARIABLES DE MOUVEMENT ET VITESSE
# ============================================================================

@export_group("Speed Settings")
@export var base_speed: float = 50.0  # Vitesse de base/repos
@export var current_speed: float = 50.0  # Vitesse actuelle
@export var max_speed: float = 250.0  # Vitesse maximale (boost)
@export var min_speed: float = -50.0  # Vitesse minimale (recul)

@export_group("Inertia & Acceleration")
@export var acceleration_rate: float = 500.0  # Accélération lors du swipe
@export var deceleration_rate: float = 200.0  # Retour à la vitesse de base
@export var friction: float = 0.95  # Friction pour ralentissement naturel

@export_group("Fuel System")
@export var fuel_level: float = 100.0  # Niveau de carburant (0-100)
@export var max_fuel: float = 100.0
@export var fuel_cost_per_swipe: float = 20.0  # Coût d'un swipe
@export var fuel_recharge_rate: float = 5.0  # Recharge par seconde

@export_group("Swipe Detection")
@export var min_swipe_distance: float = 50.0  # Distance minimale pour valider un swipe
@export var swipe_timeout: float = 0.5  # Temps max pour compléter un swipe

@export_group("Impact Damage")
@export var impact_damage_factor: float = 2.0  # Multiplicateur de dégâts par vitesse
@export var base_impact_damage: float = 10.0  # Dégâts de base à l'impact

# ============================================================================
# VARIABLES INTERNES
# ============================================================================

# Détection du swipe
var swipe_start_pos: Vector2 = Vector2.ZERO
var swipe_start_time: float = 0.0
var is_swiping: bool = false
var target_speed: float = 0.0  # Vitesse cible après swipe

# État du jeu
var is_in_combat: bool = false
var can_swipe: bool = true

# Signaux
signal speed_changed(new_speed: float)
signal fuel_changed(new_fuel: float)
signal swipe_performed(direction: Vector2, success: bool)
signal impact_occurred(damage: float)
signal out_of_fuel()

# Référence au fuel bar (optionnel)
@onready var fuel_bar: ProgressBar = null

func _ready():
	current_speed = base_speed
	target_speed = base_speed
	
	# Chercher la barre de fuel si elle existe
	if has_node("UI/FuelBar"):
		fuel_bar = $UI/FuelBar
		update_fuel_ui()

func _process(delta: float):
	# Recharger le carburant
	recharge_fuel(delta)
	
	# Appliquer l'inertie
	apply_inertia(delta)
	
	# Déplacer l'île
	if is_in_combat:
		move_raft(delta)
	
	# Mettre à jour l'UI
	update_fuel_ui()

func _input(event: InputEvent):
	if not can_swipe or not is_in_combat:
		return
	
	# Détection du swipe tactile (ou souris pour debug)
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			start_swipe(event.position)
		else:
			end_swipe(event.position)
	
	# Suivi du swipe en cours
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		update_swipe(event.position)

# ============================================================================
# SYSTÈME DE SWIPE
# ============================================================================

func start_swipe(pos: Vector2):
	"""Démarre la détection d'un swipe"""
	swipe_start_pos = pos
	swipe_start_time = Time.get_ticks_msec() / 1000.0
	is_swiping = true

func update_swipe(pos: Vector2):
	"""Met à jour la position pendant le swipe (pour feedback visuel)"""
	if not is_swiping:
		return
	
	var swipe_vector = pos - swipe_start_pos
	# Ici vous pouvez ajouter un feedback visuel (flèche, traînée, etc.)

func end_swipe(pos: Vector2):
	"""Termine le swipe et applique l'effet si valide"""
	if not is_swiping:
		return
	
	is_swiping = false
	
	var swipe_vector = pos - swipe_start_pos
	var swipe_distance = swipe_vector.length()
	var swipe_time = (Time.get_ticks_msec() / 1000.0) - swipe_start_time
	
	# Vérifier si le swipe est valide
	if swipe_distance < min_swipe_distance:
		swipe_performed.emit(swipe_vector, false)
		return
	
	if swipe_time > swipe_timeout:
		swipe_performed.emit(swipe_vector, false)
		return
	
	# Vérifier le carburant
	if fuel_level < fuel_cost_per_swipe:
		out_of_fuel.emit()
		swipe_performed.emit(swipe_vector, false)
		show_feedback("Pas assez de carburant!", Color.RED)
		return
	
	# Déterminer la direction du swipe
	var swipe_direction = swipe_vector.normalized()
	var horizontal_component = swipe_direction.x
	
	# Appliquer l'effet du swipe
	if abs(horizontal_component) > 0.5:  # Swipe horizontal dominant
		if horizontal_component > 0:
			# Swipe vers la droite = Accélération
			perform_acceleration_swipe(swipe_distance)
		else:
			# Swipe vers la gauche = Décélération/Recul
			perform_deceleration_swipe(swipe_distance)
		
		# Consommer le carburant
		consume_fuel(fuel_cost_per_swipe)
		swipe_performed.emit(swipe_vector, true)
	else:
		swipe_performed.emit(swipe_vector, false)

func perform_acceleration_swipe(distance: float):
	"""Applique une accélération basée sur la distance du swipe"""
	var boost_multiplier = clamp(distance / 100.0, 0.5, 2.0)
	target_speed = min(current_speed + (acceleration_rate * boost_multiplier * 0.1), max_speed)
	show_feedback("BOOST!", Color.GREEN)
	create_boost_particles()

func perform_deceleration_swipe(distance: float):
	"""Applique une décélération/recul basée sur la distance du swipe"""
	var brake_multiplier = clamp(distance / 100.0, 0.5, 2.0)
	target_speed = max(current_speed - (deceleration_rate * brake_multiplier * 0.1), min_speed)
	show_feedback("FREIN!", Color.YELLOW)
	create_brake_particles()

# ============================================================================
# SYSTÈME D'INERTIE ET MOUVEMENT
# ============================================================================

func apply_inertia(delta: float):
	"""Applique l'inertie et ramène progressivement à la vitesse de base"""
	# Si on a une vitesse cible (après swipe), y tendre rapidement
	if abs(current_speed - target_speed) > 1.0:
		current_speed = lerp(current_speed, target_speed, acceleration_rate * delta / 100.0)
	else:
		target_speed = current_speed
	
	# Retour progressif vers la vitesse de base
	if abs(current_speed - base_speed) > 1.0:
		var return_speed = deceleration_rate * delta
		if current_speed > base_speed:
			current_speed = max(current_speed - return_speed, base_speed)
		else:
			current_speed = min(current_speed + return_speed, base_speed)
	
	# Appliquer la friction
	if abs(current_speed) > 0.1:
		current_speed *= friction
	
	# Limiter la vitesse
	current_speed = clamp(current_speed, min_speed, max_speed)
	
	speed_changed.emit(current_speed)

func move_raft(delta: float):
	"""Déplace l'île selon la vitesse actuelle"""
	position.x += current_speed * delta
	
	# Limites de la carte (optionnel)
	# position.x = clamp(position.x, min_x, max_x)

# ============================================================================
# SYSTÈME DE CARBURANT
# ============================================================================

func recharge_fuel(delta: float):
	"""Recharge le carburant passivement"""
	if fuel_level < max_fuel:
		fuel_level = min(fuel_level + fuel_recharge_rate * delta, max_fuel)
		fuel_changed.emit(fuel_level)

func consume_fuel(amount: float):
	"""Consomme du carburant"""
	fuel_level = max(fuel_level - amount, 0.0)
	fuel_changed.emit(fuel_level)
	
	if fuel_level <= 0:
		out_of_fuel.emit()

func add_fuel(amount: float):
	"""Ajoute du carburant (bonus, pickups, etc.)"""
	fuel_level = min(fuel_level + amount, max_fuel)
	fuel_changed.emit(fuel_level)

func update_fuel_ui():
	"""Met à jour la barre de carburant"""
	if fuel_bar:
		fuel_bar.value = (fuel_level / max_fuel) * 100.0

# ============================================================================
# SYSTÈME DE COLLISION ET DÉGÂTS D'IMPACT
# ============================================================================

func calculate_impact_damage(collision_speed: float = -1.0) -> float:
	"""Calcule les dégâts d'impact basés sur la vitesse"""
	var impact_speed = collision_speed if collision_speed > 0 else current_speed
	
	# Formule: Dégâts de base + (vitesse actuelle - vitesse de base) × facteur
	var speed_difference = impact_speed - base_speed
	var extra_damage = max(speed_difference, 0.0) * impact_damage_factor
	
	var total_damage = base_impact_damage + extra_damage
	return total_damage

func on_collision_with_enemy():
	"""Appelé lors de la collision avec l'île ennemie"""
	var damage = calculate_impact_damage()
	impact_occurred.emit(damage)
	
	# Réduire drastiquement la vitesse après l'impact
	current_speed = base_speed * 0.3
	target_speed = current_speed
	
	# Effet visuel d'impact
	create_impact_effect()
	
	return damage

# ============================================================================
# EFFETS VISUELS ET FEEDBACK
# ============================================================================

func show_feedback(text: String, color: Color):
	"""Affiche un texte de feedback temporaire"""
	# Créer un label temporaire
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", color)
	label.position = Vector2(-50, -100)
	add_child(label)
	
	# Animation de montée et disparition
	var tween = create_tween()
	tween.tween_property(label, "position:y", -150, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func create_boost_particles():
	"""Crée des particules de boost"""
	# À implémenter avec CPUParticles2D ou GPUParticles2D
	print("🚀 Boost particles!")

func create_brake_particles():
	"""Crée des particules de freinage"""
	# À implémenter avec CPUParticles2D ou GPUParticles2D
	print("🛑 Brake particles!")

func create_impact_effect():
	"""Crée un effet visuel d'impact"""
	# Shake de caméra
	if has_node("/root/Camera2D"):
		var camera = get_node("/root/Camera2D")
		shake_camera(camera, 0.5, 10.0)
	
	# Particules d'explosion
	print("💥 Impact effect!")

func shake_camera(camera: Camera2D, duration: float, intensity: float):
	"""Secoue la caméra"""
	var original_offset = camera.offset
	var tween = create_tween()
	
	for i in range(int(duration * 30)):  # 30 FPS
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "offset", original_offset + shake_offset, 0.033)
	
	tween.tween_property(camera, "offset", original_offset, 0.1)

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

func start_combat():
	"""Démarre la phase de combat"""
	is_in_combat = true
	can_swipe = true

func end_combat():
	"""Termine la phase de combat"""
	is_in_combat = false
	can_swipe = false
	current_speed = base_speed
	target_speed = base_speed

func reset_to_base():
	"""Réinitialise l'île à l'état de base"""
	current_speed = base_speed
	target_speed = base_speed
	fuel_level = max_fuel
	position = Vector2.ZERO

func get_speed_percentage() -> float:
	"""Retourne le pourcentage de vitesse (0-100)"""
	var speed_range = max_speed - min_speed
	return ((current_speed - min_speed) / speed_range) * 100.0

func is_boosting() -> bool:
	"""Vérifie si l'île est en boost (au-dessus de la vitesse de base)"""
	return current_speed > base_speed + 10.0

func is_braking() -> bool:
	"""Vérifie si l'île est en freinage (en-dessous de la vitesse de base)"""
	return current_speed < base_speed - 10.0

# ============================================================================
# GETTERS ET SETTERS
# ============================================================================

func get_fuel_percentage() -> float:
	return (fuel_level / max_fuel) * 100.0

func can_perform_swipe() -> bool:
	return fuel_level >= fuel_cost_per_swipe and can_swipe

func set_max_speed(new_max: float):
	max_speed = new_max
	current_speed = clamp(current_speed, min_speed, max_speed)

func set_fuel_recharge_rate(new_rate: float):
	fuel_recharge_rate = new_rate
