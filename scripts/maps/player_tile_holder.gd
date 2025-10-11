extends Node2D

@onready var tile = preload("res://scenes/maps/tile.tscn")
@onready var tower = preload("res://scenes/towers/red_bullet_tower.tscn")

var island_tile_map = []


func _ready():
	draw_tiles()
	draw_towers()


func draw_tiles():
	for x in range(8):
		island_tile_map.append([])
		for y in range(8):
			var new_tile = tile.instantiate()
			add_child(new_tile)
			
			new_tile.name = "tile_%d_%d" % [x, y]
			new_tile.global_position = Vector2(
				global_position.x + (x * 64) + 32,
				global_position.y + (y * 48) + 24
			)
			
			new_tile.add_to_group("player")
			new_tile.add_to_group("tile")


func draw_towers():
	# Charger le layout depuis le TowerDataManager
	TowerDataManager.load_layout()
	var island_tower_map = TowerDataManager.get_layout()
	
	for x in range(8):
		for y in range(8):
			if island_tower_map[x][y] > 0:
				create_tower(x, y, island_tower_map[x][y])


func create_tower(x: int, y: int, tower_type: int):
	var new_tower = tower.instantiate()
	var tile_node = get_node("tile_%d_%d" % [x, y])
	
	tile_node.add_child(new_tower)
	
	# Configuration de la tour
	new_tower.scale /= 2
	new_tower.global_position = tile_node.global_position
	new_tower.team = 1  # Team.PLAYER
	new_tower.z_index = 1000
	
	# Personnalisation selon le type (si vous avez plusieurs types)
	match tower_type:
		1: # Red Tower
			pass  # Configuration par défaut
		2: # Blue Tower
			new_tower.bullet_damage = 3
			new_tower.fire_rate = 2.0
		3: # Green Tower
			new_tower.attack_range = 600
	
	new_tower.add_to_group("player")
	new_tower.add_to_group("tower")
	
	new_tower.get_node("Area").modulate = Color(1, 1, 1, 0.05)
