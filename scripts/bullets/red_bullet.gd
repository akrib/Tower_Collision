extends CharacterBody2D

# Énumération pour les équipes (doit correspondre à celle de la tour)
enum Team { NONE, PLAYER, ENEMY }
@onready var impact_particles = preload("res://scenes/effects/explode.tscn")
# Configuration de la balle
@export var team: Team = Team.NONE
@export var bullet_damage: int = 1
@export var speed: int = 2000

# État interne
var target = null


func _physics_process(_delta):
	if is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position) * speed
		look_at(target.global_position)
		move_and_slide()
	else:
		# Si la cible n'existe plus, détruire la balle
		queue_free()


func set_target(obj):
	target = obj


# Collision avec un body (pour les tours)
func _on_area_2d_body_entered(body):
	if "tower" in body.name.to_lower():
		# Vérifier si c'est un ennemi
		if is_enemy_tower(body):
			body.take_damage(bullet_damage)
			queue_free()


# Collision avec une area (pour les tuiles)
func _on_area_2d_area_entered(area):
	var tiles = get_tree().get_nodes_in_group("tile")
	
	# Vérifier si c'est une tuile
	if area not in tiles:
		return
	
	# Déterminer si c'est une tuile ennemie
	if is_enemy_tile(area):
		area.health -= bullet_damage
		spawn_explosion(global_position)
		queue_free()
		
		
func spawn_explosion(pos: Vector2):
	var explosion = impact_particles.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = pos
	explosion.emitting = true

func is_enemy_tower(tower) -> bool:
	# Si on a pas de team, on ne touche rien
	if team == Team.NONE:
		return false
	
	# Player blesse Enemy, Enemy blesse Player
	if team == Team.PLAYER and tower.team == Team.ENEMY:
		return true
	if team == Team.ENEMY and tower.team == Team.PLAYER:
		return true
	
	return false


func is_enemy_tile(tile) -> bool:
	# Si on a pas de team, on ne touche rien
	if team == Team.NONE:
		return false
	
	var enemy_tiles = get_tree().get_nodes_in_group("enemy" if team == Team.PLAYER else "player")
	return tile in enemy_tiles
