extends Area2D

# ============================================================================
# TUILE - Élément de base de l'île
# ============================================================================

# Équipe (1 = joueur, 2 = ennemi)
var team: int = 1

# Statistiques
var max_health: int = 3
var health: int = 3
var is_stunned: bool = false
var base_speed: float = 75.0

# Effets visuels
@onready var smoke_particles = preload("res://scenes/effects/smoke.tscn")
@onready var tile_map = $TileMap

# Système d'effets de statut
var status_effects: StatusEffects

# Cooldown pour éviter les collisions répétées
var collision_cooldown: float = 0.0
const COLLISION_COOLDOWN_TIME: float = 0.5

# Debug
var debug_collision_count: int = 0

func _ready():
	# Ajouter le système d'effets de statut
	status_effects = StatusEffects.new()
	add_child(status_effects)
	
	# Afficher une tuile aléatoire du TileMap
	display_random_tile()
	
	# Configurer le shader de profondeur si disponible
	var tile_sprite = get_node_or_null("tile")
	if tile_sprite and tile_sprite is IsoDepthSprite:
		tile_sprite.far_y = 200.0
		tile_sprite.near_y = 1000.0
		tile_sprite.update_depth()
	
	print("✅ Tuile %s créée (team=%d, groupe=%s)" % [name, team, "player" if team == 1 else "enemy"])

func display_random_tile():
	"""Affiche une tuile aléatoire du TileMap"""
	if not tile_map:
		push_warning("⚠️ TileMap non trouvé dans la tuile")
		return
	
	var tile_set = tile_map.tile_set
	if not tile_set:
		push_warning("⚠️ TileSet non configuré")
		return
	
	var source_id = 0
	var source = tile_set.get_source(source_id)
	
	if not source or not source is TileSetAtlasSource:
		push_warning("⚠️ Source d'atlas introuvable")
		return
	
	var atlas_source = source as TileSetAtlasSource
	
	# Récupérer toutes les coordonnées de tuiles disponibles
	var available_tiles = []
	var tiles_count = atlas_source.get_tiles_count()
	
	for i in range(tiles_count):
		var tile_coords = atlas_source.get_tile_id(i)
		available_tiles.append(tile_coords)
	
	if available_tiles.size() == 0:
		push_warning("⚠️ Aucune tuile disponible dans l'atlas")
		return
	
	# Choisir une tuile aléatoire
	var random_tile = available_tiles[randi() % available_tiles.size()]
	
	# Appliquer la texture au sprite
	var tile_sprite = get_node_or_null("tile")
	if tile_sprite and tile_sprite is Sprite2D:
		var atlas_texture = atlas_source.texture
		var tile_size = atlas_source.texture_region_size
		var margins = atlas_source.margins
		var separation = atlas_source.separation
		
		var atlas_x = margins.x + random_tile.x * (tile_size.x + separation.x)
		var atlas_y = margins.y + random_tile.y * (tile_size.y + separation.y)
		
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = atlas_texture
		atlas_tex.region = Rect2(atlas_x, atlas_y, tile_size.x, tile_size.y)
		
		tile_sprite.texture = atlas_tex
		tile_sprite.visible = true
	
	# Masquer le TileMap (on n'en a plus besoin)
	tile_map.visible = false

func _process(delta):
	# Vérifier la mort
	if health < 1:
		death()
		return
	
	# Réduire le cooldown de collision
	if collision_cooldown > 0:
		collision_cooldown -= delta
	
	# Mettre à jour le feedback visuel selon les effets
	update_visual_feedback()

func update_visual_feedback():
	"""Met à jour l'apparence selon les effets actifs"""
	# Réinitialiser la modulation
	modulate = Color(1, 1, 1, 1)
	
	# Appliquer les teintes selon les effets
	if status_effects.has_effect("poison"):
		modulate = Color(0.5, 1, 0.5, 1)  # Vert pour poison
	elif status_effects.has_effect("burn"):
		modulate = Color(1, 0.5, 0.3, 1)  # Orange pour brûlure
	elif status_effects.has_effect("slow"):
		modulate = Color(0.7, 0.7, 1, 1)  # Bleu pour ralentissement
	elif status_effects.has_effect("stun"):
		modulate = Color(1, 1, 0, 1)  # Jaune pour stun
	elif status_effects.has_effect("shield"):
		modulate = Color(0.7, 0.7, 1, 1)  # Bleu clair pour bouclier

# ============================================================================
# SYSTÈME DE SANTÉ
# ============================================================================

