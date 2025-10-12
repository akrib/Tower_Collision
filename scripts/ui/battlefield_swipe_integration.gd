extends Node2D

# Référence pour intégrer le système de swipe dans votre battlefield existant

@onready var player_island = $player_path/PathFollow2D/Player_island
@onready var enemy_island = $ennemi_path/PathFollow2D/ennemi_island
@onready var player_path_follow = $player_path/PathFollow2D
@onready var enemy_path_follow = $ennemi_path/PathFollow2D

# Variables de combat avec swipe
var player_raft: JunkRaft
var collision_distance: float = 100.0
var is_combat_active: bool = false

func _ready():
	# Ajouter le système de swipe à l'île du joueur
	setup_player_swipe_system()
	
	# Connecter les signaux
	if player_raft:
		player_raft.impact_occurred.connect(_on_player_impact)
	
	# Démarrer la bataille après un délai
	await get_tree().create_timer(2.0).timeout
	start_swipe_battle()

func setup_player_swipe_system():
	"""Ajoute le système de swipe à l'île du joueur"""
	# Créer un JunkRaft component
	var raft_controller = JunkRaft.new()
	raft_controller.name = "RaftController"
	
	# Configuration
	raft_controller.base_speed = 50.0
	raft_controller.max_speed = 200.0
	raft_controller.min_speed = -30.0
	raft_controller.fuel_cost_per_swipe = 15.0
	raft_controller.fuel_recharge_rate = 8.0
	
	player_island.add_child(raft_controller)
	player_raft = raft_controller
	
	print("✅ Système de swipe activé pour l'île du joueur")

func start_swipe_battle():
	"""Démarre la bataille avec le système de swipe"""
	is_combat_active = true
	
	if player_raft:
		player_raft.start_combat()
	
	print("⚔️ Bataille avec swipe démarrée!")

func _process(delta):
	if not is_combat_active:
		return
	
	# Mettre à jour la position sur le Path2D selon la vitesse du swipe
	if player_raft:
		var swipe_speed = player_raft.current_speed
		player_path_follow.progress += swipe_speed * delta
	
	# L'ennemi continue avec sa vitesse normale
	var enemy_speed = 75.0  # Vitesse de base de l'ennemi
	enemy_path_follow.progress += enemy_speed * delta
	
	# Vérifier la collision
	check_collision()

func check_collision():
	"""Vérifie si les îles sont en collision"""
	var distance = player_island.global_position.distance_to(enemy_island.global_position)
	
	if distance < collision_distance and is_combat_active:
		on_islands_collide()

func on_islands_collide():
	"""Gère la collision entre les îles"""
	is_combat_active = false
	
	# Calculer les dégâts du joueur (basés sur sa vitesse)
	var player_damage = 0.0
	if player_raft:
		player_damage = player_raft.on_collision_with_enemy()
	
	# Calculer les dégâts de l'ennemi (vitesse fixe)
	var enemy_damage = calculate_enemy_impact_damage()
	
	# Appliquer les dégâts aux îles
	apply_collision_damage(player_damage, enemy_damage)
	
	# Afficher le résultat
	show_collision_result(player_damage, enemy_damage)
	
	# Effet de collision
	create_collision_effects()
	
	# Séparer les îles après collision
	await get_tree().create_timer(1.0).timeout
	separate_islands()

func calculate_enemy_impact_damage() -> float:
	"""Calcule les dégâts d'impact de l'ennemi"""
	var enemy_base_speed = 75.0
	var base_damage = 10.0
	var damage_factor = 1.5
	
	return base_damage + (enemy_base_speed - 50.0) * damage_factor

func apply_collision_damage(player_dmg: float, enemy_dmg: float):
	"""Applique les dégâts aux îles"""
	# Obtenir les tuiles des deux îles
	var player_tiles = get_tree().get_nodes_in_group("player")
	var enemy_tiles = get_tree().get_nodes_in_group("enemy")
	
	# Le joueur inflige des dégâts aux tuiles ennemies
	damage_random_tiles(enemy_tiles, int(player_dmg / 10))
	
	# L'ennemi inflige des dégâts aux tuiles du joueur
	damage_random_tiles(player_tiles, int(enemy_dmg / 10))

