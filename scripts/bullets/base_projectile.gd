extends CharacterBody2D
class_name BaseProjectile

# ============================================================================
# SYSTÈME DE PROJECTILES AVEC INTÉGRATION VERLET + PRÉDICTION DE TRAJECTOIRE
# ============================================================================

enum Team { NONE, PLAYER, ENEMY }
enum ProjectileType { DIRECT, HOMING, BALLISTIC, BEAM }

# Configuration
@export_group("Base Stats")
@export var team: Team = Team.NONE
@export var projectile_type: ProjectileType = ProjectileType.BALLISTIC
@export var bullet_damage: int = 1
@export var speed: int = 2000
@export var piercing: int = 0

@export_group("Verlet Physics")
@export var initial_velocity: Vector2 = Vector2(400.0, -300.0)
@export var gravity_force: Vector2 = Vector2(0.0, 980.0)  # Gravité réaliste
@export var air_resistance: float = 0.99  # Résistance de l'air
@export var lifetime: float = 5.0

@export_group("Trajectory Prediction")
@export var show_trajectory: bool = true
@export var trajectory_points: int = 30
@export var trajectory_color: Color = Color(1, 1, 0, 0.5)

@export_group("Special Effects")
@export var splash_radius: float = 0.0
@export var slow_duration: float = 0.0
@export var slow_amount: float = 0.0
@export var poison_damage: int = 0
@export var poison_duration: float = 0.0

# Verlet Integration Variables
var current_position: Vector2 = Vector2.ZERO
var previous_position: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO

# Marqueur de cible (ligne horizontale)
var target_marker: Area2D = null
var target_position: Vector2 = Vector2.ZERO

# Ligne de trajectoire prédite
var trajectory_line: Line2D = null

# État
var time_alive: float = 0.0
var has_hit_targets = []
var hit_count: int = 0
var is_initialized: bool = false
var has_impacted: bool = false

# Effets
@onready var sprite = $TowerDefenseTile251 if has_node("TowerDefenseTile251") else null
@onready var impact_particles = preload("res://scenes/effects/explode.tscn")
@onready var water_splash = preload("res://scenes/effects/smoke.tscn")

func _ready():
	# Timer de sécurité
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_expired)
	
	print("🔫 Projectile Verlet créé à: %s" % global_position)

func _physics_process(delta):
	if not is_initialized:
		return
	
	time_alive += delta
	
	# Intégration Verlet
	verlet_integrate(delta)
	
	# Vérifier si touche le sol
	if global_position.y > get_viewport_rect().size.y:
		print("⚠️ Projectile sorti en bas de l'écran")
		spawn_water_splash(global_position)
		cleanup()
		return
	
	# Vérifier collision avec marqueur
	check_marker_collision()

# ============================================================================
# CONFIGURATION & PRÉDICTION DE TRAJECTOIRE
# ============================================================================

func setup(p_team: Team, p_damage: int, p_target, launch_speed: float = 600.0):
	"""Configure le projectile avec intégration Verlet"""
	team = p_team
	bullet_damage = p_damage
	
	# Position de départ
	current_position = global_position
	previous_position = global_position
	
	# Déterminer la cible
	if is_instance_valid(p_target):
		target_position = p_target.global_position
	elif p_target is Vector2:
		target_position = p_target
	else:
		var forward = Vector2(1, 0) if team == Team.PLAYER else Vector2(-1, 0)
		target_position = global_position + forward * 400.0
	
	# Calculer la vélocité initiale vers la cible
	calculate_launch_velocity(launch_speed)
	
	# Initialiser Verlet avec la vélocité
	previous_position = current_position - initial_velocity * 0.016  # ~1 frame à 60fps
	
	is_initialized = true
	
	# Créer la ligne de trajectoire prédite
	if show_trajectory:
		call_deferred("create_trajectory_prediction")
	
	# Créer le marqueur
	call_deferred("create_target_marker_line")
	
	print("🎯 %s tire depuis %s vers %s (v: %s)" % [
		"JOUEUR" if team == Team.PLAYER else "ENNEMI",
		current_position,
		target_position,
		initial_velocity
	])

func calculate_launch_velocity(launch_speed: float):
	"""Calcule la vélocité de lancement pour atteindre la cible"""
	var direction = (target_position - current_position).normalized()
	var distance = current_position.distance_to(target_position)
	
	# Angle de lancement optimal (45° pour portée max, ajusté selon distance)
	var launch_angle = -45.0  # Degrés (négatif = vers le haut)
	
	# Ajuster l'angle selon la distance
	if distance < 300.0:
		launch_angle = -60.0  # Arc plus prononcé pour courte distance
	elif distance > 800.0:
		launch_angle = -30.0  # Arc plus plat pour longue distance
	
	# Convertir en radians
	var angle_rad = deg_to_rad(launch_angle)
	
	# Direction horizontale (gauche ou droite)
	var horizontal_dir = 1.0 if target_position.x > current_position.x else -1.0
	
	# Calculer les composantes de vélocité
	initial_velocity.x = cos(angle_rad) * launch_speed * horizontal_dir
	initial_velocity.y = sin(angle_rad) * launch_speed  # Négatif = vers le haut

