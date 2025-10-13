extends CharacterBody2D
class_name BaseProjectile

# ============================================================================
# SYSTÈME DE PROJECTILES AVEC VERLET SIMPLIFIÉ + PRÉDICTION
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
@export var gravity: float = 600.0  # Gravité (pixels/s²)
@export var damping: float = 0.998  # Amortissement
@export var lifetime: float = 5.0

@export_group("Trajectory Prediction")
@export var show_trajectory: bool = true
@export var trajectory_points: int = 40
@export var trajectory_color: Color = Color(1, 1, 0, 0.6)

@export_group("Debug Options")
@export var debug_show_trajectory: bool = true  # ✅ Afficher les lignes de prédiction
@export var debug_show_marker: bool = true      # ✅ Afficher les marqueurs de cible
@export var debug_show_logs: bool = true        # ✅ Afficher les logs console

@export_group("Special Effects")
@export var splash_radius: float = 0.0
@export var slow_duration: float = 0.0
@export var slow_amount: float = 0.0
@export var poison_damage: int = 0
@export var poison_duration: float = 0.0

# Verlet - Positions
var pos: Vector2 = Vector2.ZERO
var old_pos: Vector2 = Vector2.ZERO

# Cible
var target_marker: Area2D = null
var target_position: Vector2 = Vector2.ZERO

# Ligne de trajectoire
var trajectory_line: Line2D = null

# État
var time_alive: float = 0.0
var has_hit_targets = []
var is_initialized: bool = false
var has_impacted: bool = false

# Effets
@onready var sprite = $TowerDefenseTile251 if has_node("TowerDefenseTile251") else null
@onready var impact_particles = preload("res://scenes/effects/explode.tscn")
@onready var water_splash = preload("res://scenes/effects/smoke.tscn")

func _ready():
	# Visibilité
	visible = true
	z_index = 1000
	z_as_relative = false
	
	if sprite:
		sprite.visible = true
		sprite.scale = Vector2(2, 2)
	
	# Timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_expired)
	
	if debug_show_logs:
		print("🔫 Projectile créé à: %s" % global_position)

func _physics_process(delta):
	if not is_initialized:
		return
	
	time_alive += delta
	
	# Intégration Verlet
	verlet_step(delta)
	
	# Appliquer la position
	global_position = pos
	
	# Rotation
	if sprite:
		var vel = pos - old_pos
		if vel.length() > 0.1:
			sprite.rotation = vel.angle()
	
	# Vérifier si sort de l'écran
	if pos.y > get_viewport_rect().size.y:
		if debug_show_logs:
			print("⚠️ Projectile sorti de l'écran")
		spawn_water_splash(pos)
		cleanup()
		return
	
	# Vérifier collision
	check_marker_collision()

# ============================================================================
# SETUP
# ============================================================================

func setup(p_team: Team, p_damage: int, p_target, launch_speed: float = 350.0):
	"""Configure le projectile"""
	team = p_team
	bullet_damage = p_damage
	
	# Position initiale
	pos = global_position
	old_pos = global_position
	
	# Déterminer la cible
	if is_instance_valid(p_target):
		target_position = p_target.global_position
	elif p_target is Vector2:
		target_position = p_target
	else:
		var forward = Vector2(1, 0) if team == Team.PLAYER else Vector2(-1, 0)
		target_position = global_position + forward * 400.0
	
	# Calculer la vélocité initiale
	var initial_velocity = calculate_initial_velocity(launch_speed)
	
	# Initialiser old_pos pour créer la vélocité initiale
	old_pos = pos - initial_velocity / 60.0  # Assumer 60 FPS
	
	is_initialized = true
	
	if debug_show_logs:
		print("🎯 Tir: pos=%s, target=%s, v0=%s" % [pos, target_position, initial_velocity])
	
	# Créer prédiction et marqueur selon les options de debug
	if show_trajectory and debug_show_trajectory:
		call_deferred("create_trajectory_prediction")
	if debug_show_marker:
		call_deferred("create_target_marker_line")

