extends Sprite2D
@export var scroll_speed = Vector2(300, 0)
@export var speed_factor = 1.0

func _process(delta):
	region_rect.position += scroll_speed * speed_factor * delta
