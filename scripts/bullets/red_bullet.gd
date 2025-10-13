extends BaseProjectile

func _ready():
	# Configuration spécifique du projectile rouge
	projectile_type = ProjectileType.HOMING
	
	# Appeler le _ready du parent
	super._ready()

# Ce projectile utilise le comportement par défaut de BaseProjectile
# Pas besoin de surcharger les méthodes
