extends Node2D

# Types de tours disponibles
enum TowerType { NONE, RED_TOWER, BLUE_TOWER, GREEN_TOWER }

# Références
@onready var tile_holder = $TileHolder
@onready var ui = $UI

# État de l'éditeur
var selected_tower_type = TowerType.NONE
var tiles = []
var tower_sprites = {}
var dragging_tower = false
var drag_preview = null

# Préchargement des ressources
var tile_scene = preload("res://scenes/maps/tile.tscn")
var tower_textures = {
	TowerType.RED_TOWER: preload("res://assets/Default size/towerDefense_tile250.png"),
	# Ajoutez d'autres textures ici
}


func _ready():
	TowerDataManager.load_layout()
	create_grid()
	load_towers_from_data()
	setup_ui()


func create_grid():
	# Créer la grille de tuiles 8x8
	for x in range(8):
		tiles.append([])
		for y in range(8):
			var new_tile = tile_scene.instantiate()
			tile_holder.add_child(new_tile)
			
			new_tile.name = "tile_%d_%d" % [x, y]
			new_tile.global_position = Vector2(
				tile_holder.global_position.x + (x * 64) + 32,
				tile_holder.global_position.y + (y * 48) + 24
			)
			
			# Activer l'input pour cette tuile
			new_tile.input_pickable = true
			new_tile.input_event.connect(_on_tile_input.bind(x, y))
			
			tiles[x].append(new_tile)


func load_towers_from_data():
	var layout = TowerDataManager.get_layout()
	for x in range(8):
		for y in range(8):
			if layout[x][y] > 0:
				place_tower_visual(x, y, layout[x][y])


func place_tower_visual(x: int, y: int, tower_type: int):
	# Supprimer l'ancienne tour si elle existe
	remove_tower_visual(x, y)
	
	if tower_type == TowerType.NONE:
		return
	
	# Créer le sprite de la tour
	var tower_sprite = Sprite2D.new()
	tower_sprite.texture = tower_textures.get(tower_type)
	tower_sprite.scale = Vector2(1.5, 1.5)
	tower_sprite.rotation = PI / 2
	tower_sprite.z_index = 10
	
	tiles[x][y].add_child(tower_sprite)
	
	# Stocker la référence
	var key = "%d_%d" % [x, y]
	tower_sprites[key] = tower_sprite


func remove_tower_visual(x: int, y: int):
	var key = "%d_%d" % [x, y]
	if tower_sprites.has(key):
		tower_sprites[key].queue_free()
		tower_sprites.erase(key)


