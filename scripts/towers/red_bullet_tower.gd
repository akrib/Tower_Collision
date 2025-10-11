extends StaticBody2D

# Énumération pour les équipes (plus propre que des strings)
enum Team { NONE, PLAYER, ENEMY }

# Configuration de la tour
@export var team: Team = Team.NONE
@export var bullet_damage: int = 5
@export var fire_rate: float = 3.0
@export var attack_range: int = 400
@export var health: int = 10

# Ressources et état interne
var red_bullet = preload("res://scenes/bullets/red_bullet.tscn")
var current_target = null
var targets_in_range = []

@onready var timer = $"Upgrade/ProgressBar/Timer"
@onready var tower_area = $Tower
@onready var bullet_container = $BulletContainer


func _ready():
	# Configurer le timer avec le fire_rate
	timer.wait_time = fire_rate
	
	# Configurer la portée
	$Tower/CollisionShape2D2.shape.radius = attack_range


func _process(_delta):
	$"Upgrade/ProgressBar".z_index = 900
	
	if is_instance_valid(current_target):
		look_at(current_target.global_position)
	else:
		# Nettoyer les balles si la cible n'existe plus
		clear_bullets()
		# Chercher une nouvelle cible
		find_new_target()


func shoot():
	if not is_instance_valid(current_target):
		return
	
	var bullet = red_bullet.instantiate()
	bullet.team = team  # Passer l'enum Team à la balle
	bullet.set_target(current_target)
	bullet.bullet_damage = bullet_damage
	
	bullet_container.add_child(bullet)
	bullet.global_position = $Aim.global_position


func clear_bullets():
	for bullet in bullet_container.get_children():
		bullet.queue_free()


func find_new_target():
	# Déterminer le groupe ennemi en fonction de notre team
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	
	var tiles = get_tree().get_nodes_in_group("tile")
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	# Récupérer toutes les areas dans la portée
	targets_in_range = tower_area.get_overlapping_areas()
	
	# Filtrer pour ne garder que les tuiles ennemies
	var valid_targets = []
	for target in targets_in_range:
		if target in tiles and target in enemies:
			valid_targets.append(target)
	
	# Trouver la cible la plus proche
	if valid_targets.size() > 0:
		current_target = get_closest_target(valid_targets)
		if not timer.is_stopped() == false:
			timer.start()
	else:
		current_target = null


func get_closest_target(targets: Array) -> Area2D:
	var closest = null
	var min_distance = INF
	
	for target in targets:
		var distance = global_position.distance_to(target.global_position)
		if distance < min_distance:
			min_distance = distance
			closest = target
	
	return closest


func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()


func die():
	queue_free()


# Signaux de la zone de détection
func _on_tower_area_entered(area):
	# Déterminer le groupe ennemi
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	
	var tiles = get_tree().get_nodes_in_group("tile")
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	# Vérifier si c'est une tuile ennemie
	if area in tiles and area in enemies:
		if current_target == null:
			current_target = area
			shoot()
			if timer.is_stopped():
				timer.start()


func _on_tower_area_exited(area):
	if area == current_target:
		current_target = null
		find_new_target()


func _on_timer_timeout():
	shoot()


# Fonctions d'upgrade (à réactiver plus tard si besoin)
func upgrade_range(amount: int):
	attack_range += amount
	$Tower/CollisionShape2D2.shape.radius = attack_range


func upgrade_attack_speed(amount: float):
	fire_rate = max(0.3, fire_rate - amount)
	timer.wait_time = fire_rate


func upgrade_damage(amount: int):
	bullet_damage += amount
