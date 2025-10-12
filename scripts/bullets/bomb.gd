# ============================================================================
# BOMBE - Explosion en zone au contact
# ============================================================================
extends BaseProjectile
class_name Bomb

func _ready():
	projectile_type = ProjectileType.BALLISTIC
	splash_radius = 150.0
	piercing = 0
	lifetime = 4.0
	
	super._ready()

# Surcharger pour exploser en touchant le sol
func move_ballistic(delta):
	super.move_ballistic(delta)
	
	# Si le projectile touche le "sol" (y > certain seuil), exploser
	if global_position.y > 800:  # À ajuster selon votre jeu
		explode_on_ground()

func explode_on_ground():
	apply_splash_damage(global_position)
	spawn_impact_effect(global_position)
	queue_free()