func _on_tile_input(_viewport, event, _shape_idx, x: int, y: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_tower_type == TowerType.NONE:
			# Mode suppression
			TowerDataManager.set_tower(x, y, 0)
			remove_tower_visual(x, y)
		else:
			# Mode placement
			TowerDataManager.set_tower(x, y, selected_tower_type)
			place_tower_visual(x, y, selected_tower_type)
		
		update_tower_count()


func _input(event):
	if dragging_tower and drag_preview:
		if event is InputEventMouseMotion:
			# Déplacer la prévisualisation
			drag_preview.global_position = get_global_mouse_position()
			
			# Trouver la tuile la plus proche
			var closest_tile = get_closest_tile(get_global_mouse_position())
			if closest_tile:
				# Snap au centre de la tuile
				highlight_tile(closest_tile)
				drag_preview.global_position = closest_tile.global_position
				
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Relâcher
			var closest_tile = get_closest_tile(get_global_mouse_position())
			if closest_tile:
				var coords = get_tile_coords(closest_tile)
				if coords:
					TowerDataManager.set_tower(coords.x, coords.y, selected_tower_type)
					place_tower_visual(coords.x, coords.y, selected_tower_type)
					update_tower_count()
			
			# Nettoyer la prévisualisation
			if drag_preview:
				drag_preview.queue_free()
				drag_preview = null
			dragging_tower = false


func get_closest_tile(pos: Vector2):
	var min_dist = INF
	var closest = null
	
	for row in tiles:
		for tile in row:
			var dist = tile.global_position.distance_to(pos)
			if dist < min_dist and dist < 64:  # Rayon de snap
				min_dist = dist
				closest = tile
	
	return closest


func get_tile_coords(tile_node):
	for x in range(8):
		for y in range(8):
			if tiles[x][y] == tile_node:
				return Vector2i(x, y)
	return null


func setup_ui():
	# Connecter les boutons de l'UI
	ui.get_node("Panel/ButtonContainer/RedTowerBtn").pressed.connect(
		func(): select_tower(TowerType.RED_TOWER)
	)
	ui.get_node("Panel/ButtonContainer/EraseBtn").pressed.connect(
		func(): select_tower(TowerType.NONE)
	)
	ui.get_node("Panel/BottomButtons/SaveBtn").pressed.connect(_on_save_pressed)
	ui.get_node("Panel/BottomButtons/ClearBtn").pressed.connect(_on_clear_pressed)
	ui.get_node("Panel/BottomButtons/BattleBtn").pressed.connect(_on_battle_pressed)
	ui.get_node("Panel/BottomButtons/MenuBtn").pressed.connect(_on_menu_pressed)
	
	# Connecter la boîte de dialogue de confirmation
	ui.get_node("Panel/ConfirmDialog/HBox/YesBtn").pressed.connect(_on_clear_confirmed)
	ui.get_node("Panel/ConfirmDialog/HBox/NoBtn").pressed.connect(
		func(): ui.get_node("Panel/ConfirmDialog").visible = false
	)
	ui.get_node("Panel/ButtonContainer/RedTowerBtn").pressed.connect(
		func():
			select_tower(TowerType.RED_TOWER)
			start_drag_preview()
	)

func select_tower(tower_type: TowerType):
	selected_tower_type = tower_type
	update_selection_display()


func update_selection_display():
	# Mettre à jour l'affichage de la sélection
	var buttons = ui.get_node("Panel/ButtonContainer")
	for button in buttons.get_children():
		if button is Button:
			button.modulate = Color(1, 1, 1, 0.5)
	
	# Highlighter le bouton sélectionné
	match selected_tower_type:
		TowerType.RED_TOWER:
			buttons.get_node("RedTowerBtn").modulate = Color(1, 1, 1, 1)
		TowerType.NONE:
			buttons.get_node("EraseBtn").modulate = Color(1, 1, 1, 1)


func update_tower_count():
	var count = TowerDataManager.count_towers()
	ui.get_node("Panel/InfoLabel").text = "Tours placées: %d / 64" % count


func _on_save_pressed():
	if TowerDataManager.save_layout():
		show_message("Sauvegarde réussie!")


func _on_clear_pressed():
	# Demander confirmation
	var confirm = ui.get_node("Panel/ConfirmDialog")
	confirm.visible = true


func _on_clear_confirmed():
	TowerDataManager.reset_layout()
	# Supprimer tous les visuels
	for key in tower_sprites.keys():
		tower_sprites[key].queue_free()
	tower_sprites.clear()
	update_tower_count()
	ui.get_node("Panel/ConfirmDialog").visible = false
	show_message("Grille effacée!")


func _on_battle_pressed():
	# Sauvegarder automatiquement avant de lancer la bataille
	TowerDataManager.save_layout()
	get_tree().change_scene_to_file("res://scenes/maps/battlefield.tscn")


func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func show_message(text: String):
	var message = ui.get_node("Panel/MessageLabel")
	message.text = text
	message.visible = true
	
	# Créer un timer pour cacher le message
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): message.visible = false)
	
func start_drag_preview():
	if selected_tower_type == TowerType.NONE:
		return
	dragging_tower = true
	drag_preview = Sprite2D.new()
	drag_preview.texture = tower_textures.get(selected_tower_type)
	drag_preview.scale = Vector2(1.5, 1.5)
	drag_preview.modulate = Color(1, 1, 1, 0.5)  # semi-transparent
	add_child(drag_preview)
	drag_preview.global_position = get_global_mouse_position()
	

func highlight_tile(tile):
	for row in tiles:
		for t in row:
			t.modulate = Color(1, 1, 1)
	tile.modulate = Color(1, 1, 0.8)  # léger jaune