# ============================================================================
# INTÉGRATION VERLET
# ============================================================================

func verlet_integrate(delta: float):
	"""Intégration de Verlet pour physique stable
	
	Formule Verlet:
	x(t+dt) = 2*x(t) - x(t-dt) + a*dt²
	
	Avantages:
	- Très stable numériquement
	- Conservation de l'énergie
	- Pas besoin de stocker la vélocité explicitement
	"""
	
	# Calculer l'accélération (gravité + autres forces)
	acceleration = gravity_force
	
	# Sauvegarder l'ancienne position
	var temp_position = current_position
	
	# Formule de Verlet
	current_position = 2.0 * current_position - previous_position + acceleration * delta * delta
	
	# Appliquer la résistance de l'air
	var velocity = current_position - previous_position
	velocity *= air_resistance
	current_position = temp_position + velocity
	
	# Mettre à jour la position précédente
	previous_position = temp_position
	
	# Appliquer à la position globale du node
	global_position = current_position
	
	# Rotation du sprite selon la vélocité
	if sprite:
		var vel = current_position - previous_position
		if vel.length() > 0.1:
			sprite.rotation = vel.angle()

# ============================================================================
# PRÉDICTION DE TRAJECTOIRE
# ============================================================================

func create_trajectory_prediction():
	"""Crée une ligne montrant la trajectoire prédite"""
	trajectory_line = Line2D.new()
	trajectory_line.width = 2.0
	trajectory_line.default_color = trajectory_color
	trajectory_line.z_index = 100
	
	# Ajouter à la scène
	var battlefield = get_battlefield()
	if battlefield:
		battlefield.add_child(trajectory_line)
	else:
		add_child(trajectory_line)
	
	# Calculer les points de la trajectoire
	var predicted_points = predict_trajectory(trajectory_points)
	
	for point in predicted_points:
		trajectory_line.add_point(point)
	
	print("  📈 Trajectoire prédite avec %d points" % trajectory_points)
	
	# Faire disparaître la ligne après 1 seconde
	var tween = create_tween()
	tween.tween_property(trajectory_line, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): 
		if is_instance_valid(trajectory_line):
			trajectory_line.queue_free()
	)

func predict_trajectory(num_points: int) -> Array:
	"""Prédit la trajectoire en simulant Verlet en avance
	
	Retourne un array de Vector2 représentant la trajectoire future
	"""
	var points = []
	
	# États temporaires pour la simulation
	var sim_current = current_position
	var sim_previous = previous_position
	var sim_delta = 0.05  # Pas de temps de simulation
	
	for i in range(num_points):
		# Ajouter le point actuel
		points.append(sim_current)
		
		# Simuler un pas Verlet
		var temp = sim_current
		sim_current = 2.0 * sim_current - sim_previous + gravity_force * sim_delta * sim_delta
		
		# Appliquer résistance
		var vel = sim_current - sim_previous
		vel *= air_resistance
		sim_current = temp + vel
		
		sim_previous = temp
		
		# Arrêter si la trajectoire sort de l'écran
		if sim_current.y > get_viewport_rect().size.y + 100:
			break
	
	return points

# ============================================================================
# MARQUEUR DE CIBLE (LIGNE)
# ============================================================================

func create_target_marker_line():
	"""Crée un marqueur ligne à la position cible"""
	target_marker = Area2D.new()
	target_marker.name = "TargetMarkerLine"
	target_marker.global_position = target_position
	
	# Ligne horizontale
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(200.0, 30.0)
	collision.shape = rect
	target_marker.add_child(collision)
	
	# Ajouter à la scène
	var battlefield = get_battlefield()
	if battlefield:
		battlefield.add_child(target_marker)
	
	# Signal
	target_marker.area_entered.connect(_on_marker_reached)
	
	# Debug visuel
	if OS.is_debug_build():
		var debug_rect = ColorRect.new()
		debug_rect.size = Vector2(200.0, 30.0)
		debug_rect.position = Vector2(-100.0, -15.0)
		debug_rect.color = Color(1, 0, 0, 0.3)
		target_marker.add_child(debug_rect)
	
	print("  📍 Marqueur LIGNE créé à: %s" % target_position)

func get_battlefield():
	"""Trouve la scène Battlefield"""
	var tree = get_tree()
	if not tree:
		return null
	
	var root = tree.root
	if not root:
		return null
	
	for child in root.get_children():
		if child.name.to_lower() in ["battlefield", "mainscene", "main"]:
			return child
	
	return root.get_child(0) if root.get_child_count() > 0 else null

# ============================================================================
# DÉTECTION DE COLLISION
# ============================================================================

func check_marker_collision():
	"""Vérifie collision avec le marqueur"""
	if has_impacted:
		return
	
	if not is_instance_valid(target_marker):
		if time_alive > 3.0:
			trigger_impact_without_marker()
		return
	
	var distance = global_position.distance_to(target_marker.global_position)
	
	if distance < 120.0:
		trigger_impact()

