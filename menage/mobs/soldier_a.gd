extends CharacterBody2D

@export var speed = 1000
var health = 10

func _process(delta):
	# get_node("ProgressBar").global_position = self.position + Vector2(-64,-81)
	get_parent().set_progress(get_parent().get_progress() + speed * delta)
	if get_parent().get_progress_ratio() == 1 :
		Game.health -= 1
		death()
		
	if health <= 0 :
		death()
		Game.gold += 1


func death():
	get_parent().get_parent().queue_free()
