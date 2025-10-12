extends Node2D

# ============================================================================
# PLAYER TILE HOLDER - Construit l'île 8×8 et charge les tours
# ============================================================================

@export var team_id: int = 1  # 1 = joueur, 2 = ennemi

# Scènes préchargées
@onready var tile_scene = preload("res://scenes/maps/tile.tscn")
@onready var tower_scene = preload("res://scenes/towers/red_bullet_tower.tscn")

# Constantes de la grille isométrique
const TILE_WIDTH = 128
const TILE_HEIGHT = 74
const GRID_SIZE = 8

# Grille de tuiles
var island_tile_map = []

# Référence au système de swipe (si joueur)
var junk_raft: JunkRaft

func _ready():
	print("🏝️ Construction de l'île (team %d)..." % team_id)
	create_iso_grid()
	draw_towers()
	
	# Si c'est l'île du joueur, attendre le JunkRaft
	if team_id == 1:
		await get_tree().process_frame
		setup_junk_raft()

# ============================================================================
# CONSTRUCTION DE LA GRILLE 8×8
# ============================================================================

#func create_iso_grid():
	#"""Crée la grille isométrique de 8×8 tuiles"""
	#var group_name = "player" if team_id == 1 else "enemy"
	#
	#for x in range(GRID_SIZE):
		#island_tile_map.append([])
		#for y in range(GRID_SIZE):
			## Créer une nouvelle tuile
			#var new_tile = tile_scene.instantiate()
			#add_child(new_tile)
#
			## Position isométrique
			#var iso_pos = Vector2((x - y) * TILE_WIDTH / 2, (x + y) * TILE_HEIGHT / 2)
			#new_tile.position = iso_pos
			#new_tile.name = "tile_%d_%d" % [x, y]
			#
			## Configuration de la tuile
			#new_tile.team = team_id
			#new_tile.add_to_group(group_name)
			#new_tile.add_to_group("tile")
#
			## Stocker dans la grille
			#island_tile_map[x].append(new_tile)
	#
	#print("  ✅ Grille %d×%d créée (%s)" % [GRID_SIZE, GRID_SIZE, group_name])
	
	
func create_iso_grid():
	"""Crée la grille isométrique de 8×8 tuiles"""
	var group_name = "player" if team_id == 1 else "enemy"
	
	for x in range(GRID_SIZE):
		island_tile_map.append([])
		for y in range(GRID_SIZE):
			# Créer une nouvelle tuile
			var new_tile = tile_scene.instantiate()
			add_child(new_tile)

			# Position isométrique
			var iso_pos = Vector2((x - y) * TILE_WIDTH / 2, (x + y) * TILE_HEIGHT / 2)
			new_tile.position = iso_pos
			new_tile.name = "tile_%d_%d" % [x, y]
			
			# Configuration de la tuile
			new_tile.team = team_id
			new_tile.add_to_group(group_name)
			new_tile.add_to_group("tile")
			
			# ✅ APPLIQUER LE SHADER MANUELLEMENT
			setup_tile_shader(new_tile, y)

			# Stocker dans la grille
			island_tile_map[x].append(new_tile)
	
	print("  ✅ Grille %d×%d créée (%s)" % [GRID_SIZE, GRID_SIZE, group_name])

func setup_tile_shader(tile: Area2D, row: int):
	"""Configure le shader de profondeur pour la tuile"""
	# Trouver le sprite de la tuile
	var tile_sprite = tile.get_node_or_null("tile")
	if not tile_sprite or not tile_sprite is Sprite2D:
		return
	
	# Vérifier si le shader est déjà appliqué
	if tile_sprite.material and tile_sprite.material is ShaderMaterial:
		# Le shader existe, juste mettre à jour le depth_factor
		var shader_mat = tile_sprite.material as ShaderMaterial
		
		# Calculer la profondeur selon la ligne (0 = loin, 7 = près)
		var depth = float(row) / float(GRID_SIZE - 1)
		shader_mat.set_shader_parameter("depth_factor", depth)
	else:
		# Créer le matériau shader manuellement
		var shader_mat = ShaderMaterial.new()
		var shader = load("res://shaders/iso_depth_effect.gdshader")
		shader_mat.shader = shader
		
		# Calculer la profondeur selon la ligne
		var depth = float(row) / float(GRID_SIZE - 1)
		shader_mat.set_shader_parameter("depth_factor", depth)
		
		# Appliquer le matériau
		tile_sprite.material = shader_mat
	

# ============================================================================
# CHARGEMENT DES TOURS DEPUIS LA SAUVEGARDE
# ============================================================================

