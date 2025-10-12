# ============================================================================
# TOUR EXPLOSIVE - Gros dégâts en zone, tire lentement
# ============================================================================
extends BaseTower
class_name BombTower

func _ready():
	# Configuration
	attack_type = AttackType.RANGED
	target_type = TargetType.CLOSEST
	
	base_damage = 15
	splash_radius = 150.0  # Grande zone d'effet
	base_fire_rate = 6.0  # Très lent
	base_range = 400
	base_health = 20
	projectile_speed = 800  # Projectile lent
	
	projectile_scene = preload("res://scenes/bullets/bomb.tscn")
	super._ready()
