extends StaticBody2D
class_name BaseTower

# Énumération pour les équipes
enum Team { NONE, PLAYER, ENEMY }

# Énumération pour les types d'attaque
enum AttackType { RANGED, MELEE, SUPPORT, AOE }

# Énumération pour les types de ciblage
enum TargetType { CLOSEST, FARTHEST, STRONGEST, WEAKEST, FIRST, LAST }

# Configuration de base (à définir dans les enfants)
@export_group("Base Stats")
@export var team: Team = Team.PLAYER
@export var attack_type: AttackType = AttackType.RANGED
@export var target_type: TargetType = TargetType.CLOSEST

@export_group("Combat Stats")
@export var base_damage: int = 5
@export var base_fire_rate: float = 3.0
@export var base_range: int = 400
@export var base_health: int = 10
@export var projectile_speed: int = 2000

@export_group("Special Stats")
@export var splash_radius: float = 0.0  # Pour les attaques AOE
@export var heal_amount: int = 0  # Pour les tours de soin
@export var slow_amount: float = 0.0  # Pour ralentir les ennemis
@export var poison_damage: int = 0  # Dégâts sur la durée

# Stats calculées (avec bonus)
var actual_damage: int
var actual_fire_rate: float
var actual_range: int
var actual_health: int

# État interne
var current_health: int
var current_target = null
var targets_in_range = []
var is_attacking: bool = false

# Nœuds
@onready var timer: Timer
@onready var tower_area: Area2D
@onready var attack_origin: Marker2D
@onready var projectile_container: Node

# Scène de projectile (à définir dans les enfants pour ranged)
var projectile_scene: PackedScene

func _ready():
	# Appliquer les bonus de compétences du joueur
	apply_skill_bonuses()
	
	# Initialiser la santé
	current_health = actual_health
	
	# Configurer les nœuds si ils existent
	setup_nodes()
	
	# Configurer la portée
	if tower_area and tower_area.has_node("CollisionShape2D2"):
		var collision = tower_area.get_node("CollisionShape2D2")
		if collision.shape is CircleShape2D:
			collision.shape.radius = actual_range

func apply_skill_bonuses():
	"""Applique les bonus de compétences du joueur"""
	if team == Team.PLAYER:
		actual_damage = int(base_damage * PlayerData.get_damage_bonus())
		actual_fire_rate = base_fire_rate / PlayerData.get_attack_speed_bonus()
		actual_health = base_health + PlayerData.get_health_bonus()
		actual_range = base_range
	else:
		# Les ennemis n'ont pas de bonus
		actual_damage = base_damage
		actual_fire_rate = base_fire_rate
		actual_health = base_health
		actual_range = base_range

func setup_nodes():
	"""Configure les références aux nœuds enfants"""
	# Timer d'attaque
	if has_node("Upgrade/ProgressBar/Timer"):
		timer = $"Upgrade/ProgressBar/Timer"
		timer.wait_time = actual_fire_rate
		timer.timeout.connect(_on_timer_timeout)
	
	# Zone de détection
	if has_node("Tower"):
		tower_area = $Tower
		tower_area.area_entered.connect(_on_tower_area_entered)
		tower_area.area_exited.connect(_on_tower_area_exited)
	
	# Origine du tir
	if has_node("Aim"):
		attack_origin = $Aim
	
	# Conteneur de projectiles
	if has_node("BulletContainer"):
		projectile_container = $BulletContainer

func _process(_delta):
	if is_instance_valid(current_target):
		# Regarder vers la cible
		if attack_type != AttackType.SUPPORT:  # Les tours de soin ne visent pas
			look_at(current_target.global_position)
	else:
		# Chercher une nouvelle cible
		find_new_target()

# ============================================================================
# SYSTÈME DE CIBLAGE
# ============================================================================

func find_new_target():
	"""Trouve une nouvelle cible selon le type de ciblage"""
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var tiles = get_tree().get_nodes_in_group("tile")
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	# Récupérer les cibles dans la portée
	if tower_area:
		targets_in_range = tower_area.get_overlapping_areas()
	
	# Filtrer pour ne garder que les tuiles ennemies
	var valid_targets = []
	for target in targets_in_range:
		if target in tiles and target in enemies:
			valid_targets.append(target)
	
	# Trouver la meilleure cible selon le type de ciblage
	if valid_targets.size() > 0:
		current_target = select_target(valid_targets)
		start_attacking()
	else:
		current_target = null
		stop_attacking()

