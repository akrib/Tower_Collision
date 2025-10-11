extends Node2D

enum TowerType { NONE, RED_TOWER, BLUE_TOWER, GREEN_TOWER }

@onready var tile_holder = $TileHolder
@onready var ui = $UI

var selected_tower_type = TowerType.NONE
var tiles = []
var tower_sprites = {}
var dragging_tower = false
var drag_preview = null

var tile_scene = preload("res://scenes/maps/tile.tscn")
var tower_textures = {
	TowerType.RED_TOWER: preload("res://assets/Default size/towerDefense_tile250.png"),
}

const TILE_WIDTH = 128
const TILE_HEIGHT = 74
const GRID_SIZE = 8

func _ready():
	TowerDataManager.load_layout()
	create_iso_grid()
	load_towers_from_data()
	setup_ui()

func create_iso_grid():
	for x in range(GRID_SIZE):
		tiles.append([])
		for y in range(GRID_SIZE):
			var tile = tile_scene.instantiate()
			tile_holder.add_child(tile)

			var iso_pos = Vector2((x - y) * TILE_WIDTH / 2, (x + y) * TILE_HEIGHT / 2)
			tile.position = iso_pos
			tile.name = "tile_%d_%d" % [x, y]
			tile.input_pickable = true
			tile.input_event.connect(_on_tile_input.bind(x, y))

			tiles[x].append(tile)


func load_towers_from_data():
	var layout = TowerDataManager.get_layout()
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if layout[x][y] > 0:
				place_tower_visual(x, y, layout[x][y])

#func place_tower_visual(x: int, y: int, tower_type: int):
	#remove_tower_visual(x, y)
	#if tower_type == TowerType.NONE:
		#return
#
	#var tower_sprite = Sprite2D.new()
	#tower_sprite.texture = tower_textures.get(tower_type)
	#tower_sprite.scale = Vector2(1.2, 1.2)
	#tower_sprite.z_index = y * GRID_SIZE + x
	#tower_sprite.position = Vector2(0, -TILE_HEIGHT / 2)
#
	#tiles[x][y].add_child(tower_sprite)
#
	#var key = "%d_%d" % [x, y]
	#tower_sprites[key] = tower_sprite

func place_tower_visual(x: int, y: int, tower_type: int):
	remove_tower_visual(x, y)
	if tower_type == TowerType.NONE:
		return

	var tower_sprite = Sprite2D.new()
	tower_sprite.texture = tower_textures.get(tower_type)
	tower_sprite.scale = Vector2(1.2, 1.2)
	tower_sprite.z_index = y * GRID_SIZE + x

	# Centrage visuel : ajusté selon la perspective Kenney
	var offset_x = 0
	var offset_y = -TILE_HEIGHT * 0.35  # ajusté pour compenser la perspective
	tower_sprite.position = Vector2(offset_x, offset_y)

	tiles[x][y].add_child(tower_sprite)

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
			TowerDataManager.set_tower(x, y, 0)
			remove_tower_visual(x, y)
		else:
			TowerDataManager.set_tower(x, y, selected_tower_type)
			place_tower_visual(x, y, selected_tower_type)
		update_tower_count()

func _input(event):
	if dragging_tower and drag_preview:
		if event is InputEventMouseMotion:
			drag_preview.global_position = get_global_mouse_position()
			var closest_tile = get_closest_tile(get_global_mouse_position())
			if closest_tile:
				highlight_tile(closest_tile)
				drag_preview.global_position = closest_tile.global_position
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var closest_tile = get_closest_tile(get_global_mouse_position())
			if closest_tile:
				var coords = get_tile_coords(closest_tile)
				if coords:
					TowerDataManager.set_tower(coords.x, coords.y, selected_tower_type)
					place_tower_visual(coords.x, coords.y, selected_tower_type)
					update_tower_count()
			if drag_preview:
				drag_preview.queue_free()
				drag_preview = null
			dragging_tower = false

#func get_closest_tile(pos: Vector2):
	#var min_dist = INF
	#var closest = null
	#for row in tiles:
		#for tile in row:
			#var dist = tile.global_position.distance_to(pos)
			#if dist < min_dist and dist < TILE_WIDTH:
				#min_dist = dist
				#closest = tile
	#return closest

func get_closest_tile(pos: Vector2):
	var min_dist = INF
	var closest = null

	for row in tiles:
		for tile in row:
			var tile_center = tile.global_position + Vector2(TILE_WIDTH / 2, TILE_HEIGHT / 2)
			var dist = tile_center.distance_to(pos)
			if dist < min_dist:
				min_dist = dist
				closest = tile
	return closest


func get_tile_coords(tile_node):
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if tiles[x][y] == tile_node:
				return Vector2i(x, y)
	return null

func setup_ui():
	ui.get_node("Panel/ButtonContainer/RedTowerBtn").pressed.connect(
		func():
			select_tower(TowerType.RED_TOWER)
			start_drag_preview()
	)
	ui.get_node("Panel/ButtonContainer/EraseBtn").pressed.connect(
		func(): select_tower(TowerType.NONE)
	)
	ui.get_node("Panel/BottomButtons/SaveBtn").pressed.connect(_on_save_pressed)
	ui.get_node("Panel/BottomButtons/ClearBtn").pressed.connect(_on_clear_pressed)
	ui.get_node("Panel/BottomButtons/BattleBtn").pressed.connect(_on_battle_pressed)
	ui.get_node("Panel/BottomButtons/MenuBtn").pressed.connect(_on_menu_pressed)
	ui.get_node("Panel/ConfirmDialog/HBox/YesBtn").pressed.connect(_on_clear_confirmed)
	ui.get_node("Panel/ConfirmDialog/HBox/NoBtn").pressed.connect(
		func(): ui.get_node("Panel/ConfirmDialog").visible = false
	)

func select_tower(tower_type: TowerType):
	selected_tower_type = tower_type
	update_selection_display()

func update_selection_display():
	var buttons = ui.get_node("Panel/ButtonContainer")
	for button in buttons.get_children():
		if button is Button:
			button.modulate = Color(1, 1, 1, 0.5)
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
	ui.get_node("Panel/ConfirmDialog").visible = true

func _on_clear_confirmed():
	TowerDataManager.reset_layout()
	for key in tower_sprites.keys():
		tower_sprites[key].queue_free()
	tower_sprites.clear()
	update_tower_count()
	ui.get_node("Panel/ConfirmDialog").visible = false
	show_message("Grille effacée!")

func _on_battle_pressed():
	TowerDataManager.save_layout()
	get_tree().change_scene_to_file("res://scenes/maps/battlefield.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func show_message(text: String):
	var message = ui.get_node("Panel/MessageLabel")
	message.text = text
	message.visible = true
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): message.visible = false)

func start_drag_preview():
	if selected_tower_type == TowerType.NONE:
		return
	dragging_tower = true
	drag_preview = Sprite2D.new()
	drag_preview.texture = tower_textures.get(selected_tower_type)
	drag_preview.scale = Vector2(1.2, 1.2)
	drag_preview.modulate = Color(1, 1, 1, 0.5)
	add_child(drag_preview)
	drag_preview.global_position = get_global_mouse_position()

func highlight_tile(tile):
	for row in tiles:
		for t in row:
			t.modulate = Color(1, 1, 1)
	tile.modulate = Color(1, 1, 0.8)
