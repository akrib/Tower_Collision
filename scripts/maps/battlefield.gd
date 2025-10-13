extends Node2D

# ============================================================================
# BATTLEFIELD - Gère le combat entre les deux îles
# ============================================================================

# UI et profil
@onready var ui = $UI
@onready var player_profile = $PlayerProfileUI as PlayerProfileUI
var xp_gain = 50

# Références aux paths et islands
@onready var player_path = $player_path
@onready var enemy_path = $ennemi_path
@onready var player_path_follow = $player_path/PathFollow2D
@onready var enemy_path_follow = $ennemi_path/PathFollow2D
@onready var player_island = $player_path/PathFollow2D/Player_island
@onready var enemy_island = $ennemi_path/PathFollow2D/ennemi_island

# Système de swipe (JunkRaft)
var player_raft: JunkRaft

# État du combat
var is_game_over = false
var speed_boost_active = false
const STAGNATION_TIME = 10.0
var time_since_last_tile_destroyed = 0.0
var last_tile_count_player = 64
var last_tile_count_enemy = 64

# Cooldown pour éviter les collisions répétées
var collision_cooldown = 0.0
const COLLISION_COOLDOWN_TIME = 1.0

func _ready():
	# Configurer l'UI pour qu'elle continue de fonctionner en pause
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connecter les boutons
	ui.get_node("EndPanel/RetryButton").pressed.connect(_on_retry_button_pressed)
	ui.get_node("EndPanel/MenuButton").pressed.connect(_on_menu_button_pressed)
	
	# S'assurer que l'UI de fin est cachée au départ
	ui.visible = false
	
	# Attendre que tout soit prêt avant de setup le swipe
	await get_tree().process_frame
	setup_swipe_system()
	
	print("🎮 Battlefield initialisé")

func setup_swipe_system():
	"""Configure le système de swipe pour l'île du joueur"""
	if not player_island:
		push_error("❌ Player island non trouvée!")
		return
	
	# Créer l'instance de JunkRaft
	var raft = JunkRaft.new()
	raft.name = "SwipeController"
	
	# L'ajouter comme enfant de l'île
	player_island.add_child(raft)
	player_raft = raft
	
	# Connecter les signaux pour feedback
	player_raft.speed_changed.connect(_on_speed_changed)
	player_raft.fuel_changed.connect(_on_fuel_changed)
	player_raft.out_of_fuel.connect(_on_out_of_fuel)
	player_raft.impact_occurred.connect(_on_impact_occurred)
	
	# Démarrer le combat
	player_raft.start_combat()
	
	print("✅ Système de swipe activé - Vitesse de base: %.1f" % player_raft.base_speed)

func _process(delta):
	if is_game_over:
		return
	
	# Réduire le cooldown de collision
	if collision_cooldown > 0:
		collision_cooldown -= delta
	
	# Vérifier si le combat stagne
	check_stagnation(delta)
	
	# Déplacer l'île du joueur selon la vitesse du swipe
	if player_raft:
		var player_speed = player_raft.current_speed
		# Appliquer le boost de vitesse si actif
		if speed_boost_active:
			player_speed *= 3.0
		player_path_follow.progress += player_speed * delta
	
	# L'ennemi garde sa vitesse fixe (ou accélère aussi si boost actif)
	var enemy_speed = 75.0
	if speed_boost_active:
		enemy_speed *= 3.0
	
	enemy_path_follow.progress += enemy_speed * delta
	
	# Vérifier les conditions de victoire/défaite
	check_victory_conditions()
	
	# Détecter la collision entre les îles (avec cooldown)
	if collision_cooldown <= 0:
		check_island_collision()

func check_stagnation(delta: float):
	"""Vérifie si le combat stagne (aucune tuile détruite depuis X secondes)"""
	# Compter les tuiles actuelles
	var current_player_tiles = get_alive_tiles_count("player")
	var current_enemy_tiles = get_alive_tiles_count("enemy")
	
	# Vérifier si une tuile a été détruite depuis le dernier check
	var tile_destroyed = (current_player_tiles < last_tile_count_player) or (current_enemy_tiles < last_tile_count_enemy)
	
	if tile_destroyed:
		# Réinitialiser le chronomètre
		time_since_last_tile_destroyed = 0.0
		last_tile_count_player = current_player_tiles
		last_tile_count_enemy = current_enemy_tiles
		
		# Désactiver le boost si une tuile a été détruite
		if speed_boost_active:
			speed_boost_active = false
			show_temporary_message("⏸️ Vitesse normale", Color.GREEN)
			print("⏸️ Boost désactivé - Une tuile a été détruite")
	else:
		# Incrémenter le chronomètre
		time_since_last_tile_destroyed += delta
		
		# Activer l'accélération si le seuil est atteint
		if time_since_last_tile_destroyed >= STAGNATION_TIME and not speed_boost_active:
			speed_boost_active = true
			show_temporary_message("⚡ ACCÉLÉRATION - COMBAT BLOQUÉ!", Color.ORANGE_RED)
			print("⚡ Combat stagne depuis %.1f secondes - Accélération activée" % time_since_last_tile_destroyed)

func get_alive_tiles_count(group_name: String) -> int:
	"""Compte le nombre de tuiles vivantes pour un groupe"""
	var tiles = get_tree().get_nodes_in_group(group_name)
	# Filtrer pour ne compter que les tuiles (pas les tours)
	tiles = tiles.filter(func(node): return node.is_in_group("tile"))
	return tiles.size()

