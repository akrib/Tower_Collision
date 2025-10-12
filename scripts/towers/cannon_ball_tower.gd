# ============================================================================
# TOUR DE CANON - Attaque en zone (AOE)
# ============================================================================
extends BaseTower
class_name CannonTower

func _ready():
	# Configuration
	attack_type = AttackType.RANGED
	target_type = TargetType.CLOSEST
	
	base_damage = 8
	base_fire_rate = 4.0
	base_range = 450
	base_health = 15
	splash_radius = 100.0  # Dégâts en zone de 100 pixels
	projectile_speed = 1500
	
	projectile_scene = preload("res://scenes/bullets/cannon_ball.tscn")
	super._ready()