func trigger_impact():
	"""Impact au marqueur"""
	if has_impacted:
		return
	
	has_impacted = true
	print("💥 Impact Verlet au marqueur: %s" % target_marker.global_position)
	
	var enemies = find_enemies_at_marker()
	
	if enemies.size() > 0:
		hit_target(enemies[0])
		if splash_radius > 0.0:
			apply_splash_damage(target_marker.global_position)
		spawn_impact_effect(target_marker.global_position)
	else:
		spawn_water_splash(target_marker.global_position)
	
	cleanup()

func trigger_impact_without_marker():
	"""Impact d'urgence"""
	if has_impacted:
		return
	
	has_impacted = true
	var enemies = find_enemies_at_position(global_position)
	
	if enemies.size() > 0:
		hit_target(enemies[0])
		spawn_impact_effect(global_position)
	else:
		spawn_water_splash(global_position)
	
	cleanup()

func find_enemies_at_marker() -> Array:
	"""Trouve les ennemis au marqueur"""
	if not is_instance_valid(target_marker):
		return []
	
	var enemies = []
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var overlapping = target_marker.get_overlapping_areas()
	
	for area in overlapping:
		if area.is_in_group("tile") and area.is_in_group(enemy_group):
			enemies.append(area)
	
	return enemies

func find_enemies_at_position(pos: Vector2) -> Array:
	"""Trouve les ennemis à une position"""
	var enemies = []
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var tiles = get_tree().get_nodes_in_group("tile")
	
	for tile in tiles:
		if tile.is_in_group(enemy_group):
			if pos.distance_to(tile.global_position) < 80.0:
				enemies.append(tile)
	
	return enemies

func _on_marker_reached(area):
	pass

# ============================================================================
# SYSTÈME DE DÉGÂTS
# ============================================================================

func hit_target(target):
	"""Applique les dégâts"""
	has_hit_targets.append(target)
	hit_count += 1
	
	if target.has_method("take_damage"):
		target.take_damage(bullet_damage)
	elif "health" in target:
		target.health -= bullet_damage
	
	apply_special_effects(target)
	print("  💥 Touché: %s (dégâts: %d)" % [target.name, bullet_damage])

func apply_splash_damage(impact_pos: Vector2):
	"""Dégâts en zone"""
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	for enemy in enemies:
		if enemy in has_hit_targets:
			continue
		
		var distance = impact_pos.distance_to(enemy.global_position)
		if distance <= splash_radius:
			var dmg_mult = 1.0 - (distance / splash_radius) * 0.5
			var splash_dmg = int(bullet_damage * dmg_mult)
			
			if enemy.has_method("take_damage"):
				enemy.take_damage(splash_dmg)
			elif "health" in enemy:
				enemy.health -= splash_dmg
			
			has_hit_targets.append(enemy)

func apply_special_effects(target):
	"""Effets spéciaux"""
	if slow_duration > 0.0 and slow_amount > 0.0:
		if target.has_method("apply_slow"):
			target.apply_slow(slow_amount, slow_duration)
	
	if poison_damage > 0 and poison_duration > 0.0:
		if target.has_method("apply_poison"):
			target.apply_poison(poison_damage, poison_duration)

# ============================================================================
# EFFETS VISUELS
# ============================================================================

func spawn_impact_effect(pos: Vector2):
	"""Explosion"""
	if not impact_particles:
		return
	
	var explosion = impact_particles.instantiate()
	var battlefield = get_battlefield()
	
	if battlefield:
		battlefield.add_child(explosion)
		explosion.global_position = pos
		explosion.emitting = true
		
		if team == Team.PLAYER:
			explosion.modulate = Color(1.0, 0.8, 0.3)
		else:
			explosion.modulate = Color(0.8, 0.3, 0.3)

func spawn_water_splash(pos: Vector2):
	"""Geyser d'eau"""
	if not water_splash:
		return
	
	var splash = water_splash.instantiate()
	var battlefield = get_battlefield()
	
	if battlefield:
		battlefield.add_child(splash)
		splash.global_position = pos
		
		if splash is CPUParticles2D:
			splash.emitting = true
			splash.amount = 20
			splash.lifetime = 1.2
			splash.one_shot = true
			splash.explosiveness = 0.9
			splash.direction = Vector2(0, -1)
			splash.spread = 35.0
			splash.initial_velocity_min = 150.0
			splash.initial_velocity_max = 250.0
			splash.gravity = Vector2(0, 400)
			splash.modulate = Color(0.4, 0.7, 1.0, 0.7)

# ============================================================================
# NETTOYAGE
# ============================================================================

func cleanup():
	"""Nettoie tout"""
	if is_instance_valid(target_marker):
		target_marker.queue_free()
	
	if is_instance_valid(trajectory_line):
		trajectory_line.queue_free()
	
	queue_free()

func _on_lifetime_expired():
	"""Expiration"""
	if not has_impacted:
		print("⏱️ Projectile Verlet expiré")
		spawn_water_splash(global_position)
	cleanup()

# ============================================================================
# COMPATIBILITÉ
# ============================================================================

func set_target(target):
	"""Pour compatibilité"""
	if is_instance_valid(target):
		target_position = target.global_position
	setup(team, bullet_damage, target)
	
