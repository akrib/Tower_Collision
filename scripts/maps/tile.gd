extends Area2D
var team = ""
var health = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.health < 1:
		death(self)
	pass

func death(area):
	area.queue_free()

func _on_area_entered(area):
	#print(area)
	var array_of_tiles = get_tree().get_nodes_in_group ( "tile" )
	var array_of_ennemi = get_tree().get_nodes_in_group ( "ennemi" )
	var array_of_player = get_tree().get_nodes_in_group ( "player" )
	#print(array_of_tiles)
	#var currTargets = get_overlapping_areas()
	
	if area in array_of_tiles and area in array_of_player :
		var currTargets = get_overlapping_areas()
		for curr in currTargets: 
			if curr in array_of_tiles and curr in array_of_ennemi:
				if curr.health > 0:
					curr.health -= 1
					if curr.health <= 0:
						death(curr)
			if area.health < 1:
				death(area)
				break
			else : 
				area.health -= 1
		#print("in area in array_of_tiles")
		#var targets = get_node("Area2D").get_overlapping_areas()
		##var tiles = get_node('tile_holder').get_children()
		#var kill = []
		#for tar in targets :
			#print(tar.get_parent().team) 
			#if tar.get_parent().team == "ennemi" :
				#print(tar.get_parent().name)
				#kill.append(tar.get_parent().name)
		#for tar in targets : 
			#if tar.get_parent().name in kill:
				#tar.get_parent().queue_free()
