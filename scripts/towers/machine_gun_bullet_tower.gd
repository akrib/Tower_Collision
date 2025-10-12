# ============================================================================
# TOUR DE MITRAILLEUSE - Tir rapide, faibles dégâts
# ============================================================================
extends BaseTower
class_name MachineGunTower

func _ready():
	# Configuration
	attack_type = AttackType.RANGED
	target_type = TargetType.CLOSEST
	
	base_damage = 2
	base_fire_rate = 0.5  # Tire 2 fois par seconde
	base_range = 350
	base_health = 10
	projectile_speed = 2500
	
	projectile_scene = preload("res://scenes/bullets/machine_gun_bullet.tscn")
	super._ready()
	
