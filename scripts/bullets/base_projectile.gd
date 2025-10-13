extends CharacterBody2D
class_name BaseProjectile

# ============================================================================
# SYSTÈME DE PROJECTILES BALISTIQUES
# Tous les projectiles suivent des trajectoires en arc (parabole)
# vers une position FIXE définie au lancement
# ============================================================================

# Énumération pour les équipes
enum Team { NONE, PLAYER, ENEMY }

# Configuration de base
@export_group("Base Stats")
@export var team: Team = Team.NONE
@export var bullet_damage: int = 1

@export_group("Ballistic Physics")
@export var initial_speed: float = 800.0  # Vitesse initiale
@export var arc_height: float = 200.0  # Hauteur de l'arc
@export var gravity: float = 1500.0  # Force de gravité
@export var lifetime: float = 5.0  # Durée de vie max

@export_group("Special Effects")
@export var splash_radius: float = 0.0  # Rayon d'explosion
@export var slow_duration: float = 0.0
@export var slow_amount: float = 0.0
@export var poison_damage: int = 0
@export var poison_duration: float = 0.0
@export var piercing: int = 0  # Nombre de cibles traversées

# Position cible FIXE (définie au lancement)
var target_position: Vector2 = Vector2.ZERO

# Variables de trajectoire balistique
var start_position: Vector2 = Vector2.ZERO
var velocity_2d: Vector2 = Vector2.ZERO
var vertical_velocity: float = 0.0
var travel_time: float = 0.0
var max_travel_time: float = 2.0

# État
var time_alive: float = 0.0
var has_hit_targets = []
var hit_count: int = 0
var is_initialized: bool = false

# Effets visuels
@onready var sprite = $TowerDefenseTile251 if has_node("TowerDefenseTile251") else null
@onready var impact_particles = preload("res://scenes/effects/explode.tscn")
@onready var water_splash = preload("res://scenes/effects/smoke.tscn")  # On réutilise smoke pour l'effet geyser

func _ready():
	# Timer de sécurité
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_expired)

func _physics_process(delta):
	if not is_initialized:
		return
	
	time_alive += delta
	travel_time += delta
	
	# Mouvement balistique
	move_ballistic(delta)
	
	# Vérifier si on a atteint la destination
	check_arrival()

# ============================================================================
# CONFIGURATION DU PROJECTILE
# ============================================================================

func setup(p_team: Team, p_damage: int, p_target, p_speed: float = 800.0):
	"""Configure le projectile depuis la tour"""
	team = p_team
	bullet_damage = p_damage
	initial_speed = p_speed
	
	# Enregistrer la position de départ
	start_position = global_position
	
	# Déterminer la position cible FIXE
	if is_instance_valid(p_target):
		# Si c'est un objet, prendre sa position ACTUELLE
		target_position = p_target.global_position
	elif p_target is Vector2:
		# Si c'est déjà une position
		target_position = p_target
	else:
		# Fallback: projeter devant
		target_position = global_position + Vector2(400, 0)
	
	# Calculer la trajectoire balistique
	calculate_ballistic_trajectory()
	
	is_initialized = true
	
	print("🎯 Projectile lancé vers: %s (distance: %.0f)" % [target_position, start_position.distance_to(target_position)])

func calculate_ballistic_trajectory():
	"""Calcule la vélocité initiale pour atteindre target_position avec un arc"""
	var distance_vector = target_position - start_position
	var horizontal_distance = distance_vector.length()
	
	# Éviter la division par zéro
	if horizontal_distance < 1.0:
		target_position = start_position + Vector2(100, 0)
		distance_vector = target_position - start_position
		horizontal_distance = distance_vector.length()
	
	# Direction horizontale normalisée
	var direction = distance_vector.normalized()
	
	# Calculer le temps de vol basé sur la distance
	# Plus c'est loin, plus le temps de vol est long
	max_travel_time = sqrt(horizontal_distance / 200.0)  # Formule empirique
	max_travel_time = clamp(max_travel_time, 0.3, 2.0)
	
	# Calculer la vélocité horizontale nécessaire
	velocity_2d = direction * (horizontal_distance / max_travel_time)
	
	# Calculer la vélocité verticale pour créer un arc parabolique
	# On veut que le projectile atteigne arc_height à mi-chemin
	# Formule: v0 = (h + 0.5*g*t²) / t où t = max_travel_time/2
	var half_time = max_travel_time / 2.0
	vertical_velocity = -(arc_height + 0.5 * gravity * half_time * half_time) / half_time
	
	print("  📐 Trajectoire: distance=%.0f, temps=%.1fs, v_horiz=%.0f, v_vert=%.0f" % [horizontal_distance, max_travel_time, velocity_2d.length(), vertical_velocity])

