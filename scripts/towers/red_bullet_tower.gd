extends BaseTower

func _ready():
	# Configuration spécifique de la tour rouge
	attack_type = AttackType.RANGED
	target_type = TargetType.CLOSEST
	
	# Charger la scène de projectile
	projectile_scene = preload("res://scenes/bullets/red_bullet.tscn")
	
	# Appeler le _ready du parent
	super._ready()

# Cette tour utilise le comportement par défaut de BaseTower
# Pas besoin de surcharger les méthodes sauf si on veut un comportement spécial
