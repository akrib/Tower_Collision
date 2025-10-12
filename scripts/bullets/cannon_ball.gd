# ============================================================================
# PROJECTILE DE CANON - Balistique avec AOE
# ============================================================================
extends BaseProjectile
class_name CannonBall

func _ready():
	projectile_type = ProjectileType.BALLISTIC
	splash_radius = 100.0
	piercing = 0
	lifetime = 3.0
	
	super._ready()
