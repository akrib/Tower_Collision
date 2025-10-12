# ============================================================================
# PROJECTILE DE SOIN - Soigne les alliés
# ============================================================================
extends BaseProjectile
class_name HealOrb

func _ready():
	projectile_type = ProjectileType.HOMING
	piercing = 0
	
	super._ready()

# Surcharger pour soigner au lieu de faire des dégâts
func hit_target(target_hit):
	has_hit_targets.append(target_hit)
	hit_count += 1
	
	# Soigner la cible
	if target_hit.has_method("heal"):
		target_hit.heal(bullet_damage)  # bullet_damage devient heal_amount
	
	spawn_heal_effect(target_hit.global_position)
	queue_free()

func spawn_heal_effect(pos: Vector2):
	# Particules vertes de soin
	pass

# Redéfinir la détection pour cibler les alliés
func is_enemy_tile(tile) -> bool:
	# Pour le soin, on cible nos ALLIÉS, pas les ennemis
	var ally_group = "player" if team == Team.PLAYER else "enemy"
	var ally_tiles = get_tree().get_nodes_in_group(ally_group)
	return tile in ally_tiles

func is_enemy_tower(tower) -> bool:
	# Pour le soin, on cible nos ALLIÉS
	if team == Team.NONE:
		return false
	
	if not tower.has("team"):
		return false
	
	# Cibler les alliés
	if team == Team.PLAYER and tower.team == BaseTower.Team.PLAYER:
		return true
	if team == Team.ENEMY and tower.team == BaseTower.Team.ENEMY:
		return true
	
	return false
