# ============================================================================
# PROJECTILE PERFORANT - Traverse plusieurs ennemis
# ============================================================================
extends BaseProjectile
class_name PiercingArrow

func _ready():
	projectile_type = ProjectileType.DIRECT
	piercing = 3  # Traverse 3 ennemis
	speed = 2500
	
	super._ready()
