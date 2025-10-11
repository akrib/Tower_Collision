extends Panel

@onready var tower = preload("res://scenes/towers/red_bullet_tower.tscn")
var currTile
var cost = 10

func _on_gui_input(event):
	if Game.gold >= cost:
		var tempTower = tower.instantiate()
		#print(event)
		var parent=get_parent().get_parent()
		
		if event is InputEventMouseButton and event.button_mask == 1 and event.get_button_index()==1:
			# left Click down
			parent.add_child(tempTower)
			parent.get_child(-1).global_position = get_viewport().get_mouse_position()
			#tempTower.global_position = event.global_position
			tempTower.process_mode = Node.PROCESS_MODE_DISABLED
			#tempTower.scale = Vector2(0.32,0.32)

			
		elif event is InputEventMouseMotion and event.button_mask == 1:
			# left Click down drag
			parent.get_child(-1).global_position = get_viewport().get_mouse_position()
			
			var mapPath = get_tree().get_root().get_node("main/TileMap")
			var tile = mapPath.local_to_map(get_global_mouse_position())
			currTile = mapPath.get_cell_atlas_coords(0,tile,false)
			
			
			var targets = parent.get_child(-1).get_node("TowerDetector").get_overlapping_bodies()
			if currTile == Vector2i(1,1):
				if (targets.size() > 0):
					parent.get_child(-1).get_node("Area").modulate = Color(255,255,255,0.3)
				else:
					parent.get_child(-1).get_node("Area").modulate = Color(0,255,0,0.3)
			else:
				parent.get_child(-1).get_node("Area").modulate = Color(255,255,255,0.3)
		elif event is InputEventMouseButton and event.button_mask == 0 and event.get_button_index() == 1:
			# left Click up
			if get_viewport().get_mouse_position().x > 1855:
				parent.get_child(-1).queue_free()
			else :
				if currTile == Vector2i(1,1):
					parent.get_child(-1).queue_free()
					var path=get_tree().get_root().get_node("main/Towers")
					var targets = parent.get_child(-1).get_node("TowerDetector").get_overlapping_bodies()
					if (targets.size() < 1):
						path.add_child(tempTower)
						tempTower.global_position = event.global_position
						#tempTower.get_node("Area").hide
						tempTower.get_node("Area").visible = false
						Game.gold -= cost
				else : 
					parent.get_child(-1).queue_free()
