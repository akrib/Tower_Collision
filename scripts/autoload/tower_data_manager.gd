extends Node

# Chemin du fichier de sauvegarde
const SAVE_PATH = "user://player_towers.save"

# Données des tours placées
var player_tower_layout = []


func _ready():
	# Initialiser avec une grille vide 8x8
	reset_layout()


func reset_layout():
	player_tower_layout = []
	for x in range(8):
		player_tower_layout.append([])
		for y in range(8):
			player_tower_layout[x].append(0)


func set_tower(x: int, y: int, tower_type: int):
	if x >= 0 and x < 8 and y >= 0 and y < 8:
		player_tower_layout[x][y] = tower_type


func get_tower(x: int, y: int) -> int:
	if x >= 0 and x < 8 and y >= 0 and y < 8:
		return player_tower_layout[x][y]
	return 0


func save_layout() -> bool:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Impossible de créer le fichier de sauvegarde")
		return false
	
	var save_data = {
		"version": "1.0",
		"layout": player_tower_layout
	}
	
	file.store_var(save_data)
	file.close()
	print("Layout sauvegardé avec succès")
	return true


func load_layout() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Aucune sauvegarde trouvée, utilisation du layout par défaut")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Impossible d'ouvrir le fichier de sauvegarde")
		return false
	
	var save_data = file.get_var()
	file.close()
	
	if save_data.has("layout"):
		player_tower_layout = save_data.layout
		print("Layout chargé avec succès")
		return true
	
	return false


func get_layout() -> Array:
	return player_tower_layout.duplicate(true)


func count_towers() -> int:
	var count = 0
	for x in range(8):
		for y in range(8):
			if player_tower_layout[x][y] > 0:
				count += 1
	return count
