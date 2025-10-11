extends Node

# Ressources du joueur
var gold: int = 100
var health: int = 10

# Statistiques de jeu
var wave_number: int = 1
var enemies_killed: int = 0
var towers_placed: int = 0

# Signaux pour notifier les changements
signal gold_changed(new_amount)
signal health_changed(new_amount)
signal game_over


func _ready():
	# Initialisation si nécessaire
	pass


# Méthodes pour modifier l'or avec validation
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


# Méthodes pour modifier la santé
func take_damage(amount: int) -> void:
	health -= amount
	health_changed.emit(health)
	
	if health <= 0:
		health = 0
		game_over.emit()


func heal(amount: int) -> void:
	health += amount
	health_changed.emit(health)


# Réinitialiser le jeu
func reset_game() -> void:
	gold = 100
	health = 10
	wave_number = 1
	enemies_killed = 0
	towers_placed = 0
	
	gold_changed.emit(gold)
	health_changed.emit(health)
