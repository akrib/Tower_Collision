extends Node2D


var tile=preload("res://maps/tile.tscn")
var island_map = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var parent=self
	for i in range(8):
		island_map.append([])
		for j in range(8):
			var temptile = tile.instantiate()
			#parent.add_child(temptile)
			parent.add_child(temptile)
			parent.get_child(-1).name= "tile_"+str(i)+"_"+str(j)
			#print(parent.get_child(-1).name)
			parent.get_child(-1).global_position = Vector2(parent.global_position.x + (i*64)+32,parent.global_position.y + (j*48)+24)
			#parent.get_child(-1).team = "ennemi"
			parent.get_child(-1).add_to_group( "ennemi" )
			parent.get_child(-1).add_to_group( "tile" )
			#print(parent.get_child(-1).team )
			#island_map[i].append(this_tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
