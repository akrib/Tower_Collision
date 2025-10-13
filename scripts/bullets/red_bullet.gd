extends CharacterBody2D
class_name BaseProjectile

# ============================================================================
# SYSTÈME DE PROJECTILES AVEC MARQUEUR DE CIBLE INVISIBLE
# Le projectile vise un marqueur invisible créé à la position de la cible
# À l'arrivée, détecte les tuiles ennemies et explose
# ============================================================================

# Énumération pour les équipes
enum Team { NONE, PLAYER, ENEMY }
enum ProjectileType { DIRECT, HOMING, BALLISTIC, BEAM }

# Configuration
@export_group("Base Stats")
@export var team: Team = Team.NONE
@export var projectile_type: ProjectileType = ProjectileType.BALLISTIC
@export var bullet_damage: int = 1
@export var speed: int = 2000
@export var piercing: int = 0

@export_group("Ballistic Physics")
@export var initial_speed: float = 800.0
@export var arc_height: float = 200.0
@export var gravity: float = 1500.0
@export var lifetime: float = 5.0

@export_group("Special Effects")
@export var splash_radius: float = 0.0
@export var slow_duration: float = 0.0
@export var slow_amount: float = 0.0
@export var poison_damage: int = 0
@export var poison_duration: float = 0.0

# Marqueur de cible invisible
var target_marker: Area2D = null
var target_position: Vector2 = Vector2.ZERO

# Variables de trajectoire
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
var has_impacted: bool = false

# Effets
@onready var sprite = $TowerDefenseTile251 if has_node("TowerDefenseTile251") else null
@onready var impact_particles = preload("res://scenes/effects/explode.tscn")
@onready var water_splash = preload("res://scenes/effects/smoke.tscn")

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
	
	# Vérifier si on a atteint le marqueur
	check_marker_collision()

# ============================================================================
# CONFIGURATION & CRÉATION DU MARQUEUR
# ============================================================================

func setup(p_team: Team, p_damage: int, p_target, p_speed: float = 800.0):
	"""Configure le projectile et crée le marqueur de cible"""
	team = p_team
	bullet_damage = p_damage
	initial_speed = p_speed
	start_position = global_position
	
	# Déterminer la position cible
	if is_instance_valid(p_target):
		target_position = p_target.global_position
	elif p_target is Vector2:
		target_position = p_target
	else:
		var forward = Vector2(1, 0) if team == Team.PLAYER else Vector2(-1, 0)
		target_position = global_position + forward * 400.0
	
	# Calculer la trajectoire
	calculate_ballistic_trajectory()
	
	is_initialized = true
	
	# IMPORTANT: Créer le marqueur après un frame pour être sûr que le projectile est dans l'arbre
	call_deferred("create_target_marker")
	
	var dir = "→" if (target_position.x > start_position.x) else "←"
	print("🎯 %s tire %s vers %s (dist: %.0f)" % [
		"JOUEUR" if team == Team.PLAYER else "ENNEMI",
		dir,
		target_position,
		start_position.distance_to(target_position)
	])

func create_target_marker():
	"""Crée un marqueur invisible à la position cible"""
	target_marker = Area2D.new()
	target_marker.name = "TargetMarker"
	target_marker.global_position = target_position
	
	# Collision shape circulaire
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 60.0  # Rayon de détection
	collision.shape = circle
	target_marker.add_child(collision)
	
	# Ajouter à la scène de manière sécurisée
	var tree = get_tree()
	if not tree:
		push_error("❌ get_tree() retourne null!")
		target_marker.queue_free()
		return
	
	var scene_root = tree.root
	if not scene_root:
		push_error("❌ tree.root retourne null!")
		target_marker.queue_free()
		return
	
	# Chercher la scène principale (battlefield ou autre)
	var main_scene = null
	for child in scene_root.get_children():
		if child.name in ["Battlefield", "battlefield", "MainScene", "main"]:
			main_scene = child
			break
	
	# Si pas trouvé, utiliser le premier enfant qui n'est pas un popup
	if not main_scene:
		for child in scene_root.get_children():
			if not child is Window:
				main_scene = child
				break
	
	# Ajouter le marqueur
	if main_scene:
		main_scene.add_child(target_marker)
	else:
		# Fallback: ajouter directement à root
		scene_root.add_child(target_marker)
	
	# Connecter le signal de collision
	target_marker.area_entered.connect(_on_marker_reached)
	
	# DEBUG: Rendre visible en mode debug
	if OS.is_debug_build():
		var debug_circle = Polygon2D.new()
		var points = []
		for i in range(32):
			var angle = i * PI * 2.0 / 32
			points.append(Vector2(cos(angle), sin(angle)) * 60.0)
		debug_circle.polygon = PackedVector2Array(points)
		debug_circle.color = Color(1, 0, 0, 0.3)
		target_marker.add_child(debug_circle)
	
	print("  📍 Marqueur créé à: %s (parent: %s)" % [target_position, target_marker.get_parent().name if target_marker.get_parent() else "NONE"])

