# ============================================================================
# TOUR DE POISON - Dégâts sur la durée
# ============================================================================
extends BaseTower
class_name PoisonTower

func _ready():
	# Configuration
	attack_type = AttackType.RANGED
	target_type = TargetType.CLOSEST
	
	base_damage = 2
	poison_damage = 1  # 1 dégât par seconde
	base_fire_rate = 3.0
	base_range = 380
	base_health = 10
	projectile_speed = 1600
	
	projectile_scene = preload("res://scenes/bullets/poison_ball.tscn")
	super._ready()
	