# ============================================================================
# MOUVEMENT BALISTIQUE
# ============================================================================

func move_ballistic(delta):
	"""Mouvement en parabole avec gravité"""
	# Mouvement horizontal (constant)
	velocity = velocity_2d
	
	# Mouvement vertical (avec gravité)
	vertical_velocity += gravity * delta
	
	# Simuler le mouvement vertical en ajustant la position Y
	# (Godot n'a pas de vrai axe Z, on simule)
	var vertical_offset = vertical_velocity * delta
	position.y += vertical_offset
	
	# Rotation du sprite selon la trajectoire
	if sprite:
		var angle = atan2(vertical_velocity, velocity_2d.length())
		sprite.rotation = angle
	
	# Déplacer horizontalement
	move_and_slide()

func check_arrival():
	"""Vérifie si le projectile a atteint sa destination"""
	var distance_to_target = global_position.distance_to(target_position)
	
	# Si on est proche de la cible OU si on a dépassé le temps de vol
	if distance_to_target < 50.0 or travel_time >= max_travel_time * 1.2:
		impact_at_position(global_position)

# ============================================================================
# SYSTÈME D'IMPACT
# ============================================================================

func impact_at_position(impact_pos: Vector2):
	"""Gère l'impact du projectile à la position donnée"""
	print("💥 Impact à: %s" % impact_pos)
	
	# Chercher des cibles à l'impact
	var targets_hit = find_targets_at_position(impact_pos)
	
	if targets_hit.size() > 0:
		# Toucher les cibles trouvées
		for target in targets_hit:
			if target not in has_hit_targets:
				hit_target(target)
		
		# Effet d'explosion si AOE
		if splash_radius > 0.0:
			apply_splash_damage(impact_pos)
		
		# Effet visuel d'impact
		spawn_impact_effect(impact_pos)
	else:
		# Aucune cible touchée = geyser d'eau
		spawn_water_splash(impact_pos)
	
	# Détruire le projectile
	queue_free()

func find_targets_at_position(pos: Vector2) -> Array:
	"""Trouve les cibles (tuiles/tours) à proximité de la position"""
	var targets = []
	var detection_radius = 30.0  # Rayon de détection
	
	# Déterminer le groupe ennemi
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	
	# Chercher les tuiles ennemies
	var tiles = get_tree().get_nodes_in_group("tile")
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	for tile in tiles:
		if tile in enemies:
			var distance = pos.distance_to(tile.global_position)
			if distance < detection_radius:
				targets.append(tile)
	
	# Chercher les tours ennemies
	var towers = get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if tower in enemies:
			var distance = pos.distance_to(tower.global_position)
			if distance < detection_radius:
				targets.append(tower)
	
	return targets

func hit_target(target):
	"""Applique les dégâts et effets à une cible"""
	has_hit_targets.append(target)
	hit_count += 1
	
	# Appliquer les dégâts
	apply_damage(target)
	
	# Effets spéciaux
	apply_special_effects(target)
	
	print("  ✓ Touché: %s (dégâts: %d)" % [target.name if target.has_method("get_name") else "Target", bullet_damage])

func apply_damage(target):
	"""Applique les dégâts à la cible"""
	if target.has_method("take_damage"):
		target.take_damage(bullet_damage)
	elif "health" in target:
		target.health -= bullet_damage

