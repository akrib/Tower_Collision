extends Node2D

@onready var tile = preload("res://scenes/maps/tile.tscn")
@onready var tower = preload("res://scenes/towers/red_bullet_tower.tscn")

var island_tower_map = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0]
]
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
			
			new_tile.add_to_group("enemy")
			new_tile.add_to_group("tile")


func draw_towers():
	for x in range(8):
		for y in range(8):
			if island_tower_map[x][y] == 1:
				var new_tower = tower.instantiate()
				var tile_node = get_node("tile_%d_%d" % [x, y])
				
				tile_node.add_child(new_tower)
				
				# Configuration de la tour
				new_tower.scale /= 2
				new_tower.global_position = tile_node.global_position
				new_tower.team = 2  # Team.ENEMY (2 correspond à l'enum)
				new_tower.z_index = 1000
				
				new_tower.add_to_group("enemy")
				new_tower.add_to_group("tower")
				
				new_tower.get_node("Area").modulate = Color(1, 1, 1, 0.05)