func calculate_ballistic_trajectory():
	"""Calcule la trajectoire vers le marqueur"""
	var distance_vector = target_position - start_position
	var horizontal_distance = distance_vector.length()
	
	if horizontal_distance < 1.0:
		var forward = Vector2(1, 0) if team == Team.PLAYER else Vector2(-1, 0)
		target_position = start_position + forward * 50.0
		distance_vector = target_position - start_position
		horizontal_distance = distance_vector.length()
	
	var direction = distance_vector.normalized()
	
	# Arc adaptatif selon distance
	var adaptive_arc = arc_height
	if horizontal_distance < 200.0:
		adaptive_arc = arc_height * 0.2 * (horizontal_distance / 200.0)
	elif horizontal_distance < 400.0:
		adaptive_arc = arc_height * 0.5
	
	# Temps de vol adaptatif
	if horizontal_distance < 100.0:
		max_travel_time = 0.2
	elif horizontal_distance < 300.0:
		max_travel_time = 0.4 + (horizontal_distance - 100.0) / 500.0
	else:
		max_travel_time = sqrt(horizontal_distance / 200.0)
		max_travel_time = clamp(max_travel_time, 0.5, 2.0)
	
	# Vélocité horizontale
	velocity_2d = direction * (horizontal_distance / max_travel_time)
	
	# Vélocité verticale pour l'arc
	var half_time = max_travel_time / 2.0
	vertical_velocity = -(adaptive_arc + 0.5 * gravity * half_time * half_time) / half_time
	
	print("  📐 Arc: %.0f, Temps: %.2fs, Vélocité: %s" % [adaptive_arc, max_travel_time, velocity_2d])

# ============================================================================
# MOUVEMENT
# ============================================================================

func move_ballistic(delta):
	"""Mouvement en parabole"""
	# Horizontal
	velocity = velocity_2d
	
	# Vertical avec gravité
	vertical_velocity += gravity * delta
	position.y += vertical_velocity * delta
	
	# Rotation du sprite
	if sprite:
		sprite.rotation = atan2(vertical_velocity, velocity_2d.x)
	
	# Déplacement
	move_and_slide()

# ============================================================================
# DÉTECTION DU MARQUEUR
# ============================================================================

func check_marker_collision():
	"""Vérifie si le projectile a atteint le marqueur"""
	if has_impacted:
		return
	
	# Si le marqueur n'existe pas encore (création différée), attendre
	if not is_instance_valid(target_marker):
		# Si trop de temps s'est écoulé sans marqueur, forcer l'impact
		if travel_time >= max_travel_time * 1.5:
			print("⚠️ Marqueur manquant, impact forcé")
			trigger_impact_without_marker()
		return
	
	var distance = global_position.distance_to(target_marker.global_position)
	
	# Si on est proche du marqueur
	if distance < 70.0:
		trigger_impact()
	
	# Sécurité: temps écoulé
	if travel_time >= max_travel_time * 1.2:
		trigger_impact()

func trigger_impact_without_marker():
	"""Impact d'urgence sans marqueur (fallback)"""
	if has_impacted:
		return
	
	has_impacted = true
	print("💥 Impact d'urgence à: %s" % target_position)
	
	# Chercher directement les ennemis à la position cible
	var enemies = find_enemies_at_position(target_position)
	
	if enemies.size() > 0:
		hit_target(enemies[0])
		if splash_radius > 0.0:
			apply_splash_damage(target_position)
		spawn_impact_effect(target_position)
	else:
		spawn_water_splash(target_position)
	
	cleanup()

func find_enemies_at_position(pos: Vector2) -> Array:
	"""Trouve les ennemis à une position donnée (sans marqueur)"""
	var enemies = []
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var detection_radius = 60.0
	
	var tiles = get_tree().get_nodes_in_group("tile")
	for tile in tiles:
		if tile.is_in_group(enemy_group):
			var distance = pos.distance_to(tile.global_position)
			if distance < detection_radius:
				enemies.append(tile)
	
	# Trier par distance
	if enemies.size() > 1:
		enemies.sort_custom(func(a, b): 
			return pos.distance_to(a.global_position) < pos.distance_to(b.global_position)
		)
	
	return enemies

