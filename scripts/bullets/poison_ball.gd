# ============================================================================
# PROJECTILE DE POISON - Applique poison
# ============================================================================
extends BaseProjectile
class_name PoisonBall

func _ready():
	projectile_type = ProjectileType.HOMING
	poison_damage = 1
	poison_duration = 5.0
	piercing = 0
	
	super._ready()