func check_victory_conditions():
	"""Vérifie si la bataille est terminée"""
	if ui.visible:
		return  # Déjà terminé
	
	var player_tiles = get_tree().get_nodes_in_group("player")
	var enemy_tiles = get_tree().get_nodes_in_group("enemy")
	
	# Filtrer pour ne compter que les tuiles (pas les tours)
	player_tiles = player_tiles.filter(func(node): return node.is_in_group("tile"))
	enemy_tiles = enemy_tiles.filter(func(node): return node.is_in_group("tile"))
	
	if player_tiles.size() == 0:
		end_game("enemy")
	elif enemy_tiles.size() == 0:
		end_game("player")

func check_island_collision():
	"""Vérifie si les îles sont assez proches pour entrer en collision"""
	if not player_island or not enemy_island:
		return
	
	# Distance entre les deux îles
	var distance = player_island.global_position.distance_to(enemy_island.global_position)
	
	# Seuil de collision (à ajuster selon la taille des îles)
	var collision_threshold = 250.0
	
	if distance < collision_threshold:
		trigger_island_impact()

func trigger_island_impact():
	"""Déclenche l'impact entre les îles"""
	if not player_raft:
		return
	
	# Activer le cooldown pour éviter les impacts répétés
	collision_cooldown = COLLISION_COOLDOWN_TIME
	
	# Calculer les dégâts d'impact basés sur la vitesse
	var damage = player_raft.on_collision_with_enemy()
	
	print("💥 Impact! Dégâts: %.0f" % damage)
	
	# Appliquer les dégâts aux tuiles ennemies les plus proches
	apply_collision_damage_to_tiles(damage, "enemy")
	
	# Les tuiles ennemies ripostent aussi (dégâts fixes)
	var enemy_damage = 15.0
	apply_collision_damage_to_tiles(enemy_damage, "player")
	
	# Réinitialiser le compteur de stagnation après un impact
	time_since_last_tile_destroyed = 0.0

func apply_collision_damage_to_tiles(damage: float, target_group: String):
	"""Applique les dégâts d'impact aux tuiles du groupe cible"""
	var all_tiles = get_tree().get_nodes_in_group(target_group)
	# Filtrer pour ne garder que les vraies tuiles
	var tiles = all_tiles.filter(func(node): return node.is_in_group("tile"))
	
	if tiles.size() == 0:
		return
	
	# Trier par proximité (toucher les tuiles de devant en premier)
	var sorted_tiles = tiles.duplicate()
	sorted_tiles.sort_custom(func(a, b): 
		return a.global_position.x < b.global_position.x if target_group == "enemy" else a.global_position.x > b.global_position.x
	)
	
	# Distribuer les dégâts sur les 3-5 premières tuiles
	var tiles_to_hit = min(5, sorted_tiles.size())
	var damage_per_tile = int(damage / tiles_to_hit)
	
	for i in range(tiles_to_hit):
		if is_instance_valid(sorted_tiles[i]) and sorted_tiles[i].has_method("take_damage"):
			sorted_tiles[i].take_damage(damage_per_tile)
			print("  💢 Tuile %s prend %d dégâts d'impact" % [sorted_tiles[i].name, damage_per_tile])

func end_game(winner: String):
	"""Termine la partie"""
	if is_game_over:
		return
	
	is_game_over = true
	get_tree().paused = true
	
	# Arrêter le combat
	if player_raft:
		player_raft.end_combat()
	
	var message = ""
	if winner == "player":
		# Ajouter l'XP au profil du joueur
		if player_profile:
			player_profile.add_xp(xp_gain)
		
		# Enregistrer la victoire
		PlayerData.add_battle_result(true)
		
		message = "🎉 VICTOIRE ! 🎉\n\nVous gagnez %d XP\nVitesse finale: %.0f m/s" % [xp_gain, player_raft.current_speed if player_raft else 0]
	else:
		# Enregistrer la défaite
		PlayerData.add_battle_result(false)
		
		message = "💀 DÉFAITE 💀\n\nVotre île a été détruite!\nRéessayez pour gagner de l'XP"
	
	# Afficher le panneau de fin
	ui.visible = true
	ui.get_node("EndPanel/MessageLabel").text = message
	ui.get_node("EndPanel").visible = true
	
	print("🏁 Fin de partie - Gagnant: %s" % winner)

# ============================================================================
# CALLBACKS DES SIGNAUX DU JUNKRAFT
# ============================================================================

func _on_speed_changed(new_speed: float):
	"""Callback quand la vitesse change"""
	pass

func _on_fuel_changed(new_fuel: float):
	"""Callback quand le carburant change"""
	if new_fuel < 20.0 and new_fuel > 0:
		pass

func _on_out_of_fuel():
	"""Callback quand il n'y a plus de carburant"""
	show_temporary_message("⛽ PLUS DE CARBURANT!", Color.RED)

func _on_impact_occurred(damage: float):
	"""Callback lors d'un impact"""
	show_temporary_message("💥 IMPACT! %.0f dégâts" % damage, Color.ORANGE)

func show_temporary_message(text: String, color: Color):
	"""Affiche un message temporaire à l'écran"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Positionner au centre de l'écran
	label.position = Vector2(get_viewport_rect().size.x / 2 - 200, 200)
	label.size = Vector2(400, 100)
	
	add_child(label)
	
	# Animation de disparition
	var tween = create_tween()
	tween.tween_property(label, "position:y", 100, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

# ============================================================================
# CALLBACKS DES BOUTONS UI
# ============================================================================

func _on_retry_button_pressed():
	"""Recommencer la bataille"""
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	"""Retour au menu principal"""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

# ============================================================================
# DEBUG (à retirer en production)
# ============================================================================

func _input(event):
	# Debug : Appuyer sur Espace pour gagner instantanément
	if event.is_action_pressed("ui_accept") and OS.is_debug_build():
		print("🔧 DEBUG: Victoire forcée")
		end_game("player")
