# ============================================================================
# RAYON LASER - Instantané
# ============================================================================
extends BaseProjectile
class_name LaserBeam

func _ready():
	projectile_type = ProjectileType.BEAM
	piercing = 5  # Traverse beaucoup d'ennemis
	speed = 10000  # Très rapide
	lifetime = 0.5  # Courte durée
	
	super._ready()

# Le laser se déplace en ligne droite instantanément
func _physics_process(delta):
	if is_instance_valid(target):
		# Téléporter directement à la cible
		global_position = target.global_position
		hit_target(target)
	else:
		queue_free()