func _on_marker_reached(area):
	"""Callback quand le projectile entre dans le marqueur"""
	# Ce signal est connecté mais on utilise check_marker_collision pour plus de contrôle
	pass

# ============================================================================
# SYSTÈME D'IMPACT
# ============================================================================

func trigger_impact():
	"""Déclenche l'impact au niveau du marqueur"""
	if has_impacted:
		return
	
	has_impacted = true
	
	print("💥 Impact au marqueur: %s" % target_marker.global_position)
	
	# Chercher les tuiles ennemies au niveau du marqueur
	var enemies_at_marker = find_enemies_at_marker()
	
	if enemies_at_marker.size() > 0:
		# Toucher la PREMIÈRE tuile ennemie trouvée
		var first_enemy = enemies_at_marker[0]
		hit_target(first_enemy)
		
		# Effet d'explosion
		if splash_radius > 0.0:
			apply_splash_damage(target_marker.global_position)
		
		spawn_impact_effect(target_marker.global_position)
	else:
		# Pas de tuile = geyser d'eau
		spawn_water_splash(target_marker.global_position)
	
	# Nettoyer
	cleanup()

func find_enemies_at_marker() -> Array:
	"""Trouve les tuiles ennemies dans le marqueur"""
	if not is_instance_valid(target_marker):
		return []
	
	var enemies = []
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	
	# Récupérer toutes les areas qui se chevauchent avec le marqueur
	var overlapping = target_marker.get_overlapping_areas()
	
	for area in overlapping:
		if area.is_in_group("tile") and area.is_in_group(enemy_group):
			enemies.append(area)
	
	# Trier par distance pour prendre la plus proche
	if enemies.size() > 1:
		enemies.sort_custom(func(a, b): 
			return target_marker.global_position.distance_to(a.global_position) < target_marker.global_position.distance_to(b.global_position)
		)
	
	if enemies.size() > 0:
		print("  ✓ %d tuile(s) trouvée(s), cible: %s" % [enemies.size(), enemies[0].name])
	
	return enemies

func hit_target(target):
	"""Applique les dégâts à la cible"""
	has_hit_targets.append(target)
	hit_count += 1
	
	if target.has_method("take_damage"):
		target.take_damage(bullet_damage)
	elif "health" in target:
		target.health -= bullet_damage
	
	# Effets spéciaux
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
	
	# Ajouter à la scène de manière sécurisée avec vérifications
	var tree = get_tree()
	if not tree:
		explosion.queue_free()
		return
	
	var parent = get_parent()
	if parent:
		parent.add_child(explosion)
	else:
		var root = tree.root
		if root and root.get_child_count() > 0:
			root.get_child(0).add_child(explosion)
		else:
			explosion.queue_free()
			return
	
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
	
	# Ajouter à la scène de manière sécurisée avec vérifications
	var tree = get_tree()
	if not tree:
		splash.queue_free()
		return
	
	var parent = get_parent()
	if parent:
		parent.add_child(splash)
	else:
		var root = tree.root
		if root and root.get_child_count() > 0:
			root.get_child(0).add_child(splash)
		else:
			splash.queue_free()
			return
	
	splash.global_position = pos
	
	if splash is CPUParticles2D:
		splash.emitting = true
		splash.amount = 20
		splash.lifetime = 1.2
		splash.one_shot = true
		splash.explosiveness = 0.9
		
		# Jet vers le haut
		splash.direction = Vector2(0, -1)
		splash.spread = 35.0
		splash.initial_velocity_min = 150.0
		splash.initial_velocity_max = 250.0
		splash.gravity = Vector2(0, 400)
		
		# Couleur bleue
		splash.modulate = Color(0.4, 0.7, 1.0, 0.7)
		splash.scale_amount_min = 3.0
		splash.scale_amount_max = 6.0
	
	print("  💧 Geyser d'eau à: %s" % pos)

# ============================================================================
# NETTOYAGE
# ============================================================================

func cleanup():
	"""Nettoie le marqueur et détruit le projectile"""
	if is_instance_valid(target_marker):
		target_marker.queue_free()
	
	call_deferred("queue_free")

func _on_lifetime_expired():
	"""Expiration du temps de vie"""
	if not has_impacted:
		print("⏱️ Projectile expiré, geyser forcé")
		spawn_water_splash(global_position)
		cleanup()

# ============================================================================
# COMPATIBILITÉ
# ============================================================================

func set_target(target):
	"""Pour compatibilité avec l'ancien système"""
	if is_instance_valid(target):
		target_position = target.global_position
	create_target_marker()
	calculate_ballistic_trajectory()
	is_initialized = true
