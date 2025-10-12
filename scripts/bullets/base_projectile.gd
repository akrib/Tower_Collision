extends CharacterBody2D
class_name BaseProjectile

# Énumération pour les équipes
enum Team { NONE, PLAYER, ENEMY }

# Énumération pour les types de projectile
enum ProjectileType { DIRECT, HOMING, BALLISTIC, BEAM }

# Configuration de base
@export_group("Base Stats")
@export var team: Team = Team.NONE
@export var projectile_type: ProjectileType = ProjectileType.HOMING
@export var bullet_damage: int = 1
@export var speed: int = 2000
@export var lifetime: float = 5.0  # Durée de vie max en secondes
@export var piercing: int = 0  # Nombre d'ennemis traversés (0 = détruit au premier impact)

@export_group("Special Effects")
@export var splash_radius: float = 0.0
@export var slow_duration: float = 0.0
@export var slow_amount: float = 0.0
@export var poison_damage: int = 0
@export var poison_duration: float = 0.0

# État interne
var target = null
var hit_count: int = 0
var time_alive: float = 0.0
var has_hit_targets = []  # Pour éviter de toucher 2 fois la même cible

# Particules d'impact
@onready var impact_particles = preload("res://scenes/effects/explode.tscn")

func _ready():
	# Démarrer un timer de sécurité pour détruire le projectile après lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_expired)

func _physics_process(delta):
	time_alive += delta
	
	match projectile_type:
		ProjectileType.HOMING:
			move_homing(delta)
		ProjectileType.DIRECT:
			move_direct(delta)
		ProjectileType.BALLISTIC:
			move_ballistic(delta)
		ProjectileType.BEAM:
			move_beam(delta)

# ============================================================================
# TYPES DE MOUVEMENT
# ============================================================================

func move_homing(_delta):
	"""Mouvement guidé vers la cible"""
	if is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position) * speed
		look_at(target.global_position)
		move_and_slide()
	else:
		# Si la cible n'existe plus, continuer en ligne droite
		move_and_slide()

func move_direct(_delta):
	"""Mouvement en ligne droite"""
	move_and_slide()

func move_ballistic(delta):
	"""Mouvement balistique (avec gravité)"""
	velocity.y += 980 * delta  # Gravité
	move_and_slide()

func move_beam(_delta):
	"""Rayon laser (instantané, géré différemment)"""
	# Ce type nécessite une implémentation spéciale
	pass

# ============================================================================
# CONFIGURATION
# ============================================================================

func setup(p_team: Team, p_damage: int, p_target, p_speed: int = 2000):
	"""Configure le projectile depuis la tour"""
	team = p_team
	bullet_damage = p_damage
	target = p_target
	speed = p_speed
	
	# Initialiser la vélocité pour les projectiles directs
	if projectile_type == ProjectileType.DIRECT and is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position) * speed
		look_at(target.global_position)

func set_target(obj):
	"""Définit la cible (pour compatibilité avec l'ancien système)"""
	target = obj

# ============================================================================
# SYSTÈME DE COLLISION
# ============================================================================

func _on_area_2d_area_entered(area):
	"""Collision avec une area (tuiles)"""
	var tiles = get_tree().get_nodes_in_group("tile")
	
	# Vérifier si c'est une tuile
	if area not in tiles:
		return
	
	# Éviter de toucher la même cible plusieurs fois
	if area in has_hit_targets:
		return
	
	# Déterminer si c'est une tuile ennemie
	if is_enemy_tile(area):
		hit_target(area)

func _on_area_2d_body_entered(body):
	"""Collision avec un body (tours)"""
	if "tower" in body.name.to_lower():
		# Éviter de toucher la même cible plusieurs fois
		if body in has_hit_targets:
			return
		
		# Vérifier si c'est une tour ennemie
		if is_enemy_tower(body):
			hit_target(body)

func hit_target(target_hit):
	"""Gère l'impact sur une cible"""
	# Marquer la cible comme touchée
	has_hit_targets.append(target_hit)
	hit_count += 1
	
	# Appliquer les dégâts
	apply_damage(target_hit)
	
	# Effets de zone
	if splash_radius > 0.0:
		apply_splash_damage(target_hit.global_position)
	
	# Effets spéciaux
	apply_special_effects(target_hit)
	
	# Effet visuel d'impact
	spawn_impact_effect(target_hit.global_position)
	
	# Détruire le projectile ou continuer (piercing)
	if piercing <= 0 or hit_count > piercing:
		queue_free()

func apply_damage(target_hit):
	"""Applique les dégâts à la cible"""
	if target_hit.has_method("take_damage"):
		target_hit.take_damage(bullet_damage)
	#elif target_hit.has_variable("health"):
	elif "health" in target_hit:
		target_hit.health -= bullet_damage

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
			elif enemy.has("health"):
				enemy.health -= splash_damage
			
			has_hit_targets.append(enemy)

func apply_special_effects(target_hit):
	"""Applique les effets spéciaux (ralentissement, poison, etc.)"""
	# Ralentissement
	if slow_duration > 0.0 and slow_amount > 0.0:
		if target_hit.has_method("apply_slow"):
			target_hit.apply_slow(slow_amount, slow_duration)
	
	# Poison
	if poison_damage > 0 and poison_duration > 0.0:
		if target_hit.has_method("apply_poison"):
			target_hit.apply_poison(poison_damage, poison_duration)

# ============================================================================
# DÉTECTION D'ENNEMI
# ============================================================================

func is_enemy_tower(tower) -> bool:
	"""Vérifie si une tour est ennemie"""
	if team == Team.NONE:
		return false
	
	if not "team" in tower:
		return false
	
	# Player blesse Enemy, Enemy blesse Player
	if team == Team.PLAYER and tower.team == BaseTower.Team.ENEMY:
		return true
	if team == Team.ENEMY and tower.team == BaseTower.Team.PLAYER:
		return true
	
	return false

func is_enemy_tile(tile) -> bool:
	"""Vérifie si une tuile est ennemie"""
	if team == Team.NONE:
		return false
	
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var enemy_tiles = get_tree().get_nodes_in_group(enemy_group)
	return tile in enemy_tiles

# ============================================================================
# EFFETS VISUELS
# ============================================================================

func spawn_impact_effect(pos: Vector2):
	"""Crée un effet d'impact"""
	if impact_particles:
		var explosion = impact_particles.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = pos
		explosion.emitting = true

func _on_lifetime_expired():
	"""Détruit le projectile après sa durée de vie"""
	queue_free()
