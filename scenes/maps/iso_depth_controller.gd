extends Sprite2D
#extends Node2D

@export var far_y := 100.0   # Hauteur minimale (haut de la carte)
@export var near_y := 900.0  # Hauteur maximale (bas de la carte)

@onready var sprite: CanvasItem = $tile  # adapte le chemin selon ta scène

func _process(delta):
	if not sprite or not sprite.material:
		return

	var mat := sprite.material
	if mat is ShaderMaterial:
		var depth_factor : float = clamp((global_position.y - far_y) / (near_y - far_y), 0.0, 1.0)
		mat.set_shader_parameter("depth_factor", depth_factor)