func calculate_initial_velocity(launch_speed: float) -> Vector2:
	"""Calcule la vélocité initiale avec angle variable selon distance"""
	var to_target = target_position - pos
	var distance = to_target.length()
	
	# Angle variable selon l'équipe et la distance
	var angle: float
	var min_angle: float
	var max_angle: float
	
	if team == Team.PLAYER:
		# JOUEUR: -75° (vertical) à -30° (horizontal droite)
		min_angle = -75.0
		max_angle = -30.0
	else:
		# ENNEMI: -105° (vertical) à -150° (horizontal gauche)
		# ✅ INVERSER min et max pour que l'interpolation fonctionne correctement
		min_angle = -105.0  # Vertical (courte distance)
		max_angle = -150.0  # Horizontal gauche (longue distance)
	
	# Interpoler l'angle selon la distance
	# Distance courte → angle vertical (min_angle)
	# Distance longue → angle horizontal (max_angle)
	var t: float
	if distance < 200.0:
		t = 0.0  # Angle minimal (plus vertical)
	elif distance > 800.0:
		t = 1.0  # Angle maximal (plus horizontal)
	else:
		# Interpolation linéaire entre 200 et 800
		t = (distance - 200.0) / (800.0 - 200.0)
	
	angle = lerp(min_angle, max_angle, t)
	
	# ✅ AJUSTER LA VITESSE POUR NE PAS DÉPASSER 300PX DE HAUTEUR
	var angle_rad = deg_to_rad(angle)
	var vy = sin(angle_rad) * launch_speed  # Composante verticale
	
	# Hauteur max = |v_y|² / (2 * g)
	var max_height = abs(vy * vy) / (2.0 * gravity)
	
	# Si la hauteur dépasse 300px, réduire la vitesse
	var height_limit = 300.0
	var speed_multiplier = 1.0
	
	if max_height > height_limit:
		var required_vy = sqrt(2.0 * gravity * height_limit)
		speed_multiplier = required_vy / abs(vy)
	
	# Appliquer le multiplicateur
	var adjusted_speed = launch_speed * speed_multiplier
	
	# Calculer les composantes finales
	var v = Vector2(cos(angle_rad), sin(angle_rad)) * adjusted_speed
	
	if debug_show_logs:
		print("  📐 %s - Distance: %.0f → Angle: %.1f° (plage: %.1f° à %.1f°)" % [
			"JOUEUR" if team == Team.PLAYER else "ENNEMI",
			distance, 
			angle, 
			min_angle, 
			max_angle
		])
		print("  📏 Hauteur max: %.0fpx, vitesse: %.0f → %.0f, direction: (%.1f, %.1f)" % [
			max_height, 
			launch_speed, 
			adjusted_speed,
			v.x,
			v.y
		])
	
	return v

# ============================================================================
# VERLET INTEGRATION
# ============================================================================

func verlet_step(delta: float):
	"""Intégration Verlet simple
	
	Formule:
	velocity = (pos - old_pos) * damping
	acceleration = gravity
	new_pos = pos + velocity + acceleration * dt²
	"""
	
	# Calculer la vélocité actuelle
	var velocity = (pos - old_pos) * damping
	
	# Appliquer la gravité
	var acceleration = Vector2(0, gravity)
	
	# Sauvegarder la position actuelle
	var temp = pos
	
	# Calculer la nouvelle position
	pos = pos + velocity + acceleration * delta * delta
	
	# Mettre à jour l'ancienne position
	old_pos = temp

# ============================================================================
# PRÉDICTION DE TRAJECTOIRE
# ============================================================================

func create_trajectory_prediction():
	"""Crée la ligne de prédiction"""
	if not debug_show_trajectory:
		return
	
	trajectory_line = Line2D.new()
	trajectory_line.width = 3.0
	trajectory_line.default_color = trajectory_color
	trajectory_line.z_index = 999
	
	var battlefield = get_battlefield()
	if battlefield:
		battlefield.add_child(trajectory_line)
	
	# Calculer les points
	var points = simulate_trajectory()
	for point in points:
		trajectory_line.add_point(point)
	
	if debug_show_logs:
		print("  📈 Prédiction: %d points" % points.size())
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(trajectory_line, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func(): 
		if is_instance_valid(trajectory_line):
			trajectory_line.queue_free()
	)

func simulate_trajectory() -> Array:
	"""Simule la trajectoire future"""
	var points = []
	
	# Copier l'état actuel
	var sim_pos = pos
	var sim_old = old_pos
	var sim_delta = 1.0 / 60.0  # 60 FPS
	
	# Simuler N frames
	for i in range(trajectory_points * 2):  # Plus de frames pour trajectoire complète
		if i % 2 == 0:  # Ajouter 1 point tous les 2 frames
			points.append(sim_pos)
		
		# Même calcul que verlet_step
		var velocity = (sim_pos - sim_old) * damping
		var acceleration = Vector2(0, gravity)
		var temp = sim_pos
		sim_pos = sim_pos + velocity + acceleration * sim_delta * sim_delta
		sim_old = temp
		
		# Arrêter si sort de l'écran
		if sim_pos.y > get_viewport_rect().size.y + 100:
			break
	
	return points

