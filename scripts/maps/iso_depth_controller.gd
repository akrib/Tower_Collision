extends Sprite2D
class_name IsoDepthSprite

# Paramètres de profondeur
@export_group("Depth Settings")
@export var far_y: float = 100.0    # Position Y du haut de la carte (loin)
@export var near_y: float = 900.0   # Position Y du bas de la carte (près)
@export var auto_update: bool = true  # Mise à jour automatique chaque frame

# Paramètres visuels (optionnels, surchargent le shader)
@export_group("Visual Overrides (Optional)")
@export var override_colors: bool = false
@export var near_tint: Color = Color(1.1, 1.05, 0.95)  # Chaud devant
@export var far_tint: Color = Color(0.8, 0.9, 1.1)     # Froid derrière
@export var blur_strength: float = 0.002
@export var contrast_boost: float = 0.15
@export var saturation_boost: float = 0.25

# Matériau avec le shader
var shader_material: ShaderMaterial

func _ready():
	# Créer le matériau shader si nécessaire
	if not material or not material is ShaderMaterial:
		shader_material = ShaderMaterial.new()
		var shader = load("res://shaders/iso_depth_effect.gdshader")
		shader_material.shader = shader
		material = shader_material
	else:
		shader_material = material as ShaderMaterial
	
	# Appliquer les overrides si activés
	if override_colors:
		apply_visual_overrides()
	
	# Première mise à jour
	update_depth()

func _process(_delta):
	if auto_update:
		update_depth()

func update_depth():
	"""Calcule et applique le depth_factor selon la position Y"""
	if not shader_material:
		return
	
	# Calculer le facteur de profondeur (0 = loin, 1 = près)
	var depth_factor = clamp(
		(global_position.y - far_y) / (near_y - far_y), 
		0.0, 
		1.0
	)
	
	# Appliquer au shader
	shader_material.set_shader_parameter("depth_factor", depth_factor)

func apply_visual_overrides():
	"""Applique les paramètres visuels au shader"""
	if not shader_material:
		return
	
	shader_material.set_shader_parameter("near_tint_color", Vector3(near_tint.r, near_tint.g, near_tint.b))
	shader_material.set_shader_parameter("far_tint_color", Vector3(far_tint.r, far_tint.g, far_tint.b))
	shader_material.set_shader_parameter("blur_strength", blur_strength)
	shader_material.set_shader_parameter("contrast_boost", contrast_boost)
	shader_material.set_shader_parameter("saturation_boost", saturation_boost)

func set_depth_range(new_far_y: float, new_near_y: float):
	"""Change la plage de profondeur"""
	far_y = new_far_y
	near_y = new_near_y
	update_depth()

func get_current_depth_factor() -> float:
	"""Retourne le depth_factor actuel"""
	if shader_material:
		return shader_material.get_shader_parameter("depth_factor")
	return 0.5
