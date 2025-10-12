# ============================================================================
# TOUR DE SNIPER - Longue portée, dégâts élevés, lent
# ============================================================================
extends BaseTower
class_name SniperTower

func _ready():
	# Configuration
	attack_type = AttackType.RANGED
	target_type = TargetType.FARTHEST
	
	base_damage = 20
	base_fire_rate = 5.0  # Tire toutes les 5 secondes
	base_range = 800  # Longue portée
	base_health = 8
	projectile_speed = 3000  # Projectile rapide
	
	projectile_scene = preload("res://scenes/bullets/sniper_bullet.tscn")
	super._ready()
