# ============================================================================
# ROQUETTE - Très rapide, gros dégâts, explosion
# ============================================================================
extends BaseProjectile
class_name Rocket

func _ready():
	projectile_type = ProjectileType.HOMING
	splash_radius = 120.0
	speed = 3500
	piercing = 0
	
	super._ready()

# Traînée de fumée
func _physics_process(delta):
	super._physics_process(delta)
	spawn_smoke_trail()

func spawn_smoke_trail():
	# Créer des particules de fumée derrière la roquette
	pass
