extends Node2D

@export var team_id: int = 1  # 1 = joueur, 2 = ennemi

@onready var tile_scene = preload("res://scenes/maps/tile.tscn")
@onready var tower_scene = preload("res://scenes/towers/red_bullet_tower.tscn")

const TILE_WIDTH = 128
const TILE_HEIGHT = 74
const GRID_SIZE = 8

var island_tile_map = []

func _ready():
	create_iso_grid()
	draw_towers()

func create_iso_grid():
	var group_name =  "player" if team_id == 1 else "enemy"
	#if group_name=="player":
	for x in range(GRID_SIZE):
		island_tile_map.append([])
		for y in range(GRID_SIZE):
			var new_tile = tile_scene.instantiate()
			add_child(new_tile)

			var iso_pos = Vector2((x - y) * TILE_WIDTH / 2, (x + y) * TILE_HEIGHT / 2)
			new_tile.position = iso_pos
			new_tile.name = "tile_%d_%d" % [x, y]
			new_tile.team = team_id
			new_tile.add_to_group(group_name)
			new_tile.add_to_group("tile")

			island_tile_map[x].append(new_tile)

func draw_towers():
	TowerDataManager.load_layout()
	var island_tower_map = TowerDataManager.get_layout()
	var group_name =  "player" if team_id == 1 else "enemy"
	if group_name=="player":
		for x in range(GRID_SIZE):
			for y in range(GRID_SIZE):
				if island_tower_map[x][y] > 0:
					create_tower(x, y, island_tower_map[x][y])
	else:
		for x in range(GRID_SIZE):  # boucle inversée sur X
			for y in range(GRID_SIZE):
				if island_tower_map[x][y] > 0:
					create_tower(y,x, island_tower_map[x][y])


func create_tower(x: int, y: int, tower_type: int):
	var new_tower = tower_scene.instantiate()
	var tile_node = island_tile_map[x][y]
	
	tile_node.add_child(new_tower)
	#tile_node.modulate = Color(1, 1, 1, 0.05)
	new_tower.scale = Vector2(0.5, 0.5)
	new_tower.position = Vector2(0, -TILE_HEIGHT * 0.35)
	new_tower.z_index = y * GRID_SIZE + x
	new_tower.team = team_id

	match tower_type:
		1: pass
		2:
			new_tower.bullet_damage = 3
			new_tower.fire_rate = 2.0
		3:
			new_tower.attack_range = 600

	var group_name =  "player" if team_id == 1 else "enemy"
	if group_name=="enemy":
		new_tower.set_rotation_degrees(180)
	new_tower.add_to_group(group_name)
	new_tower.add_to_group("tower")
	new_tower.get_node("Area").modulate = Color(1, 1, 1, 0.0)