func apply_splash_damage(impact_position: Vector2):
	"""Applique des dégâts en zone"""
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	for enemy in enemies:
		if enemy in has_hit_targets:
			continue
		
		var distance = impact_position.distance_to(enemy.global_position)
		if distance <= splash_radius:
			# Dégâts réduits avec la distance
			var damage_multiplier = 1.0 - (distance / splash_radius) * 0.5
			var splash_damage = int(bullet_damage * damage_multiplier)
			
			if enemy.has_method("take_damage"):
				enemy.take_damage(splash_damage)
			elif "health" in enemy:
				enemy.health -= splash_damage
			
			has_hit_targets.append(enemy)
			
			print("  💨 Splash: %s (dégâts: %d)" % [enemy.name if enemy.has_method("get_name") else "Target", splash_damage])

func apply_special_effects(target):
	"""Applique les effets spéciaux (ralentissement, poison, etc.)"""
	# Ralentissement
	if slow_duration > 0.0 and slow_amount > 0.0:
		if target.has_method("apply_slow"):
			target.apply_slow(slow_amount, slow_duration)
	
	# Poison
	if poison_damage > 0 and poison_duration > 0.0:
		if target.has_method("apply_poison"):
			target.apply_poison(poison_damage, poison_duration)

# ============================================================================
# EFFETS VISUELS
# ============================================================================

func spawn_impact_effect(pos: Vector2):
	"""Crée un effet d'explosion"""
	if impact_particles:
		var explosion = impact_particles.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = pos
		explosion.emitting = true
		
		# Ajuster la couleur selon l'équipe
		if team == Team.PLAYER:
			explosion.modulate = Color(1.0, 0.8, 0.3)  # Orange
		else:
			explosion.modulate = Color(0.8, 0.3, 0.3)  # Rouge

func spawn_water_splash(pos: Vector2):
	"""Crée un effet de geyser d'eau (splash dans l'eau)"""
	if water_splash:
		var splash = water_splash.instantiate()
		get_tree().current_scene.add_child(splash)
		splash.global_position = pos
		
		# Configuration pour effet de geyser
		if splash is CPUParticles2D:
			splash.emitting = true
			splash.amount = 15
			splash.lifetime = 1.0
			splash.one_shot = true
			splash.explosiveness = 0.8
			
			# Direction vers le haut (geyser)
			splash.direction = Vector2(0, -1)
			splash.spread = 45.0
			
			# Vitesse
			splash.initial_velocity_min = 100.0
			splash.initial_velocity_max = 200.0
			
			# Gravité vers le bas
			splash.gravity = Vector2(0, 300)
			
			# Couleur bleue pour l'eau
			splash.modulate = Color(0.3, 0.6, 1.0, 0.6)
			
			# Taille des particules
			splash.scale_amount_min = 2.0
			splash.scale_amount_max = 4.0
	
	print("  💧 Geyser d'eau à: %s" % pos)

func _on_lifetime_expired():
	"""Détruit le projectile après sa durée de vie"""
	print("⏱️ Projectile expiré")
	spawn_water_splash(global_position)
	queue_free()

# ============================================================================
# COLLISIONS (DÉTECTION ANTICIPÉE)
# ============================================================================

func _on_area_2d_area_entered(area):
	"""Collision avec une area (tuiles) - détection anticipée"""
	# On vérifie si c'est une cible valide
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	
	if area.is_in_group("tile") and area.is_in_group(enemy_group):
		# Impact anticipé sur une tuile
		if area not in has_hit_targets:
			impact_at_position(area.global_position)

func _on_area_2d_body_entered(body):
	"""Collision avec un body (tours) - détection anticipée"""
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	
	if body.is_in_group("tower") and body.is_in_group(enemy_group):
		# Impact anticipé sur une tour
		if body not in has_hit_targets:
			impact_at_position(body.global_position)

# ============================================================================
# MÉTHODE DE COMPATIBILITÉ (ANCIEN SYSTÈME)
# ============================================================================

func set_target(target):
	"""Pour compatibilité avec l'ancien système"""
	if is_instance_valid(target):
		target_position = target.global_position
	calculate_ballistic_trajectory()
	is_initialized = true