func select_target(targets: Array):
	"""Sélectionne la cible selon le type de ciblage"""
	match target_type:
		TargetType.CLOSEST:
			return get_closest_target(targets)
		TargetType.FARTHEST:
			return get_farthest_target(targets)
		TargetType.STRONGEST:
			return get_strongest_target(targets)
		TargetType.WEAKEST:
			return get_weakest_target(targets)
		TargetType.FIRST:
			return targets[0] if targets.size() > 0 else null
		TargetType.LAST:
			return targets[-1] if targets.size() > 0 else null
	return get_closest_target(targets)

func get_closest_target(targets: Array):
	var closest = null
	var min_distance = INF
	for target in targets:
		var distance = global_position.distance_to(target.global_position)
		if distance < min_distance:
			min_distance = distance
			closest = target
	return closest

func get_farthest_target(targets: Array):
	var farthest = null
	var max_distance = 0
	for target in targets:
		var distance = global_position.distance_to(target.global_position)
		if distance > max_distance:
			max_distance = distance
			farthest = target
	return farthest

func get_strongest_target(targets: Array):
	var strongest = null
	var max_health = 0
	for target in targets:
		if target.has_method("get_health"):
			var health = target.get_health()
			if health > max_health:
				max_health = health
				strongest = target
	return strongest if strongest else get_closest_target(targets)

func get_weakest_target(targets: Array):
	var weakest = null
	var min_health = INF
	for target in targets:
		if target.has_method("get_health"):
			var health = target.get_health()
			if health < min_health:
				min_health = health
				weakest = target
	return weakest if weakest else get_closest_target(targets)

# ============================================================================
# SYSTÈME D'ATTAQUE
# ============================================================================

func start_attacking():
	"""Commence à attaquer"""
	if not is_attacking and timer:
		is_attacking = true
		attack()  # Première attaque immédiate
		timer.start()

func stop_attacking():
	"""Arrête d'attaquer"""
	is_attacking = false
	if timer:
		timer.stop()

func attack():
	"""Attaque principale (à surcharger dans les enfants si nécessaire)"""
	if not is_instance_valid(current_target):
		return
	
	match attack_type:
		AttackType.RANGED:
			attack_ranged()
		AttackType.MELEE:
			attack_melee()
		AttackType.SUPPORT:
			attack_support()
		AttackType.AOE:
			attack_aoe()

func attack_ranged():
	"""Attaque à distance avec projectile - Version call_deferred pour éviter erreurs"""
	if not projectile_scene:
		print("❌ PAS DE projectile_scene définie dans %s" % name)
		return
	
	if not is_instance_valid(current_target):
		print("❌ PAS DE current_target valide dans %s" % name)
		return
	
	print("🎯 %s attaque %s" % [name, current_target.name])
	
	# ✅ CRÉER LE PROJECTILE EN DIFFÉRÉ pour éviter l'erreur de flushing
	call_deferred("_create_projectile_deferred")

func _create_projectile_deferred():
	"""Crée le projectile de manière différée (évite les erreurs de collision)"""
	if not is_instance_valid(current_target):
		print("⚠️ Cible disparue avant création du projectile")
		return
	
	print("🔧 Instanciation du projectile...")
	var projectile = projectile_scene.instantiate()
	
	if not projectile:
		print("❌ Échec instantiation du projectile!")
		return
	
	print("✅ Projectile instancié: %s" % projectile)
	
	# Trouver le parent (battlefield ou scène principale)
	var battlefield = get_battlefield()
	if not battlefield:
		print("❌ Battlefield introuvable!")
		projectile.queue_free()
		return
	
	print("✅ Battlefield trouvé: %s" % battlefield.name)
	
	# Ajouter le projectile à la scène
	battlefield.add_child(projectile)
	print("✅ Projectile ajouté à la scène")
	
	# Positionner le projectile à l'origine d'attaque
	if attack_origin:
		projectile.global_position = attack_origin.global_position
		print("✅ Projectile positionné à attack_origin: %s" % projectile.global_position)
	else:
		projectile.global_position = global_position
		print("✅ Projectile positionné à global_position: %s" % projectile.global_position)
	
	# Configurer le projectile
	if projectile.has_method("setup"):
		print("🔧 Appel de projectile.setup()")
		projectile.setup(team, actual_damage, current_target, projectile_speed)
		print("✅ Setup terminé")
	else:
		print("⚠️ Projectile n'a pas de méthode setup(), configuration basique")
		# Configuration basique
		projectile.team = team
		projectile.bullet_damage = actual_damage
		projectile.set_target(current_target)
		if projectile.has("speed"):
			projectile.speed = projectile_speed

func get_battlefield():
	"""Trouve la scène battlefield"""
	var tree = get_tree()
	if not tree:
		return null
	
	var root = tree.root
	if not root:
		return null
	
	# Chercher Battlefield
	for child in root.get_children():
		if child.name.to_lower() in ["battlefield", "mainscene", "main"]:
			return child
	
	# Fallback: retourner la première scène valide
	return root.get_child(0) if root.get_child_count() > 0 else null