# ============================================================================
# MARQUEUR DE CIBLE
# ============================================================================

func create_target_marker_line():
	"""Crée le marqueur ligne"""
	if not debug_show_marker:
		return
	
	target_marker = Area2D.new()
	target_marker.name = "TargetMarker"
	target_marker.global_position = target_position
	
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(200.0, 30.0)
	collision.shape = rect
	target_marker.add_child(collision)
	
	var battlefield = get_battlefield()
	if battlefield:
		battlefield.add_child(target_marker)
	
	target_marker.area_entered.connect(_on_marker_reached)
	
	# Visuel du marqueur (toujours affiché si debug_show_marker activé)
	var debug_rect = ColorRect.new()
	debug_rect.size = Vector2(200.0, 30.0)
	debug_rect.position = Vector2(-100.0, -15.0)
	debug_rect.color = Color(1, 0, 0, 0.0)
	target_marker.add_child(debug_rect)

func get_battlefield():
	"""Trouve Battlefield"""
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
# COLLISION & DÉGÂTS
# ============================================================================

func check_marker_collision():
	"""Vérifie collision avec marqueur"""
	if has_impacted:
		return
	
	if not is_instance_valid(target_marker):
		if time_alive > 3.0:
			trigger_impact_at(pos)
		return
	
	if pos.distance_to(target_marker.global_position) < 120.0:
		trigger_impact_at(target_marker.global_position)

func trigger_impact_at(impact_pos: Vector2):
	"""Déclenche l'impact"""
	if has_impacted:
		return
	
	has_impacted = true
	
	if debug_show_logs:
		print("💥 Impact à: %s" % impact_pos)
	
	var enemies = find_enemies_at(impact_pos)
	
	if enemies.size() > 0:
		hit_target(enemies[0])
		if splash_radius > 0.0:
			apply_splash_damage(impact_pos)
		spawn_impact_effect(impact_pos)
	else:
		spawn_water_splash(impact_pos)
	
	cleanup()

func find_enemies_at(impact_pos: Vector2) -> Array:
	"""Trouve les ennemis à une position"""
	var enemies = []
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var tiles = get_tree().get_nodes_in_group("tile")
	
	for tile in tiles:
		if tile.is_in_group(enemy_group):
			if impact_pos.distance_to(tile.global_position) < 80.0:
				enemies.append(tile)
	
	return enemies

func hit_target(target):
	"""Applique les dégâts"""
	has_hit_targets.append(target)
	
	if target.has_method("take_damage"):
		target.take_damage(bullet_damage)
	elif "health" in target:
		target.health -= bullet_damage
	
	apply_special_effects(target)
	
	if debug_show_logs:
		print("  💥 Touché: %s (dégâts: %d)" % [target.name, bullet_damage])

func apply_splash_damage(impact_pos: Vector2):
	"""Dégâts AOE"""
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

func spawn_impact_effect(impact_pos: Vector2):
	"""Explosion"""
	if not impact_particles:
		return
	
	var explosion = impact_particles.instantiate()
	var battlefield = get_battlefield()
	
	if battlefield:
		battlefield.add_child(explosion)
		explosion.global_position = impact_pos
		explosion.emitting = true
		
		if team == Team.PLAYER:
			explosion.modulate = Color(1.0, 0.8, 0.3)
		else:
			explosion.modulate = Color(0.8, 0.3, 0.3)

func spawn_water_splash(splash_pos: Vector2):
	"""Geyser"""
	if not water_splash:
		return
	
	var splash = water_splash.instantiate()
	var battlefield = get_battlefield()
	
	if battlefield:
		battlefield.add_child(splash)
		splash.global_position = splash_pos
		
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
		if debug_show_logs:
			print("⏱️ Projectile expiré")
		spawn_water_splash(pos)
	cleanup()

func _on_marker_reached(area):
	pass

# ============================================================================
# COMPATIBILITÉ
# ============================================================================

func set_target(target):
	"""Pour compatibilité"""
	if is_instance_valid(target):
		target_position = target.global_position
	setup(team, bullet_damage, target)
