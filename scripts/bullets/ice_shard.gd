# ============================================================================
# PROJECTILE DE GLACE - Ralentit la cible
# ============================================================================
extends BaseProjectile
class_name IceShard

func _ready():
	projectile_type = ProjectileType.HOMING
	slow_duration = 3.0
	slow_amount = 0.5
	piercing = 0
	
	super._ready()