func attack_melee():
	"""Attaque au corps à corps (dégâts directs)"""
	if not is_instance_valid(current_target):
		return
	
	# Vérifier la distance
	var distance = global_position.distance_to(current_target.global_position)
	if distance <= actual_range:
		apply_damage_to_target(current_target, actual_damage)

func attack_support():
	"""Attaque de support (soin)"""
	if heal_amount <= 0:
		return
	
	# Trouver des alliés à soigner
	var ally_group = "player" if team == Team.PLAYER else "enemy"
	var allies = get_tree().get_nodes_in_group(ally_group)
	
	var allies_in_range = []
	for ally in allies:
		if ally != self and global_position.distance_to(ally.global_position) <= actual_range:
			if ally.has_method("get_health") and ally.has_method("heal"):
				allies_in_range.append(ally)
	
	# Soigner l'allié le plus blessé
	if allies_in_range.size() > 0:
		var most_wounded = null
		var lowest_health_percent = 1.0
		
		for ally in allies_in_range:
			var health_percent = float(ally.get_health()) / float(ally.get_max_health())
			if health_percent < lowest_health_percent:
				lowest_health_percent = health_percent
				most_wounded = ally
		
		if most_wounded:
			most_wounded.heal(heal_amount)
			spawn_heal_effect(most_wounded.global_position)

func attack_aoe():
	"""Attaque en zone"""
	if not is_instance_valid(current_target):
		return
	
	var target_pos = current_target.global_position
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	# Toucher tous les ennemis dans le rayon
	for enemy in enemies:
		var distance = target_pos.distance_to(enemy.global_position)
		if distance <= splash_radius:
			apply_damage_to_target(enemy, actual_damage)
	
	spawn_explosion_effect(target_pos, splash_radius)

func apply_damage_to_target(target, damage: int):
	"""Applique des dégâts à une cible"""
	if target.has_method("take_damage"):
		target.take_damage(damage)
	elif target.has("health"):
		target.health -= damage

# ============================================================================
# SYSTÈME DE SANTÉ
# ============================================================================

func take_damage(amount: int):
	"""Reçoit des dégâts"""
	current_health -= amount
	
	# Effet visuel de dégâts
	show_damage_feedback()
	
	if current_health <= 0:
		die()

func heal(amount: int):
	"""Se soigne"""
	current_health = min(current_health + amount, actual_health)
	show_heal_feedback()

func get_health() -> int:
	return current_health

func get_max_health() -> int:
	return actual_health

func die():
	"""Mort de la tour"""
	spawn_death_effect()
	queue_free()

# ============================================================================
# EFFETS VISUELS
# ============================================================================

func show_damage_feedback():
	"""Feedback visuel de dégâts"""
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)

func show_heal_feedback():
	"""Feedback visuel de soin"""
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.3, 1, 0.3), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)

func spawn_explosion_effect(pos: Vector2, radius: float):
	"""Effet d'explosion AOE"""
	# À implémenter avec des particules
	pass

func spawn_heal_effect(pos: Vector2):
	"""Effet de soin"""
	# À implémenter avec des particules vertes
	pass

func spawn_death_effect():
	"""Effet de mort"""
	# À implémenter avec des particules
	pass

# ============================================================================
# SIGNAUX
# ============================================================================

func _on_tower_area_entered(area):
	"""Détection d'une cible entrante"""
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var tiles = get_tree().get_nodes_in_group("tile")
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	if area in tiles and area in enemies:
		if current_target == null:
			current_target = area
			start_attacking()

func _on_tower_area_exited(area):
	"""Détection d'une cible sortante"""
	if area == current_target:
		current_target = null
		find_new_target()

func _on_timer_timeout():
	"""Timer d'attaque"""
	if is_attacking:
		attack()

# ============================================================================
# UPGRADES (optionnel, pour plus tard)
# ============================================================================

func upgrade_damage(amount: int):
	base_damage += amount
	apply_skill_bonuses()

func upgrade_attack_speed(multiplier: float):
	base_fire_rate *= multiplier
	apply_skill_bonuses()
	if timer:
		timer.wait_time = actual_fire_rate

func upgrade_range(amount: int):
	base_range += amount
	apply_skill_bonuses()
	if tower_area and tower_area.has_node("CollisionShape2D2"):
		var collision = tower_area.get_node("CollisionShape2D2")
		if collision.shape is CircleShape2D:
			collision.shape.radius = actual_range

func upgrade_health(amount: int):
	base_health += amount
	apply_skill_bonuses()
	current_health += amount
