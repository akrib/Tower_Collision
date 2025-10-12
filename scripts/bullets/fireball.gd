# ============================================================================
# BOULE DE FEU - Dégâts + brûlure sur la durée
# ============================================================================
extends BaseProjectile
class_name Fireball

func _ready():
	projectile_type = ProjectileType.HOMING
	splash_radius = 80.0
	poison_damage = 2  # Réutiliser poison_damage pour la brûlure
	poison_duration = 3.0
	piercing = 0
	
	super._ready()
