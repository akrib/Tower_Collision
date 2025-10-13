extends Area2D

var team = ""  # "player" ou "enemy"
var max_health = 3
var health = 3
var is_stunned = false
var base_speed = 75.0  # Pour plus tard si les tuiles bougent

@onready var smoke_particles = preload("res://scenes/effects/smoke.tscn")
@onready var tile_map = $TileMap

# Système d'effets de statut
var status_effects: StatusEffects

func _ready():
	# Ajouter le système d'effets de statut
	status_effects = StatusEffects.new()
	add_child(status_effects)
	
	# Afficher une tuile aléatoire du TileMap
	display_random_tile()
	
	var tile_sprite = get_node_or_null("tile")
	if tile_sprite and tile_sprite is IsoDepthSprite:
		tile_sprite.far_y = 200.0
		tile_sprite.near_y = 1000.0
		tile_sprite.update_depth()

func display_random_tile():
	"""Affiche une tuile aléatoire du TileMap"""
	if not tile_map:
		push_warning("⚠️ TileMap non trouvé dans la tuile")
		return
	
	# Récupérer le TileSet
	var tile_set = tile_map.tile_set
	if not tile_set:
		push_warning("⚠️ TileSet non configuré")
		return
	
	# Récupérer la source (atlas) - normalement source 0
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
	
	# OPTION 1 : Utiliser le sprite existant avec une région de la texture
	var tile_sprite = get_node_or_null("tile")
	if tile_sprite and tile_sprite is Sprite2D:
		# Récupérer la texture de l'atlas
		var atlas_texture = atlas_source.texture
		
		# Calculer la région de la tuile dans l'atlas
		var tile_size = atlas_source.texture_region_size
		var margins = atlas_source.margins
		var separation = atlas_source.separation
		
		# Position de la tuile dans l'atlas
		var atlas_x = margins.x + random_tile.x * (tile_size.x + separation.x)
		var atlas_y = margins.y + random_tile.y * (tile_size.y + separation.y)
		
		# Créer une AtlasTexture pour afficher juste cette région
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = atlas_texture
		atlas_tex.region = Rect2(atlas_x, atlas_y, tile_size.x, tile_size.y)
		
		# Appliquer au sprite
		tile_sprite.texture = atlas_tex
		tile_sprite.visible = true
	
	# Masquer le TileMap (on n'en a plus besoin)
	tile_map.visible = false

func _process(_delta):
	if health < 1:
		death()
	
	# Feedback visuel selon les effets
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

func take_damage(amount: int):
	"""Reçoit des dégâts (avec bouclier)"""
	# Le bouclier absorbe d'abord
	var actual_damage = status_effects.absorb_damage(amount)
	health -= actual_damage
	
	# Effet visuel
	show_damage_feedback()
	
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
# COLLISION (conservé de l'ancien système)
# ============================================================================

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
	take_damage(1)
	if other.has_method("take_damage"):
		other.take_damage(1)

	# Générer des particules de fumée
	spawn_smoke(global_position)
	spawn_smoke(other.global_position)

func spawn_smoke(pos: Vector2):
	var smoke = smoke_particles.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.global_position = pos
	smoke.emitting = true
