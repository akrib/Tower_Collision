extends Node

# Chemin de sauvegarde
const SAVE_PATH = "user://player_data.save"

# Données du joueur
var player_data = {
	"name": "Capitaine",
	"level": 1,
	"current_xp": 0,
	"xp_to_next_level": 100,
	"avatar_path": "",
	"skill_points": 0,
	"skills": {
		"tower_damage": 0,      # +5% de dégâts par niveau
		"tower_attack_speed": 0, # +5% de vitesse d'attaque par niveau
		"tower_health": 0        # +10 HP par niveau
	},
	"total_battles": 0,
	"victories": 0,
	"defeats": 0
}

# Signaux
signal level_up(new_level)
signal xp_gained(amount)
signal skill_upgraded(skill_name, new_level)
signal data_loaded

func _ready():
	load_data()

# Calcul de l'XP nécessaire pour le niveau suivant
func calculate_xp_for_level(level: int) -> int:
	# Formule de progression exponentielle avec paliers
	var base_xp = 100
	
	if level <= 10:
		# Niveaux 1-10: progression douce
		return int(base_xp * pow(1.1, level - 1))
	elif level <= 30:
		# Niveaux 11-30: progression modérée
		return int(base_xp * pow(1.12, level - 1))
	elif level <= 60:
		# Niveaux 31-60: progression soutenue
		return int(base_xp * pow(1.14, level - 1))
	else:
		# Niveaux 61-99: progression intense
		return int(base_xp * pow(1.16, level - 1))

# Ajouter de l'XP
func add_xp(amount: int):
	if player_data.level >= 99:
		return
	
	player_data.current_xp += amount
	xp_gained.emit(amount)
	
	# Vérifier les level ups
	while player_data.current_xp >= player_data.xp_to_next_level and player_data.level < 99:
		level_up_player()
	
	save_data()

# Level up
func level_up_player():
	player_data.current_xp -= player_data.xp_to_next_level
	player_data.level += 1
	player_data.skill_points += 1
	
	# Calculer l'XP pour le prochain niveau
	player_data.xp_to_next_level = calculate_xp_for_level(player_data.level)
	
	level_up.emit(player_data.level)
	save_data()

# Améliorer une compétence
func upgrade_skill(skill_name: String) -> bool:
	if player_data.skill_points <= 0:
		return false
	
	if not player_data.skills.has(skill_name):
		return false
	
	# Limite de niveau par compétence (99)
	if player_data.skills[skill_name] >= 99:
		return false
	
	player_data.skills[skill_name] += 1
	player_data.skill_points -= 1
	
	skill_upgraded.emit(skill_name, player_data.skills[skill_name])
	save_data()
	return true

# Calculer les bonus appliqués
func get_damage_bonus() -> float:
	return 1.0 + (player_data.skills.tower_damage * 0.05)

func get_attack_speed_bonus() -> float:
	return 1.0 + (player_data.skills.tower_attack_speed * 0.05)

func get_health_bonus() -> int:
	return player_data.skills.tower_health * 10

# Statistiques
func add_battle_result(won: bool):
	player_data.total_battles += 1
	if won:
		player_data.victories += 1
	else:
		player_data.defeats += 1
	save_data()

# Sauvegarde et chargement
func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(player_data)
		file.close()

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data:
				player_data = data
			file.close()
	data_loaded.emit()

func reset_data():
	player_data = {
		"name": "Capitaine",
		"level": 1,
		"current_xp": 0,
		"xp_to_next_level": 100,
		"avatar_path": "",
		"skill_points": 0,
		"skills": {
			"tower_damage": 0,
			"tower_attack_speed": 0,
			"tower_health": 0
		},
		"total_battles": 0,
		"victories": 0,
		"defeats": 0
	}
	save_data()

# Getters
func get_level() -> int:
	return player_data.level

func get_skill_points() -> int:
	return player_data.skill_points

func get_skill_level(skill_name: String) -> int:
	return player_data.skills.get(skill_name, 0)