func take_damage(amount: int):
	"""Reçoit des dégâts (avec bouclier)"""
	# Le bouclier absorbe d'abord
	var actual_damage = status_effects.absorb_damage(amount)
	health -= actual_damage
	
	# Effet visuel
	show_damage_feedback()
	
	# Debug
	print("  💢 %s prend %d dégâts (HP: %d/%d)" % [name, actual_damage, health, max_health])
	
	if health <= 0:
		death()

func heal(amount: int):
	"""Se soigne"""
	health = min(health + amount, max_health)
	show_heal_feedback()

func get_health() -> int:
	return health

func get_max_health() -> int:
	return max_health

func death():
	"""Mort de la tuile"""
	print("💀 Tuile %s détruite (team=%d)" % [name, team])
	queue_free()

func show_damage_feedback():
	"""Feedback visuel de dégâts"""
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func show_heal_feedback():
	"""Feedback visuel de soin"""
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.5, 1, 0.5), 0.2)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)

# ============================================================================
# MÉTHODES D'EFFETS (appelées par les projectiles)
# ============================================================================

func apply_slow(multiplier: float, duration: float):
	"""Applique un ralentissement"""
	status_effects.apply_slow(multiplier, duration)

func apply_poison(damage_per_second: int, duration: float):
	"""Applique du poison"""
	status_effects.apply_poison(damage_per_second, duration)

func apply_burn(damage_per_second: int, duration: float):
	"""Applique une brûlure"""
	status_effects.apply_burn(damage_per_second, duration)

func apply_stun(duration: float):
	"""Applique un étourdissement"""
	status_effects.apply_stun(duration)

func apply_shield(amount: int, duration: float):
	"""Applique un bouclier"""
	status_effects.apply_shield(amount, duration)

# ============================================================================
# COLLISION - ✅ SYSTÈME CORRIGÉ
# ============================================================================

func _on_area_entered(area):
	"""Détecte les collisions avec d'autres tuiles"""
	
	# Vérifier le cooldown pour éviter les collisions répétées
	if collision_cooldown > 0:
		return
	
	# Vérifier que c'est bien une tuile
	if not area.is_in_group("tile"):
		return
	
	# ============================================================
	# ✅ FIX PRINCIPAL : Vérification correcte des équipes
	# ============================================================
	
	# Déterminer si l'autre tuile est ennemie
	var is_enemy_tile: bool = false
	
	if team == 1:
		# Je suis JOUEUR (team=1) → Mon ennemi a le groupe "enemy"
		is_enemy_tile = area.is_in_group("enemy")
	elif team == 2:
		# Je suis ENNEMI (team=2) → Mon ennemi a le groupe "player"
		is_enemy_tile = area.is_in_group("player")
	
	# Debug - Afficher les informations de collision
	debug_collision_count += 1
	if debug_collision_count % 10 == 0:  # Log tous les 10 checks pour éviter le spam
		print("🔍 Collision check #%d:" % debug_collision_count)
		print("  - Moi: %s (team=%d, groupes=%s)" % [name, team, get_groups()])
		print("  - Autre: %s (groupes=%s)" % [area.name if area else "null", area.get_groups() if area else "null"])
		print("  - Est ennemi? %s" % is_enemy_tile)
	
	# Résoudre la collision SEULEMENT si c'est un vrai ennemi
	if is_enemy_tile:
		resolve_collision(area)

func resolve_collision(other):
	"""Résout la collision entre deux tuiles ennemies"""
	
	# Activer le cooldown pour éviter les impacts multiples
	collision_cooldown = COLLISION_COOLDOWN_TIME
	
	# Appliquer les dégâts mutuels
	take_damage(1)
	if other.has_method("take_damage"):
		other.take_damage(1)
	
	# Générer des particules de fumée
	spawn_smoke(global_position)
	spawn_smoke(other.global_position)
	
	print("💥 Collision résolue: %s (team=%d) ⚔️ %s (team=%s)" % [
		name, 
		team, 
		other.name if other else "null",
		other.team if other and "team" in other else "?"
	])

func spawn_smoke(pos: Vector2):
	"""Crée des particules de fumée"""
	var smoke = smoke_particles.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.global_position = pos
	smoke.emitting = true

# ============================================================================
# DEBUG & UTILITAIRES
# ============================================================================

func _to_string():
	return "Tile(name=%s, team=%d, hp=%d/%d, groups=%s)" % [
		name, 
		team, 
		health, 
		max_health, 
		get_groups()
	]

func get_team_name() -> String:
	"""Retourne le nom de l'équipe pour le debug"""
	match team:
		1:
			return "PLAYER"
		2:
			return "ENEMY"
		_:
			return "UNKNOWN"
