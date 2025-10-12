# ============================================================================
# TOUR LASER - Dégâts continus
# ============================================================================
extends BaseTower
class_name LaserTower

func _ready():
	# Configuration
	attack_type = AttackType.RANGED
	target_type = TargetType.STRONGEST
	
	base_damage = 1  # Peu de dégâts par tick
	base_fire_rate = 0.1  # Attaque très rapide = rayon continu
	base_range = 500
	base_health = 12
	projectile_speed = 5000  # Très rapide = quasi instantané
	
	projectile_scene = preload("res://scenes/bullets/laser_beam.tscn")
	super._ready()
