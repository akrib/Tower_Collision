# ============================================================================
# TOUR ÉLECTRIQUE - Chaîne entre plusieurs ennemis
# ============================================================================
extends BaseTower
class_name ElectricTower

func _ready():
	# Configuration
	attack_type = AttackType.RANGED
	target_type = TargetType.CLOSEST
	
	base_damage = 6
	base_fire_rate = 2.0
	base_range = 350
	base_health = 10
	projectile_speed = 2500
	
	projectile_scene = preload("res://scenes/bullets/lightning.tscn")
	super._ready()

# Pour cette tour, on peut surcharger attack() pour créer un effet de chaîne
func attack():
	if not is_instance_valid(current_target):
		return
	
	# Attaque la cible principale
	apply_damage_to_target(current_target, actual_damage)
	
	# Chercher des cibles secondaires proches
	var enemy_group = "enemy" if team == Team.PLAYER else "player"
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	var chained = 0
	var max_chains = 3
	var chain_range = 150.0
	var last_target = current_target
	
	while chained < max_chains:
		var next_target = null
		var min_dist = chain_range
		
		for enemy in enemies:
			if enemy == last_target or enemy == current_target:
				continue
			
			var dist = last_target.global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				next_target = enemy
		
		if next_target:
			# Dégâts réduits pour chaque rebond
			var chain_damage = int(actual_damage * pow(0.7, chained + 1))
			apply_damage_to_target(next_target, chain_damage)
			
			# Effet visuel de chaîne (à implémenter)
			spawn_chain_effect(last_target.global_position, next_target.global_position)
			
			last_target = next_target
			chained += 1
		else:
			break

func spawn_chain_effect(from: Vector2, to: Vector2):
	# À implémenter : ligne d'électricité entre from et to
	pass
