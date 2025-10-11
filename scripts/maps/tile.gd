extends Area2D

var team = ""  # "player" ou "enemy"
var health = 3
@onready var smoke_particles = preload("res://scenes/effects/smoke.tscn")  # à créer

func _process(delta):
	if health < 1:
		death()

func death():
	queue_free()

func _on_area_entered(area):
	# Vérifie que l'autre est une tuile
	if not area.is_in_group("tile"):
		return

	# Collision entre équipes opposées
	if team == 1 and area.is_in_group("enemy"):  
		resolve_collision(area)
	elif team == 2 and area.is_in_group("player"): 
		resolve_collision(area)

func resolve_collision(other):
	# Réduction des PV
	health -= 1
	other.health -= 1

	# Générer des particules de fumée
	spawn_smoke(global_position)
	spawn_smoke(other.global_position)

	# Vérifier la mort
	if health <= 0:
		death()
	if other.health <= 0:
		other.death()

func spawn_smoke(pos: Vector2):
	var smoke = smoke_particles.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.global_position = pos
	smoke.emitting = true