func damage_random_tiles(tiles: Array, tile_count: int):
	"""Endommage un nombre aléatoire de tuiles"""
	if tiles.size() == 0:
		return
	
	for i in range(min(tile_count, tiles.size())):
		var random_tile = tiles[randi() % tiles.size()]
		if random_tile and random_tile.has_method("take_damage"):
			random_tile.take_damage(1)

func show_collision_result(player_dmg: float, enemy_dmg: float):
	"""Affiche le résultat de la collision"""
	var result_text = ""
	
	if player_dmg > enemy_dmg:
		result_text = "💥 COLLISION PUISSANTE! +%.0f dégâts!" % player_dmg
	elif player_dmg < enemy_dmg:
		result_text = "⚠️ Impact défavorable! -%0.f dégâts subis!" % enemy_dmg
	else:
		result_text = "⚡ Collision équilibrée!"
	
	show_big_message(result_text)

func show_big_message(text: String):
	"""Affiche un gros message au centre de l'écran"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	label.position = get_viewport_rect().size / 2 - Vector2(300, 50)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func create_collision_effects():
	"""Crée les effets visuels de collision"""
	# Shake de caméra (si vous avez une caméra)
	if has_node("Camera2D"):
		var camera = $Camera2D
		shake_camera(camera, 0.8, 15.0)
	
	# Particules d'explosion au point de collision
	var collision_point = (player_island.global_position + enemy_island.global_position) / 2
	spawn_explosion_particles(collision_point)
	
	# Son d'impact (à ajouter)
	print("🔊 *BOOM*")

func shake_camera(camera: Camera2D, duration: float, intensity: float):
	"""Secoue la caméra"""
	var original_offset = camera.offset
	var shake_count = int(duration * 30)  # 30 FPS
	
	for i in range(shake_count):
		var shake = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		camera.offset = original_offset + shake
		await get_tree().create_timer(0.033).timeout
	
	camera.offset = original_offset

func spawn_explosion_particles(pos: Vector2):
	"""Crée des particules d'explosion"""
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 50
	particles.lifetime = 1.0
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 30.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 300.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(1, 0.5, 0.2)
	
	add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	
	# Supprimer après l'animation
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

func separate_islands():
	"""Sépare les îles après la collision"""
	# Reculer légèrement les îles
	if player_path_follow.progress > 100:
		player_path_follow.progress -= 100
	
	if enemy_path_follow.progress > 100:
		enemy_path_follow.progress -= 100
	
	# Reprendre le combat
	await get_tree().create_timer(0.5).timeout
	is_combat_active = true
	
	if player_raft:
		player_raft.start_combat()

func _on_player_impact(damage: float):
	"""Callback quand le joueur fait un impact"""
	print("💥 Impact du joueur: %.0f dégâts" % damage)

# ============================================================================
# INTÉGRATION AVEC VOTRE SYSTÈME EXISTANT
# ============================================================================

func end_battle(winner: String):
	"""Termine la bataille (intégration avec votre système existant)"""
	is_combat_active = false
	
	if player_raft:
		player_raft.end_combat()
	
	# Appeler votre fonction end_game existante
	if winner == "player":
		# Le joueur a gagné
		if has_method("end_game"):
			end_game("player")
	else:
		# L'ennemi a gagné
		if has_method("end_game"):
			end_game("enemy")

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

func get_swipe_tutorial_text() -> String:
	"""Retourne le texte du tutoriel pour le swipe"""
	return """
	🎮 CONTRÔLES DE SWIPE:
	
	→ Swipe DROITE: Accélérer (boost)
	← Swipe GAUCHE: Freiner/Reculer
	
	⛽ Chaque swipe consomme du carburant
	🔋 Le carburant se recharge automatiquement
	
	💡 Stratégie:
	- Accélérez pour infliger plus de dégâts
	- Freinez pour économiser le carburant
	- Timing parfait = maximum de dégâts!
	"""

func show_tutorial():
	"""Affiche le tutoriel au début"""
	var tutorial_label = Label.new()
	tutorial_label.text = get_swipe_tutorial_text()
	tutorial_label.add_theme_font_size_override("font_size", 24)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.position = Vector2(100, 200)
	add_child(tutorial_label)
	
	await get_tree().create_timer(8.0).timeout
	
	var tween = create_tween()
	tween.tween_property(tutorial_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(tutorial_label.queue_free)
