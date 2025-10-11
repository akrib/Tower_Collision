#extends Node2D
#
#
#var tile=preload("res://maps/tile.tscn")
#var island_map = []
#
## Called when the node enters the scene tree for the first time.
#func _ready():
	#
	#var parent=self
	#for i in range(8):
		#island_map.append([])
		#for j in range(8):
			#var temptile = tile.instantiate()
			##parent.add_child(temptile)
			#parent.add_child(temptile)
			#parent.get_child(-1).name= "tile_"+str(i)+"_"+str(j)
			##print(parent.get_child(-1).name)
			#parent.get_child(-1).global_position = Vector2(parent.global_position.x + (i*64)+32,parent.global_position.y + (j*48)+24)
			##parent.get_child(-1).team = "ennemi"
			#parent.get_child(-1).add_to_group( "ennemi" )
			#parent.get_child(-1).add_to_group( "tile" )
			##print(parent.get_child(-1).team )
			##island_map[i].append(this_tile)
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass
extends Node2D


@onready var tile=preload("res://scenes/maps/tile.tscn")
@onready var tower = preload("res://scenes/towers/red_bullet_tower.tscn")
var island_tower_map =[[1,1,1,1,1,1,1,1],
					   [0,0,0,0,0,0,0,0],
					   [0,0,0,0,0,0,0,0],
					   [0,0,0,0,0,0,0,0],
					   [0,0,0,0,0,0,0,0],
					   [0,0,0,0,0,0,0,0],
					   [0,0,0,0,0,0,0,0],
					   [0,0,0,0,0,0,0,0]]
var island_tile_map = []

# Called when the node enters the scene tree for the first time.
func _ready():
	draw_tiles()
	draw_towers()

func draw_towers():
	var parent=self
	for x in range(8):
		for y in range(8):
			if island_tower_map[x][y] == 1:
				print("creation de tower")
				var tempTower = tower.instantiate()
				tile=parent.get_node("tile_"+str(x)+"_"+str(y))
				tile.add_child(tempTower)
				tile.get_child(-1).scale /= 2
				tile.get_child(-1).global_position = tile.global_position #+ Vector2(32,24)
				tile.get_child(-1).team="ennemi"
				tile.get_child(-1).add_to_group( "ennemi" )
				tile.get_child(-1).add_to_group( "tower" )
				tile.get_child(-1).z_index=1000
				#tile.get_child(-1).get_node("Area").hide()
				tile.get_child(-1).get_node("Area").modulate = Color(255,255,255,0.05)


func draw_tiles():
	var parent=self
	for x in range(8):
		island_tile_map.append([])
		for y in range(8):
			var temptile = tile.instantiate()
			#parent.add_child(temptile)
			parent.add_child(temptile)
			parent.get_child(-1).name= "tile_"+str(x)+"_"+str(y)
			#print(parent.get_child(-1).name)
			parent.get_child(-1).global_position = Vector2(parent.global_position.x + (x*64)+32,parent.global_position.y + (y*48)+24)
			#print(parent.get_child(-1).global_position.x," ",parent.get_child(-1).global_position.y)
			#parent.get_child(-1).team = "player"
			parent.get_child(-1).add_to_group( "ennemi" )
			parent.get_child(-1).add_to_group( "tile" )
			#island_tile_map[i].append(this_tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