func draw_towers():
	"""Charge et place les tours depuis TowerDataManager"""
	TowerDataManager.load_layout()
	var island_tower_map = TowerDataManager.get_layout()
	var group_name = "player" if team_id == 1 else "enemy"
	
	var towers_placed = 0
	
	if group_name == "player":
		# Île du joueur : placement normal
		for x in range(GRID_SIZE):
			for y in range(GRID_SIZE):
				if island_tower_map[x][y] > 0:
					create_tower(x, y, island_tower_map[x][y])
					towers_placed += 1
	else:
		# Île ennemie : placement inversé (effet miroir)
		for x in range(GRID_SIZE):
			for y in range(GRID_SIZE):
				if island_tower_map[x][y] > 0:
					create_tower(y, x, island_tower_map[x][y])
					towers_placed += 1
	
	print("  ✅ %d tours placées (%s)" % [towers_placed, group_name])

func create_tower(x: int, y: int, tower_type: int):
	"""Crée et place une tour sur la tuile"""
	# Vérifier que les coordonnées sont valides
	if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
		push_warning("⚠️ Coordonnées de tour invalides: (%d, %d)" % [x, y])
		return
	
	# Créer la tour
	var new_tower = tower_scene.instantiate()
	var tile_node = island_tile_map[x][y]
	
	# Ajouter comme enfant de la tuile
	tile_node.add_child(new_tower)
	
	# Configuration visuelle
	new_tower.scale = Vector2(0.5, 0.5)
	new_tower.position = Vector2(0, -TILE_HEIGHT * 0.35)  # Centrage vertical
	new_tower.z_index = y * GRID_SIZE + x
	
	# Configuration de l'équipe
	new_tower.team = team_id
	
	# Configuration selon le type de tour
	configure_tower_by_type(new_tower, tower_type)
	
	# Groupes
	var group_name = "player" if team_id == 1 else "enemy"
	new_tower.add_to_group(group_name)
	new_tower.add_to_group("tower")
	
	# Rotation pour l'ennemi (faire face au joueur)
	if group_name == "enemy":
		new_tower.set_rotation_degrees(180)
	
	# Masquer la zone de portée (visuellement)
	if new_tower.has_node("Area"):
		new_tower.get_node("Area").modulate = Color(1, 1, 1, 0.0)

func configure_tower_by_type(tower: Node, tower_type: int):
	"""Configure les stats de la tour selon son type"""
	match tower_type:
		1:  # Tour Rouge (par défaut)
			pass  # Garde les stats de base
		2:  # Tour Canon (exemple)
			if tower.has("bullet_damage"):
				tower.bullet_damage = 8
			if tower.has("fire_rate"):
				tower.fire_rate = 4.0
			if tower.has("splash_radius"):
				tower.splash_radius = 100.0
		3:  # Tour Sniper (exemple)
			if tower.has("bullet_damage"):
				tower.bullet_damage = 20
			if tower.has("attack_range"):
				tower.attack_range = 800
			if tower.has("fire_rate"):
				tower.fire_rate = 5.0
		# Ajouter d'autres types ici selon ton système

# ============================================================================
# SYSTÈME DE SWIPE (JOUEUR UNIQUEMENT)
# ============================================================================

func setup_junk_raft():
	"""Configure le lien avec le système de swipe (si joueur)"""
	if team_id != 1:
		return  # Seulement pour le joueur
	
	# Chercher le JunkRaft dans les enfants du parent
	var parent_island = get_parent()
	if parent_island:
		for child in parent_island.get_children():
			if child is JunkRaft:
				junk_raft = child
				print("  ✅ JunkRaft trouvé et lié")
				break
	
	if not junk_raft:
		push_warning("⚠️ JunkRaft non trouvé dans player_island")

# ============================================================================
# GETTERS UTILITAIRES
# ============================================================================

func get_current_speed() -> float:
	"""Retourne la vitesse actuelle de l'île (si joueur)"""
	if junk_raft:
		return junk_raft.current_speed
	return 0.0

func get_tile_at(x: int, y: int):
	"""Retourne la tuile aux coordonnées données"""
	if x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE:
		return island_tile_map[x][y]
	return null

func get_all_tiles() -> Array:
	"""Retourne toutes les tuiles de l'île"""
	var tiles = []
	for row in island_tile_map:
		tiles.append_array(row)
	return tiles

func get_alive_tiles_count() -> int:
	"""Retourne le nombre de tuiles encore en vie"""
	var count = 0
	for row in island_tile_map:
		for tile in row:
			if is_instance_valid(tile):
				count += 1
	return count

func get_total_health() -> int:
	"""Retourne la santé totale de toutes les tuiles"""
	var total = 0
	for row in island_tile_map:
		for tile in row:
			if is_instance_valid(tile) and tile.has_method("get_health"):
				total += tile.get_health()
	return total

# ============================================================================
# DEBUG
# ============================================================================

func _to_string():
	return "Island(team=%d, tiles=%d/%d, health=%d)" % [
		team_id,
		get_alive_tiles_count(),
		GRID_SIZE * GRID_SIZE,
		get_total_health()
	]
	
