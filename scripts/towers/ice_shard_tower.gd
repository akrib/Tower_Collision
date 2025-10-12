# ============================================================================
# TOUR DE GLACE - Ralentit les ennemis
# ============================================================================
extends BaseTower
class_name IceTower

func _ready():
	# Configuration
	attack_type = AttackType.RANGED
	target_type = TargetType.FIRST
	
	base_damage = 3
	slow_amount = 0.5  # Ralentit de 50%
	base_fire_rate = 2.5
	base_range = 400
	base_health = 10
	projectile_speed = 1800
	
	projectile_scene = preload("res://scenes/bullets/ice_shard.tscn")
	super._ready()
	
